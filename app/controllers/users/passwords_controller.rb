class Users::PasswordsController < Devise::PasswordsController

  # POST /resource/password
  def create
    user = User.find_by_email(params[:user][:email])
    if !user.nil?
      UserMailer.reset_password_instructions(user, mail_options).deliver!
      set_flash_message(:notice, :send_instructions)
    else 
      set_flash_message(:notice, :email_not_found)
    end
    respond_with({}, :location => root_path)
  end

end

