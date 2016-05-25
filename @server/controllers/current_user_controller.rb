# coding: utf-8


def dirty_if_any_private_proposals(real_user)
  matters = false 

  proposals, _, __ = Proposal.all_proposals_for_subdomain

  dummy = User.new

  proposals.each do |proposal|
    if permit('read proposal', proposal, real_user) != permit('read proposal', proposal, dummy)
      matters = true 
      break 
    end
  end 

  if matters 
    dirty_key '/proposals'
  end 

  matters
end

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
      trying_to = 'edit profile'    
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

      when 'create account', 'create account via invitation'

        update_user_attrs 'create account', errors
        try_update_password 'create account', errors 
        if !current_user.registered || trying_to == 'create account via invitation'
          has_name = current_user.name && current_user.name.length > 0
          ok_email = current_user.email && current_user.email.length > 0
          signed_pledge = params[:signed_pledge]
          ok_password = params[:password] && params[:password].length >= @min_pass

          if has_name && ok_email && signed_pledge && ok_password
            current_user.registered = true
            if !current_user.save
              raise "Error registering this uesr"
            end

            current_user.add_to_active_in
            dirty_if_any_private_proposals current_user

            update_roles_and_permissions

            # if this user was created via the invitation process, note that
            # they've gone through the registration process
            if current_user.complete_profile
              current_user.complete_profile = false
              current_user.save
            end

            log('registered account')

          else
            errors.append("Password needs to be at least #{@min_pass} letters") if !ok_password
            errors.append('Name is blank') if !has_name
            errors.append('Community pledge required') if !signed_pledge
            if !params[:email] || params[:email].length == 0
              errors.append('Email address can\'t be blank') 
            end
          end

        end

      when 'login'
        # puts("Signing in by email and password")
        if !params[:email] || params[:email].length == 0
          errors.append 'Missing email'
        elsif !params[:password] || params[:password].length == 0
          errors.append 'Missing password'
        elsif current_user.registered
          puts("Trying to log in a user who is already in!")
          errors.append 'You are already logged in'
        else

          user = User.find_by_email(params[:email].downcase)

          if !user || !user.registered
            # note: Returning this error message is a security risk as it
            #       reveals that a particular email address exists in the
            #       system or not.  But it's prolly the right tradeoff.
            errors.append "No user exists at that email address. Maybe you should click 'Create New Account' below." 

          elsif !user.authenticate(params[:password])
            errors.append "Wrong password. Click \"I forgot my password\" if you\'re having problems."
          else 
            replace_user(current_user, user)
            set_current_user(user)
            current_user.add_to_active_in
            update_roles_and_permissions

            dirty_if_any_private_proposals current_user

            if user.is_admin?
              dirty_key '/subdomain'
              dirty_key '/users'
            end

            # puts("Now current is #{current_user && current_user.id}")
            log('sign in by email')
          end
        end

      when 'reset password'

        # puts("Signing in by password reset.  min_pass is #{@min_pass}")
        has_password = params[:password] && params[:password].length >= @min_pass
        if !has_password
          # puts("They need to provide a longer password. Bailing.")
          errors.append "Please make a new password at least #{@min_pass} letters long"

        elsif current_user.registered
          errors.append 'You are already logged in'
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
            try_update_password 'reset password', errors
            current_user.add_to_active_in
            update_roles_and_permissions
            
            if !current_user.verified 
              current_user.verified = true
              current_user.save
            end
            dirty_if_any_private_proposals current_user

            log('sign in by password reset')

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
          
          UserMailer.reset_password_instructions(user, raw_token, current_subdomain).deliver_now

          log('requested password reset')
        end

      when 'logout'
        if current_user && current_user.logged_in?
          puts("Logging out.")
          dirty_key '/page/'
          dirty_if_any_private_proposals current_user
          new_current_user()
          log('logged out')
        end

      when 'switch_users'
        # Only enable god mode for 3 hours since the last time 
        # the super admin invoked godmode
        if current_user.super_admin
          session[:godmode] = Time.now.to_i 
        end

        if session[:godmode] && Time.now.to_i - session[:godmode] < 60 * 60 * 3

          user = User.find key_id(params[:switch_to])
          if user
            dirty_if_any_private_proposals current_user
            set_current_user(user)
            dirty_key '/application'
          else
            errors.append "Could not find a user at #{params[:switch_to]}"
          end
        else 
          errors.append 'You lack permission to switch users'
        end

      when 'edit profile'
        update_user_attrs 'edit profile', errors
        try_update_password 'edit profile', errors
        log('updating info')

      when 'user questions'
        update_user_attrs 'user questions', errors
        log('answering user questions')

      when 'verify email'
        pp '\n\n\nhoho!!!\n'


        verify_user(current_user.email, params[:verification_code])
        log('verifying email')

      when 'send_verification_token'
        pp '\n\n\nSENDING TOKEN!!!\n'
        UserMailer.verification(current_user, current_subdomain).deliver_now
        log('verification token sent')

    end

    # Wrap everything up
    response = current_user.current_user_hash(form_authenticity_token)
    response[:errors] = errors

    # If a user is trying to log in, and there was an error, we can
    # re-send them the faulty information so they can fix it.
    if ( ['login', 'reset password', 'create account', 'create account via invitation'].include?(trying_to))\
       && !response[:logged_in]
      response[:reset_password_token] = params[:reset_password_token] if params[:reset_password_token]
      response[:password] = params[:password] if params[:password]
      response[:email]    = params[:email]    if params[:email]
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
    types = { 
      :avatar => ActionDispatch::Http::UploadedFile, 
      :bio => String, 
      :name => String,
      :hide_name => 'boolean',
      :email => String
    }


    types.each do |field, type| 
      value = params[field]
      error = "Field #{field} is wrong type #{value.class}"
      if type == 'boolean'
        raise error if value && !(!!value == value)
      else
        raise error if value && value.class != type
      end
    end

    fields = ['avatar', 'bio', 'name', 'hide_name', 'tags', 'subscriptions']
    new_params = params.select{|k,v| fields.include? k}
    new_params[:name] = '' if !new_params[:name] #TODO: Do we really want to allow blank names?...

    if new_params.has_key? :tags
      # strip out non-editable tags...
      new_tags = new_params[:tags].reject {|k,v| !k.include?('.editable') } 

      # make sure non-editable tags weren't removed entirely...
      non_editable_old_tags = JSON.parse(current_user.tags || '{}').reject {|k,v| k.include?('.editable') } 
      new_tags.update non_editable_old_tags

      new_params[:tags] = JSON.dump new_tags

      dirty_key '/proposals' # might have access to more proposals if user tags have been changed (LVG, zipcodes)
    end

    if new_params.has_key? :subscriptions
      new_params[:subscriptions] = current_user.update_subscriptions(new_params[:subscriptions])
    end

    if current_user.update_attributes(new_params)
      # puts("Updating params. #{new_params}")
      if !current_user.save
        raise 'Error saving basic current_user parameters!'
      end
      

    else
      raise 'Had trouble manipulating this user!'
    end

    # Update their email address.  First, check if they gave us a new address
    email = params[:email]
    user = User.find_by_email(email)
    if !email || email.length == 0
      if trying_to == 'create account'
        errors.append 'No email address specified'
      end
    # And if it's not taken
    elsif user && (user != current_user)
      errors.append 'There is already an account with that email'
    # And that it's valid
    elsif !/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match(email)
      errors.append 'Email address is not properly formatted'
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
      if trying_to == 'create account' || trying_to == 'reset password'
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

  # Check to see if this user has been referenced by email in any 
  # roles or permissions settings. If so, replace the email with the
  # user's key. 
  def update_roles_and_permissions
    for cls in [Subdomain, Proposal]
      objs_with_user_in_role = cls.where("roles like '%\"#{current_user.email}\"%'") 
                                       # this is case insensitive

      for obj in objs_with_user_in_role
        pp "UPDATING ROLES, replacing #{current_user.email} with #{current_user.id} for #{obj.name}"
        obj.roles = obj.roles.gsub /\"#{current_user.email}\"/i, "\"/user/#{current_user.id}\""
        obj.save
      end

    end

  end

  def log (what)
    write_to_log({:what => what, :where => request.fullpath, :details => nil})
  end

end

