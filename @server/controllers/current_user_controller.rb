# coding: utf-8

class CurrentUserController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :update_user_avatar_hack

  # Gets the current user data
  def show
    # puts("Current_user is #{current_user.id}")
    dirty_key '/current_user'
    render :json => []
  end  

  # handles auth (login, new accounts, and login via reset password token) and updating user info
  def update

    errors = []
    @min_pass = 4


    if !params.has_key?(:trying_to) || !params[:trying_to] || params[:trying_to] == 'update_avatar_hack'
      trying_to = 'update'    
    else
      trying_to = params[:trying_to]
    end

    # puts("")
    # puts("--------------------------------")
    # puts("----Start UPDATE CURRENT USER---")
    # puts("  with current_user=#{current_user.id}")
    # puts("  trying to #{params[:trying_to]}")
    # puts("")


    case trying_to

      when 'register', 'register-after-invite'

        update_user_attrs 'register', errors
        try_update_password 'register', errors 
        if !current_user.registered || trying_to == 'register-after-invite'
          third_party_authenticated = current_user.twitter_uid || current_user.facebook_uid\
                                      || current_user.google_uid
          has_name = current_user.name && current_user.name.length > 0
          can_login = ((current_user.email && current_user.email.length > 0)\
                       || third_party_authenticated)
          signed_pledge = params[:signed_pledge]
          ok_password = third_party_authenticated || (params[:password] && params[:password].length >= @min_pass)

          if has_name && can_login && signed_pledge && ok_password
            current_user.registered = true
            if !current_user.save
              raise "Error registering this uesr"
            end

            current_user.add_to_active_in
            dirty_key '/proposals'
            log('registered account')

          else
            errors.append("Password needs to be at least #{@min_pass} letters") if !ok_password
            errors.append('Name is blank') if !has_name
            errors.append('Community pledge required') if !signed_pledge
          end

        end

      when 'login'
        # puts("Signing in by email and password")

        if !params[:email] || params[:email].length == 0
          errors.append 'Missing email'
        elsif !params[:password] || params[:password].length == 0
          errors.append 'Missing password'
        else

          user = User.find_by_email(params[:email].downcase)

          if !user || !user.registered
            # note: Returning this error message is a security risk as it
            #       reveals that a particular email address exists in the
            #       system or not.  But it's prolly the right tradeoff.
            errors.append "No user exists at that email address" 

          elsif !user.authenticate(params[:password])
            provider = user.third_party_authenticated()
            errors.append "Wrong password.#{provider ? ' Previously you used the ' + provider + ' button.' : ''}"
          else 
            current_user.add_to_active_in
            replace_user(current_user, user)
            set_current_user(user)
            dirty_key '/proposals'

            if user.is_admin?
              dirty_key '/subdomain'
              dirty_key '/users'
            end

            # puts("Now current is #{current_user && current_user.id}")
            log('sign in by email')
          end
        end
      when 'login_via_reset_password_token'

        # puts("Signing in by password reset.  min_pass is #{@min_pass}")
        has_password = params[:password] && params[:password].length >= @min_pass
        if !has_password
          # puts("They need to provide a longer password. Bailing.")
          errors.append "Please make a new password at least #{@min_pass} letters long"

        else 
        
          # Now let's take that raw reset_password_token, and compute the
          # digest and see if it matches any users
          encoded_token = OpenSSL::HMAC.hexdigest('SHA256',
                                                  'reset_password_token',
                                                  params[:verification_code])
          user = User.where(reset_password_token: encoded_token).first
          # puts("We found user #{user} with a password reset token")
          
          if user
            replace_user(current_user, user)
            set_current_user(user)
            try_update_password 'login_via_reset_password_token', errors
            current_user.add_to_active_in
            dirty_key '/proposals'
          else
            errors.append "Sorry, that's the wrong verification code."
          end  
                  
        end

      when 'send_password_reset_token' 
        # puts("Initiating reset_password")
        has_email = params[:email] && params[:email].strip.length > 0
        user = has_email && User.find_by_email(params[:email].downcase)
        
        if !user
          # note: returning this is a security risk as it reveals that a
          #       particular email address exists in the system or not.
          #       But it's prolly the right tradeoff.
          errors.append "We have no account for that email address."
          # puts("Errors are #{errors}")
        else 
          # This algorithm is adapted from devise
          # TODO: unify with user.unique_token

          # Generate a token that nobody's using
          raw_token = loop do
            raw_token = SecureRandom.urlsafe_base64(15)
            raw_token = raw_token.tr('lIO0', 'sxyz') # Remove hard-to-distinguish characters
            # Now we have a raw token... let's see if anyone's using it
            break raw_token unless User.where(reset_password_token: raw_token).first
          end

          puts("\nYO YO the raw token to login is #{raw_token}\n")

          # Now we'll store an encoded version of the token on the user table
          encoded_token = OpenSSL::HMAC.hexdigest('SHA256', 'reset_password_token', raw_token)
          user.reset_password_token   = encoded_token
          user.reset_password_sent_at = Time.now.utc
          user.save(:validate => false)
          
          UserMailer.reset_password_instructions(user, raw_token, Thread.current[:subdomain]).deliver!

          log('requested password reset')
        end

      when 'logout'
        if current_user && current_user.logged_in? && params[:logged_in] == false
          # puts("Logging out.")
          dirty_key '/page/homepage'
          dirty_key '/proposals'
          new_current_user()
          log('logged out')
        end

      when 'update'
        update_user_attrs 'update', errors
        try_update_password 'update', errors
        log('updating info')

      when 'verify'
        # this will get used below in verify_user_email_if_possible
        session[:email_token_user] = {'u' => current_user.email, 't' => params[:verification_code]}
        log('verifying email')

      when 'send_verification_token'
        UserMailer.verification(current_user, current_subdomain)
        log('verification token sent')

    end

    verify_user_email_if_possible

    # Wrap everything up
    response = current_user.current_user_hash(form_authenticity_token)
    response[:errors] = errors

    # Don't overwrite these fields in the case of errors. Let the user edit them again.
    # TODO: can we use errors variable here for a more precise conditional?
    #
    # MIKE:
    #       Good catch.  I thought about it, and the current behavior
    #       will cause a bug when users can edit their profiles.  They
    #       will be logged in, but their password will disappear each
    #       time they submit an update.
    if !response[:logged_in] 
      response[:reset_password_token] = params[:reset_password_token] if params[:reset_password_token]
      response[:password] = params[:password] if params[:password]
      response[:email] = params[:email] if params[:email]
    end

    if errors.length > 0
      write_to_log({
        :what => "Errors trying to #{trying_to} user",
        :where => request.fullpath,
        :details => {:errors => errors}
      })
    end

    Thread.current[:dirtied_keys].delete('/current_user') # Because we're adding our own
    dirty_key("/user/#{current_user.id}")                 # But let's get the /user

    render :json => [response]

    # puts("")
    # puts("----End UPDATE CURRENT USER---")
    # puts("------------------------------")

  end

  #####
  # See @submit_avatar_form in franklin.coffee
  def user_avatar_hack
    render :json => { :b64_thumbnail => current_user.b64_thumbnail }
  end
  def update_user_avatar_hack
    current_user.update_attributes({:avatar => params['avatar']})
    render :json => []
  end
  #######


  def update_user_attrs(trying_to, errors)
    types = {:avatar => ActionDispatch::Http::UploadedFile, :bio => String, :name => String,
             :hide_name => 'boolean',
             :email => String, :no_email_notifications => 'boolean'}
    types.each do |field, type| 
      value = params[field]
      error = "Field #{field} is wrong type #{value.class}"
      if type == 'boolean'
        raise error if value && !(!!value == value)
      else
        raise error if value && value.class != type
      end
    end

    fields = ['avatar', 'bio', 'name', 'hide_name', 'tags', 'no_email_notifications']
    new_params = params.select{|k,v| fields.include? k}
    new_params[:name] = '' if !new_params[:name]
    new_params[:tags] = JSON.dump(new_params[:tags]) if new_params[:tags]

    if current_user.update_attributes(new_params)
      # puts("Updating params. #{new_params}")
      if !current_user.save
        raise 'Error saving basic current_user parameters!'
      end
      dirty_key '/proposals' # might have access to more proposals if user tags have been changed (LVG, zipcodes)

    else
      raise 'Had trouble manipulating this user!'
    end

    # Update their email address.  First, check if they gave us a new address
    email = params[:email]
    user = User.find_by_email(email)
    if !email || email.length == 0
      if trying_to == 'register'
        errors.append 'No email address specified' 
      end
    # And if it's not taken
    elsif user && (user != current_user)
      errors.append 'There is already an account with that email'
    # And that it's valid
    elsif !/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match(email)
      errors.append 'Bad email address'
    elsif current_user.email != email
      # puts("Updating email from #{current_user.email} to #{params[:email]}")
      # Okay, here comes a new email address!
      current_user.update_attributes({:email => email, :verified => false})
      if !current_user.save
        raise "Error saving this user's email"
      end
    end
  end

  def try_update_password(trying_to, errors)
    # Update their password
    if !params[:password] || params[:password].length == 0
      if trying_to == 'register' || trying_to == 'login_via_reset_password_token'
        errors.append 'No password specified'
      end
    elsif params[:password].length < @min_pass
      errors.append 'Password is too short'
    else
      # puts("Changing user's password.")
      current_user.password = params[:password]
      if !current_user.save
        raise "Error saving this user's password"
      end
    end

  end

  def log (what)
    write_to_log({:what => what, :where => request.fullpath, :details => nil})
  end


  def update_via_third_party

    access_token = env["omniauth.auth"]

    ######
    # Try to find an existing user that matches the credentials 
    # provided in the access token
    case access_token.provider
      when 'facebook'
        user = User.find_by_facebook_uid(access_token.uid)
      when 'google_oauth2'
        user = User.find_by_google_uid(access_token.uid)
    end

    # If we didn't find a user by the uid, perhaps they already have a user
    # registered by the given email address, but just haven't authenticated 
    # yet by this particular third party. For example, say I register by 
    # email/password with me@gmail.com, but then later I try to authenticate
    # via google oauth. We'll want to match with the existing user and 
    # set the proper google uid. 
    if !user && access_token.info.email
      user = User.find_by_email(access_token.info.email.downcase)
      if user
        user["#{access_token.provider}_uid".intern] = access_token.uid
        user.save
      end
    end


    # If a registered user is associated with this third party, just log them in
    if user && user.registered
      # Then the user registration is complete.
      replace_user current_user, user
      set_current_user(user)

      current_user.add_to_active_in

      dirty_key '/proposals'
      if user.is_admin?
        dirty_key '/subdomain'
        dirty_key '/users'
      end

      # third party user's emails are automatically verified
      if !current_user.verified 
        current_user.verified = true
        current_user.save
      end

      write_to_log({
        :what => 'logged in through 3rd party',
        :where => '/current_user',
        :details => {:provider => user.third_party_authenticated}
      })

    else
      # Then the user still needs to complete the pledge.  
      if user
        replace_user current_user, user
        set_current_user(user)
        current_user.add_to_active_in
      end      
      
      # We'll use the oauth access_token to fill in some of the user's data
      case access_token.provider

        when 'google_oauth2'
          third_party_params = {
            'google_uid' => access_token.uid,
            'email' => access_token.info.email,
            'avatar_url' => access_token.info.image,
          }        

        when 'facebook'
          third_party_params = {
            'facebook_uid' => access_token.uid,
            'email' => access_token.info.email,
            #'url' => access_token.info.urls.Website ? access_token.info.urls.Website : nil, #TODO: fix this for facebook
            'avatar_url' => 'https://graph.facebook.com/' + access_token.uid + '/picture?type=large'
          }

        else
          raise 'Unsupported provider'
      end

      third_party_params['name'] = access_token.info.name

      if !current_user.encrypted_password
        # this prevents a bcrypt hashing problem in the scenario where 
        # a user creates an account via third party, forgets, and tries
        # to enter an email and password. In that case, password
        # can't be null.
        third_party_params['password'] = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] 
      end


      # third party user's emails are automatically verified
      if !current_user.verified 
        third_party_params['verified'] = true
      end

      current_user.update_attributes! third_party_params

    end

    response = [current_user.current_user_hash(form_authenticity_token)]
    response.concat(compile_dirty_objects())

    document_domain = nil
    vanity_url = request.host.split('.').length == 1
    document_domain = vanity_url ? "document.domain" : "location.host.replace(/^.*?([^.]+\.[^.]+)$/g,'$1')"

    render :inline =>
      "<div style='font-weight:600; font-size: 36px; color: #414141'>Please close this window</div>" +
      "<div style='font-size: 24px'><div>You've logged in successfully!</div>" + 
      "<div>Unfortunately, a bug in the iPad & iPhone prevents this window from closing automatically." +
      "<div>Sorry for the inconvenience.</div></div>" +
      "<script type=\"text/javascript\">" +
      (document_domain ? "document.domain = #{document_domain};\n" : '') + 
      "  window.current_user_hash = #{response.to_json};  " +
      "</script>"
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
    raise env['omniauth.error.type']
  end

  private

  # this won't be needed after old dash is replaced
  def file_uploaded
    params[:remotipart_submitted].present? && params[:remotipart_submitted] == "true"
  end



end

