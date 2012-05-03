

class Users::PasswordsController < Devise::PasswordsController

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name], current_tenant.contact_email)

    if successfully_sent?(resource)
      respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  protected
    # The path used after sending reset password instructions
    def after_sending_reset_password_instructions_path_for(resource_name)
      root_path
    end
end

