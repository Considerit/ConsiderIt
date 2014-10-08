# coding: utf-8

class CurrentUserController < ApplicationController
  protect_from_forgery :except => :update
  skip_before_filter :verify_authenticity_token, :if => :file_uploaded

  # Gets the current user data
  def show
    # puts("Current_user is #{current_user.id}")
    dirty_key '/current_user'
    render :json => []
  end  

  # handles auth (login, new accounts, and login via reset password token) and updating user info
  def update

    puts("")
    puts("--------------------------------")
    puts("----Start UPDATE CURRENT USER---")
    puts("  with current_user=#{current_user.id}")
    puts("")

    errors = {:login => [], :register => [], :reset_password => []}
    min_pass = @min_pass = 4
    logging_out = false
    signing_in = false
    email_regexp = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

    def log (what)
      write_to_log({:what => what, :where => request.fullpath, :details => nil})
    end

    def try_email_authentication(params)
      puts("Signing in by email and password")

      return 'Missing email'    if !params[:email] || params[:email].length == 0
      return 'Missing password' if !params[:password] || params[:password].length == 0
      
      user = User.find_by_lower_email(params[:email])
      return "No user exists at that email address" if !user || !user.registration_complete
      # note: Returning this error message is a security risk as it
      #       reveals that a particular email address exists in the
      #       system or not.  But it's prolly the right tradeoff.

      if !user.authenticate(params[:password])
        provider = user.third_party_authenticated()
        if provider
          return "Wrong password. Previously you used the #{provider} button."
        else 
          return "Wrong password"
        end
      end
      replace_user(current_user, user)
      set_current_user(user)
      dirty_key '/proposals'

      puts("Now current is #{current_user && current_user.id}")
      return nil
    end

    def try_password_reset_authentication(params)
      error = nil

      puts("Signing in by password reset.  min_pass is #{@min_pass}")
      has_password = params[:password] && params[:password].length >= @min_pass
      if !has_password
        puts("They need to provide a longer password. Bailing.")
        return ["Please make a new password at least #{@min_pass} letters long"]
      end
      
      # What's this next line?  I'm guessing this next line is for
      # when you create an account and click a link in a confirmation
      # email, but I'm not sure. -mike
      params[:password_confirmation] = params[:password] if !params.has_key? :password_confirmation

      # Now let's take that raw reset_password_token, and compute the
      # digest and see if it matches any users
      encoded_token = OpenSSL::HMAC.hexdigest('SHA256',
                                              'reset_password_token',
                                              params[:reset_password_token])
      user = User.where(reset_password_token: encoded_token).first
      puts("We found user #{user} with a password reset token")
      
      if user
        replace_user(current_user, user)
        set_current_user(user)
      else
        error = "Sorry, that's the wrong verification code."
      end

      return error
    end

    def validate(field, type)
      value = params[field]
      error = "Field #{field} is wrong type #{value.class}"
      if type == 'boolean'
        raise error if value && !(!!value == value)
      else
        raise error if value && value.class != type
      end
    end

    # Validate input
    types = {:avatar => ActionDispatch::Http::UploadedFile, :bio => String, :name => String,
             :hide_name => 'boolean',
             :email => String, :password => String}
    types.each {|field, value| validate(field, value)}
    validate(:logged_in, 'boolean')

    fields = ['avatar', 'bio', 'name', 'hide_name', 'tags']
    new_params = params.select{|k,v| fields.include? k}
    new_params[:name] = '' if !new_params[:name]
    new_params[:tags] = JSON.dump(new_params[:tags]) if new_params[:tags]

    puts("Reset my password? #{params[:reset_my_password]}")

    # Send the reset_password token if client wants
    if params[:reset_my_password]
      puts("Initiating reset_password")
      errors[:reset_password].concat(send_reset_password_token(params))
      puts("Errors are #{errors[:reset_password]}")
      log('requested password reset')

    end

    # 0. Try logging out
    if current_user && current_user.logged_in? && params[:logged_in] == false
      puts("Logging out.")
      logging_out = true
      dirty_key '/page/homepage'
      dirty_key '/proposals'
      new_current_user()
      log('logged out')

    else
      # Otherwise, we'll
      #  (1) Authenticate: "HEY WHO ARE YOU, REALLY?" ... we might switch users.
      #  (2) Update:       "Ok, tell me more about you."
      #  (3) Test Registration-Complete  "Do you deserve your badge of power yet?"

      # 1. Authenticate.  Log in.  Switch Users.
      # 
      # The user can log in with:
      #  • A password reset token
      #  • Or the email address that has been passed into this method
      #
      # There's also third-party auth (fb/twit/goog) but that
      # happens in other functions.
      if !current_user || !current_user.logged_in?
        # This can return the following errors:
        #  errors.reset_password = bad password
        #  errors.reset_password = bad verification code
        #  errors.login = bad password

        puts("Trying to log in.")

        # Sign in by password reset token
        if params[:reset_password_token]
          error_msg = try_password_reset_authentication(params)
          if error_msg
            errors[:reset_password].append(error_msg)
          else
            log('sign in by reset password token')
            signing_in = true
          end

        # Sign in by email and password
        else
          error_msg = try_email_authentication(params)
          if error_msg
            errors[:login].append(error_msg)
          else
            signing_in = true
            log('sign in by email')
          end
        end
      end

      if !signing_in
        # 2. Now we know the user's account.  Let them manipulate themself:
        #   • Update their name, bio, photo...
        #   • Update their email (if it doesn't already exist)
        #   • Get registered if they filled everything out

        # Update their name, bio, photo, and anonymity.
        permitted = ActionController::Parameters.new(new_params).permit!

        if current_user.update_attributes(permitted)
          puts("Updating params. #{new_params}; permitted version #{permitted}")
          if !current_user.save
            raise 'Error saving basic current_user parameters!'
          end
          dirty_key '/proposals' # might have access to more proposals if user tags have been changed
          log_entry = 'updating info' if !log_entry

        else
          raise 'Had trouble manipulating this user!'
        end

        # Update their email address.  First, check if they gave us a new address
        email = params[:email]
        user = User.find_by_email(email)
        if !email || email.length == 0
          errors[:register].append 'No email address specified'
        # And if it's not taken
        elsif user && (user != current_user)
          errors[:register].append 'There is already an account with that email'
        # And that it's valid
        elsif !/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match(email)
          errors[:register].append 'Bad email address'
        else
          puts("Updating email from #{current_user.email} to #{params[:email]}")
          # Okay, here comes a new email address!
          current_user.update_attributes({:email => email})
          if !current_user.save
            raise "Error saving this user's email"
          end
        end

        # Update their password
        if !params[:password] || params[:password].length == 0
          errors[:register].append 'No password specified'
        elsif params[:password].length < min_pass
          errors[:register].append 'Password is too short'
        else
          puts("Changing user's password.")
          current_user.password = params[:password]
          if !current_user.save
            raise "Error saving this user's password"
          end
        end

        # Register the account
        if !current_user.registration_complete
          third_party_authenticated = current_user.twitter_uid || current_user.facebook_uid\
                                      || current_user.google_uid
          has_name = current_user.name && current_user.name.length > 0
          can_login = ((current_user.email && current_user.email.length > 0)\
                       || third_party_authenticated)
          signed_pledge = params[:signed_pledge]
          ok_password = third_party_authenticated || (params[:password] && params[:password].length >= min_pass)

          if has_name && can_login && signed_pledge && ok_password
            current_user.registration_complete = true
            if !current_user.save
              raise "Error registering this uesr"
            end
            log_entry = 'registered account'
          # user.skip_confirmation! #TODO: make email confirmations actually work... (disabling here because users with accounts that never confirmed their accounts can't login after 7 days...)
          else
            errors[:register].append('Name is blank') if !has_name
            errors[:register].append('Community pledge required') if !signed_pledge
          end
        end
      end
    end
    
    # 4. Now wrap everything up
    response = current_user.current_user_hash(form_authenticity_token)
    response[:errors] = errors

    if response[:logged_in] || logging_out
      response[:password] = nil
    else
      # Keep these parameters around while the user re-types them in
      response[:reset_password_token] = params[:reset_password_token]
      response[:password] = params[:password]
      response[:email] = params[:email] if params[:email]
    end

    #HACKY! supports local measures w/ zipcodes
    # if user && (session.has_key? :tags) && session[:tags]
    #   user.addTags session[:tags]
    # end

    respond_to do |format|
      format.json do 
        Thread.current[:dirtied_keys].delete('/current_user') # Because we're adding our own
        dirty_key("/user/#{current_user.id}")                 # But let's get the /user
        # TODO: figure out how to let applicationcontroller#compile_dirty_objects
        #       handle this response

        if log_entry
          write_to_log({
            :what => log_entry,
            :where => request.fullpath,
            :details => {:errors => errors}
          })
        end

        render :json => [response]
      end

      format.html do
        # non-ajax method is used for legacy support for dash
        if current_user.registration_complete
          # redirect here
          if session.has_key? :redirect_after_login
            path = session[:redirect_after_login]
            session.delete :redirect_after_login
            redirect_to path
            return
          else 
            render :json => [response]
          end
        else
          @errors = errors.values().flatten
          @not_logged_in = true
          render :template => "old/login", :layout => 'dash' 
        end

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
      dirty_key '/proposals'

      write_to_log({
        :what => 'logged in through 3rd party',
        :where => '/current_user',
        :details => {:provider => user.third_party_authenticated}
      })

    else
      # Then the user still needs to complete the pledge.  Let's just
      # get some of the user's current data (we have them temporarily
      # referenced via the access_token)
      if user
        replace_user current_user, user
        set_current_user(user)
      end      
      current_user.update_from_third_party_data(access_token)
    end

    response = [current_user.current_user_hash(form_authenticity_token)]
    response.concat(compile_dirty_objects())

    render :inline =>
      "<div style='font-weight:600; font-size: 36px; color: #414141'>Please close this window</div>" +
      "<div style='font-size: 24px'><div>You've logged in successfully!</div>" + 
      "<div>Unfortunately, a bug in the iPad & iPhone prevents this window from closing automatically." +
      "<div>Sorry for the inconvenience.</div></div>" +
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

  def send_reset_password_token(params)
    has_email = params[:email] && params[:email].strip.length > 0
    user = has_email && User.find_by_lower_email(params[:email])
    
    if !user
      # note: returning this is a security risk as it reveals that a
      #       particular email address exists in the system or not.
      #       But it's prolly the right tradeoff.
      return ["We have no account for that email address."]
    end

    user.reset_password()

    return []
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

  def passthru
    render status: 404, text: "Not found. Oauth authentication passthru."
  end


  # when something goes wrong in an oauth transation, this method gets called
  def failure
    # TODO: handle this gracefully for the user
    raise "Something went wrong in authenticating your account"
  end

  private



  # this won't be needed after old dash is replaced
  def file_uploaded
    params[:remotipart_submitted].present? && params[:remotipart_submitted] == "true"
  end

end

