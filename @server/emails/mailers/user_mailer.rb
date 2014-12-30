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

    puts "And the token is ", @token
    to = format_email @user.email, @user.name
    from = format_email(default_sender(current_subdomain), current_subdomain.app_title)
    mail(:from => from, :to => to, :subject => "[#{current_subdomain.app_title}] #{subject}")
  end

  def invitation(inviter, invitee, invitation_obj, action, current_subdomain, message = nil)
    @user = invitee
    @inviter = inviter
    @subdomain = current_subdomain
    @invitation_obj = invitation_obj
    @action = action
    @message = message

    if invitee.first_name
      to = format_email invitee.email, invitee.name    
    end

    from = format_email(inviter.email, inviter.name)

    case invitation_obj.class.to_s

    when 'Subdomain'
      subject = "#{inviter.name} invites you to #{action} at #{invitation_obj.app_title}"
    when 'Proposal'
      subject = "#{inviter.name} invites you to #{action} at '#{invitation_obj.name}'"
    else
      raise "Why are you trying to send an invitation to a #{invitation_obj.class.to_s}?"
    end

    mail(:from => from, :to => to, :subject => subject)

  end

end

