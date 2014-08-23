# coding: utf-8

class CurrentUserController < DeviseController
  protect_from_forgery :except => :update
  before_filter :configure_permitted_parameters
  skip_before_filter :verify_authenticity_token, :if => :file_uploaded

  # TODO: test if we need the following to support oauth transactions
  #prepend_before_filter { request.env["devise.skip_timeout"] = true }

  # Gets the current user data
  def show
    pp("Current_user is #{current_user}")
    make_stub_user if not current_user
    pp("After stubby, it\'s #{current_user}")
    
    render :json => current_user_hash
  end  

  # handles auth (login, new accounts, and login via reset password token) and updating user info
  def update
    errors = {:login => [], :register => [], :password_reminder => []}

    puts("")
    puts("")
    puts("")
    puts("-------------- #{current_user}")
    puts("-------")
    puts("")
    puts("")
    puts("")
    puts("")
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

    password_reset_token = params[:reset_password_token]

    # 0. Try logging out
    puts("Current user is #{current_user} and logged in? #{current_user and current_user.logged_in?}")
    if current_user and current_user.logged_in? and params[:logged_in] == false
      puts("Logging out... what is this resource_name thing? #{resource_name}")
      puts("And the all scopes thing? #{Devise.sign_out_all_scopes}")
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)

      puts("Making a stub user.")
      make_stub_user()
      puts("Now current_user is #{current_user}")

    else
      # Otherwise, we'll try logging in and/or updating this user

      # 1. Try logging in
      # 
      # We can log in with three methods
      #  • A third-party account, like facebook or google or twitter (handled below in update_via_third_party)
      #  • A password reset token
      #  • Or the email address that has been passed into this method
      if not current_user or not current_user.logged_in?
        puts("Trying to sign in with #{params[:email]} and #{params[:password]}")

        # Sign in by password reset token
        if password_reset_token
          puts("Signing in by password reset")
          params[:password_confirmation] = params[:password] if !params.has_key? :password_confirmation
          old_user = current_user
          user = User.reset_password_by_token params

          if !user.errors || user.errors.count == 0
            replace_user(current_user, user)
            sign_in :user, user
          else
            errors[:password_reminder].append 'Invalid verification token!'
          end


        # Sign in by third party
        # elsif third_party_token
        #   puts("Signing in by third party")
        #   user = User.find_by_third_party_token(third_party_token)
        #   replace_user(current_user, user)
        #   sign_in :user, user

        # Sign in by email and password
        elsif (params[:password] and params[:password].length > 0\
               and params[:email] and params[:email].length > 0)
          puts("Signing in by email and password")
          user = User.find_by_lower_email(params[:email])
          puts('Found a user') if user
          if user and user.valid_password?(params[:password])
            puts('Password is valid, here we go...merging first')
            replace_user(current_user, user)
            puts("Now signing in #{user.id}. Going from #{current_user and current_user.id}.")
            sign_in :user, user
            puts("Signed in! Now current is #{current_user and current_user.id}")
          else
            errors[:login].append 'wrong password'
          end
        end

        puts("Done trying singing in.  Current user is #{current_user}")
      end


      # 2. If they still need an account, make a stub
      if not current_user
        puts("Making a stub user.")
        make_stub_user()
        puts("Now current_user is #{current_user}")
      end      

      # 3. Now the user has an account.  Let them manipulate themself:
      #   • Update their name, bio, photo...
      #   • Update their email (if it doesn't already exist)
      #   • Get registered if they filled everything out

      puts("Current user is #{current_user.id}")
      puts("and the user of that is #{User.find(current_user.id)}")

      # Update their name, bio, photo, and anonymity.
      permitted = ActionController::Parameters.new(new_params).permit!
      puts("Params is #{new_params}, permitted version #{permitted}")

      if current_user.update_attributes(permitted) # Why is this bullshit so complicated?
        puts("Updated those damn params.  Now name is #{current_user.name}")
        if current_user.save
          puts("Saved that shit. Now current_user.name is #{current_user.name}")
        else
          puts("Save goddam failed")
        end
        if params.has_key? :avatar
          dirty_avatar_cache
        end
      else
        puts("No updating of bio and shit happened #{current_user.bio}")
        raise 'Had trouble manipulating this user!'
      end

      # Update their email address.  First, check if they gave us a new address
      if params[:email] and params[:email] != current_user.email
        puts("Updating email from #{current_user.email} to #{params[:email]}")
        # And if it's not taken
        if User.find_by_email(params[:email])
          errors[:register].append 'That email is not available.'
        # And that it's valid
        elsif false # I don't know how to check an email address in rails, so punt!
          errors[:register].append 'Bad email address'
        else
          puts('XXX Need to figure out how to validate email address in here')
          # Okay, here comes a new email address!
          current_user.update_attributes({:email => params[:email]})
          if !current_user.save
            raise "Error saving this user's email"
          end
        end
      end

      # Update their password
      if (params[:password] and params[:password].length > 0)
        puts("There's a password. #{params[:password]}")
        if params[:password].length < 4
          puts("But it's too short")
          errors[:register].append 'Password is too short'
        else
          puts("Ok let's change the password.")
          current_user.password = params[:password]
          if !current_user.save
            raise "Error saving this user's password"
          end
          puts("Current user is now #{current_user.id}")
          puts("Ok, logging back in...")
          sign_in :user, current_user, :bypass => true
          puts("Current user is now #{current_user.id}")
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

      puts('XXX Need to check password or third_party login')

      if has_name and can_login and signed_pledge
        current_user.registration_complete = true
        if !current_user.save
          raise "Error registering this uesr"
        end
        # user.skip_confirmation! #TODO: make email confirmations actually work... (disabling here because users with accounts that never confirmed their accounts can't login after 7 days...)
      elsif !signed_pledge
        errors[:register].append 'Community pledge required'
      end
    end
    
    # 4. Now wrap everything up
    response = current_user_hash
    response['errors'] = errors

    #HACKY! supports local measures w/ zipcodes
    # if user && (session.has_key? :tags) && session[:tags]
    #   user.addTags session[:tags]
    # end

    puts('Is this a XHR request?', request.xhr?)
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

    puts("Finalizing.  Current_user=#{current_user}")
    puts("")
    puts("")
    puts("-------")
    puts("--------------")

  end

  def update_via_third_party
    access_token = env["omniauth.auth"]
    user = User.find_by_third_party_token access_token

    # If a registered user is associated with this third party, just log them in
    if user && user.registration_complete
      # Then the user registration is complete.
      replace_user current_user, user
      sign_in :user, user
    else
      # Then the user still needs to complete the pledge.  Let's just
      # get some of the user's current data (we have them temporarily
      # referenced via the access_token)
      current_user.update_from_third_party_data(access_token)
      dirty_avatar_cache
    end

    render :inline =>
      "<script type=\"text/javascript\">" +
      "  window.current_user_hash = #{current_user_hash.to_json};  " +
      "</script>"
  end


  def replace_user(old_user, new_user)
    new_user.absorb(old_user)

    puts("Deleting old user #{old_user.id}")
    if current_user.id == old_user.id
      puts("Signing out of #{current_user.id} before we delete it")
      sign_out current_user
    end
    old_user.delete()
    puts("Done replacing. current_user=#{current_user}")
  end

  #TODO: activeRESTify this method
  def send_password_reset_token
    user = User.find_by_lower_email(params[:user][:email]) if params[:user][:email].strip.length > 0
    if !user.nil?
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token   = enc
      user.reset_password_sent_at = Time.now.utc
      user.save(:validate => false)

      UserMailer.reset_password_instructions(user, raw, mail_options).deliver!
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

  def current_user_hash
    {
      id: current_user.id, #leave the id in for now for backwards compatability with Dash
      key: '/current_user',
      user: current_user ? "/user/#{current_user.id}" : nil,
      logged_in: current_user.registration_complete,
      email: current_user.email,
      password: nil,
      csrf: form_authenticity_token,
      follows: current_user.follows,
      avatar_url: nil,
      url: current_user.url,
      bio: current_user.bio,
      twitter_uid: nil,
      facebook_uid: nil,
      google_uid: nil,
      name: current_user.name
    }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit! }
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit! }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit! }    
  end

  # this won't be needed after old dash is replaced
  def file_uploaded
    params[:remotipart_submitted].present? && params[:remotipart_submitted] == "true"
  end

end

