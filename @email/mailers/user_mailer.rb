require 'mail'

class UserMailer < Mailer

  def reset_password_instructions(user, token, subdomain)
    @user = user
    @token = token 
    subject = "password reset instructions"
    @subdomain = subdomain

    to = format_email @user.email, @user.name
    from = format_email(default_sender(subdomain), (subdomain.app_title or subdomain.name))
    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
  end

  def verification(user, subdomain)
    @user = user
    @token = ApplicationController.MD5_hexdigest("#{user.email}#{user.unique_token}#{subdomain.name}")
    @subdomain = subdomain
    subject = "please verify your email address"

    puts "And the token is ", @token
    to = format_email @user.email, @user.name
    from = format_email(default_sender(subdomain), (subdomain.app_title or subdomain.name))
    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
  end

  def invitation(inviter, invitee, invitation_obj, role, subdomain, message = nil)
    @user = invitee
    @inviter = inviter
    @subdomain = subdomain
    @invitation_obj = invitation_obj
    @message = message

    case role
    when 'writer'
      @action = 'write new points at'
    when 'commenter'
      @action = 'comment on points at'
    when 'opiner'
      @action = 'give your opinion at'
    when 'proposer'
      @action = 'add new proposals at'
    when 'admin'
      @action = 'administer'
    when 'evaluator'
      @action = 'fact check'
    when 'editor'
      @action = 'edit'
    when 'visitor'
      @action = 'visit'
    else 
      if role[-1] == 'r'
        @action = "#{role[0..-3]}e"
      else
        @action = role
      end
    end

    if invitee.first_name
      to = format_email invitee.email, invitee.name    
    end

    from = format_email default_sender(subdomain), inviter.name
    reply_to = format_email inviter.email, inviter.name

    case invitation_obj.class.to_s

    when 'Subdomain'
      subject = "#{inviter.name} invites you to #{@action} #{invitation_obj.app_title}"
    when 'Proposal'
      subject = "#{inviter.name} invites you to #{@action} '#{invitation_obj.name}'"
    else
      raise "Why are you trying to send an invitation to a #{invitation_obj.class.to_s}?"
    end

    mail(:from => from, :to => to, :subject => subject, :reply_to => reply_to)

  end

end

