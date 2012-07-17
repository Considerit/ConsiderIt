class Users::PasswordsController < Devise::PasswordsController

  # POST /resource/password
  def create
    user = User.find_by_email(params[:user][:email])
    UserMailer.reset_password_instructions(user, mail_options).deliver!
    
    respond_with({}, :location => root_path)
    
  end

end

