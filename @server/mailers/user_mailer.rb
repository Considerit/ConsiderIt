require 'mail'

class UserMailer < Mailer

  def reset_password_instructions(user, token, current_subdomain)
    @user = user
    @token = token 
    subject = "password reset instructions"
    @subdomain = current_subdomain

    to = format_email @user.email, @user.name
    from = format_email(default_sender(current_subdomain), current_subdomain.app_title)
    mail(:from => from, :to => to, :subject => "[#{current_subdomain.app_title}] #{subject}")
  end

  def verification(user, current_subdomain)
    @user = user
    @token = ApplicationController.MD5_hexdigest("#{user.email}#{user.unique_token}#{current_subdomain.name}")
    @subdomain = current_subdomain
    subject = "please verify your email address"

    to = format_email @user.email, @user.name
    from = format_email(default_sender(current_subdomain), current_subdomain.app_title)
    mail(:from => from, :to => to, :subject => "[#{current_subdomain.app_title}] #{subject}")
  end
end

