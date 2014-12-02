require 'mail'

class UserMailer < Mailer

  def reset_password_instructions(user, token, current_subdomain)
    app_title = current_subdomain ? current_subdomain.app_title : ''
    from = current_subdomain && current_subdomain.notifications_sender_email && current_subdomain.notifications_sender_email.length > 0 ? current_subdomain.notifications_sender_email : APP_CONFIG[:email]
    @user = user
    @token = token 
    subject = "password reset instructions"
    @subdomain = current_subdomain


    to = format_email @user.email, @user.name
    from = format_email(from, app_title)
    mail(:from => from, :to => to, :subject => "[#{app_title}] #{subject}")
  end

  def invitation(inviter, invitee, invitation_obj, action, current_subdomain)
    @user = invitee
    @subdomain = current_subdomain
    @invitation_obj = invitation_obj
    @action = action

    to = format_email user.email, user.name    
    from = format_email(inviter, inviter.name)

    case invitation_obj.class

    when Subdomain
      subject = "#{inviter.name} invites you to #{action} at #{invitation_obj.app_title}"
    when Proposal
      subject = "#{inviter.name} invites you to #{action} at '#{invitation_obj.name}'"
    end

    mail(:from => from, :to => to, :subject => "#{subject}")

  end

end

