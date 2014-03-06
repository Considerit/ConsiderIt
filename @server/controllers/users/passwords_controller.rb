class Users::PasswordsController < Devise::PasswordsController

  # POST /resource/password
  def create
    user = User.find_by_lower_email(params[:user][:email]) if params[:user][:email].strip.length > 0
    if !user.nil?
      #from recoverable.send_reset_password_instructions
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token   = enc
      user.reset_password_sent_at = Time.now.utc
      user.save(:validate => false)
      ####

      UserMailer.reset_password_instructions(user, raw, mail_options).deliver!
      render :json => {
        :result => 'success'
      }
    else 
      render :json => {
        :result => 'failure',
        :reason => 'email not found'
      } 
    end
    
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      sign_in(resource_name, resource)
      render :json => {
        :result => 'successful',
        #TODO: filter users' to_json
        :user => current_user
      }

      #flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      #set_flash_message(:notice, flash_message) if is_navigational_format?
      #respond_with resource, :location => after_sign_in_path_for(resource)
    else
      #respond_with resource
      render :json => {
        :result => 'failure',
        :reason => 'password token expired'
      }

    end
  end


end

