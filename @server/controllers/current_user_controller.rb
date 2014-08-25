# coding: utf-8

class CurrentUserController < ApplicationController
  protect_from_forgery :except => :update
  skip_before_filter :verify_authenticity_token, :if => :file_uploaded

  # TODO: test if we need the following to support oauth transactions
  #prepend_before_filter { request.env["devise.skip_timeout"] = true }

  # Gets the current user data
  def show
    puts("Current_user is #{current_user.id}")
    render :json => current_user().current_user_hash(form_authenticity_token)
  end  

  # handles auth (login, new accounts, and login via reset password token) and updating user info
  def update

    puts("")
    puts("--------------------------------")
    puts("----Start UPDATE CURRENT USER---")
    puts("  with current_user=#{current_user.id}")
    puts("")

    errors = {:login => [], :register => [], :password_reminder => []}
    min_pass = 4

    def validate(field, type)
      value = params[field]
      error = "Field #{field} is wrong type #{value.class}"
      if type == 'boolean'
        raise error if value and not (!!value == value)
      else
        raise error if value and value.class != type
      end
    end

    # Validate input
    types = {:avatar => ActionDispatch::Http::UploadedFile, :bio => String, :name => String,
             :hide_name => 'boolean',
             :email => String, :password => String}
    types.each {|field, value| validate(field, value)}
    validate(:logged_in, 'boolean')

    fields = ['avatar', 'bio', 'name', 'hide_name']
    new_params = params.select{|k,v| fields.include? k}

    reset_password_token = params[:reset_password_token]

    # 0. Try logging out
    if current_user and current_user.logged_in? and params[:logged_in] == false
      new_current_user()
    else
      # Otherwise, we'll try logging in and/or updating this user

      # 1. Try logging in
      # 
      # We can log in with three methods
      #  • A third-party account, like facebook or google or twitter
      #    (handled below in update_via_third_party)
      #  • A password reset token
      #  • Or the email address that has been passed into this method
      if not current_user or not current_user.logged_in?
        # Sign in by password reset token
        if reset_password_token
          password = params[:password] and params[:password].length > min_pass
          if not password
            errors[:password_reminder].append("You must provide a new password at least #{min_pass} letters long")
          else
            puts("Signing in by password reset")
            params[:password_confirmation] = params[:password] if !params.has_key? :password_confirmation
            old_user = current_user

            # Now let's take that raw reset_password_token, and compute
            # the digest and see if it matches any users
            encoded_token = OpenSSL::HMAC.hexdigest('SHA256',
                                                    'reset_password_token',
                                                    reset_password_token)
            user = User.where(reset_password_token: encoded_token).first
            puts("We found user #{user} with a password reset token")
            if user
              replace_user(current_user, user)
              set_current_user(user)
            else
              errors[:password_reminder].append "Sorry, that's the wrong verification code."
            end
          end

        # Sign in by email and password
        elsif (params[:password] and params[:password].length > 0\
               and params[:email] and params[:email].length > 0)
          puts("Signing in by email and password")
          user = User.find_by_lower_email(params[:email])
          if user and user.authenticate(params[:password])
            replace_user(current_user, user)
            set_current_user(user)
            puts("Now current is #{current_user and current_user.id}")
          else
            errors[:login].append 'wrong password'
          end
        end
      end

      # 2. Now we know the user's account.  Let them manipulate themself:
      #   • Update their name, bio, photo...
      #   • Update their email (if it doesn't already exist)
      #   • Get registered if they filled everything out

      # Update their name, bio, photo, and anonymity.
      permitted = ActionController::Parameters.new(new_params).permit!

      if current_user.update_attributes(permitted) 
        puts("Updating params. #{new_params}; permitted version #{permitted}")
        if !current_user.save
          puts("Save failed")
        end
        if params.has_key? :avatar
          dirty_avatar_cache
        end
      else
        raise 'Had trouble manipulating this user!'
      end

      # Update their email address.  First, check if they gave us a new address
      email = params[:email]
      if email and email.length > 0 and email != current_user.email
        # And if it's not taken
        if User.find_by_email email
          errors[:register].append 'That email is not available.'
        # And that it's valid
        elsif !email.include?('.') || !email.include?('@') # instead of a complicated regex, let's just check for @ and .
          errors[:register].append 'Bad email address'
        else
          puts("Updating email from #{current_user.email} to #{params[:email]}")
          # Okay, here comes a new email address!
          current_user.update_attributes({:email => email})
          if !current_user.save
            raise "Error saving this user's email"
          end
        end
      end

      # Update their password
      if (params[:password] and params[:password].length > 0)
        if params[:password].length < min_pass
          errors[:register].append 'Password is too short'
        else
          puts("Changing user's password.")
          current_user.password = params[:password]
          if !current_user.save
            raise "Error saving this user's password"
          end
        end
      end
    end

    # Register the account
    if not current_user.registration_complete
      has_name = current_user.name and current_user.name.length > 0
      can_login = ((current_user.email and current_user.email.length > 0)\
                   or (current_user.twitter_uid or current_user.facebook_uid\
                       or current_user.google_uid))
      signed_pledge = params[:signed_pledge]
      ok_password = params[:password] and params[:password].length > min_pass

      puts('XXX Need to check password or third_party login')

      if has_name and can_login and signed_pledge and ok_password
        current_user.registration_complete = true
        if !current_user.save
          raise "Error registering this uesr"
        end
        # user.skip_confirmation! #TODO: make email confirmations actually work... (disabling here because users with accounts that never confirmed their accounts can't login after 7 days...)
      else
        errors[:register].append('Community pledge required') if !signed_pledge
        errors[:register].append("Password must be at least #{min_pass} letters long") if !ok_password
      end
    end
    
    # 4. Now wrap everything up
    response = current_user.current_user_hash(form_authenticity_token)
    response['errors'] = errors

    #HACKY! supports local measures w/ zipcodes
    # if user && (session.has_key? :tags) && session[:tags]
    #   user.addTags session[:tags]
    # end

    if true || request.xhr?
      response = [response]
      response.concat(affected_objects())
      render :json => response
    else
      # non-ajax method is used for legacy support for dash
      if errors[:register].length == 0 and errors[:login].length == 0
        # redirect here
        if session.has_key? :redirect_after_login
          path = session[:redirect_after_login]
          session.delete :redirect_after_login
          redirect_to path
          return
        else 
          render :json => response
        end
      else
        @errors = errors
        @not_logged_in = true        
        render :template => "old/login", :layout => 'dash' 
      end
    end

    puts("")
    puts("----End UPDATE CURRENT USER---")
    puts("------------------------------")

  end

  def update_via_third_party
    access_token = env["omniauth.auth"]
    user = User.find_by_third_party_token access_token

    # If a registered user is associated with this third party, just log them in
    if user && user.registration_complete
      # Then the user registration is complete.
      replace_user current_user, user
      set_current_user(user)
    else
      # Then the user still needs to complete the pledge.  Let's just
      # get some of the user's current data (we have them temporarily
      # referenced via the access_token)
      current_user.update_from_third_party_data(access_token)
      dirty_avatar_cache
    end

    response = [current_user.current_user_hash(form_authenticity_token)]
    response.concat(affected_objects())

    render :inline =>
      "<script type=\"text/javascript\">" +
      "  window.current_user_hash = #{response.to_json};  " +
      "</script>"
  end


  def replace_user(old_user, new_user)
    return if old_user.id == new_user.id

    new_user.absorb(old_user)

    puts("Deleting old user #{old_user.id}")
    if current_user.id == old_user.id
      puts("Signing out of #{current_user.id} before we delete it")

      # Travis: should we be signing in new_user here? Everytime replace_user is
      #         called, sign_in follows
    end
    old_user.destroy()

    puts("Done replacing. current_user=#{current_user}")
  end

  #TODO: activeRESTify this method
  def send_password_reset_token
    user = User.find_by_lower_email(params[:user][:email]) if params[:user][:email].strip.length > 0
    if !user.nil?
      # This algorithm is copied/extracted from devise

      # Generate a token that nobody's using
      raw_token = loop do
        raw_token = SecureRandom.urlsafe_base64(15)
        raw_token = raw_token.tr('lIO0', 'sxyz') # Remove hard-to-distinguish characters
        # Now we have a raw token... let's see if anyone's using it
        break raw_token unless User.where(reset_password_token: raw_token).first
      end

      # Now we'll store an encoded version of the token on the user table
      encoded_token = OpenSSL::HMAC.hexdigest('SHA256', 'reset_password_token', raw_token)
      user.reset_password_token   = encoded_token
      user.reset_password_sent_at = Time.now.utc
      user.save(:validate => false)

      UserMailer.reset_password_instructions(user, raw_token, mail_options).deliver!
      render :json => {
               :result => 'success'
             }
    else 
      # note: returning this is a security risk as it reveals that a particular
      #       email address exists in the system or not
      render :json => {
               :errors => ["We couldn\'t find an account matching that email."]
             } 
    end

  end

  # Omniauth oauth handlers
  def facebook
    update_via_third_party
  end

  def google_oauth2
    update_via_third_party
  end

  def twitter
    update_via_third_party
  end

  # when something goes wrong in an oauth transation, this method gets called
  def failure
    # TODO: handle this gracefully for the user
    raise "Something went wrong in authenticating your account"
  end

  private

  def dirty_avatar_cache
    current = Rails.cache.read("avatar-digest-#{current_tenant.id}") || 0
    Rails.cache.write("avatar-digest-#{current_tenant.id}", current + 1)   
  end


  # this won't be needed after old dash is replaced
  def file_uploaded
    params[:remotipart_submitted].present? && params[:remotipart_submitted] == "true"
  end

end

