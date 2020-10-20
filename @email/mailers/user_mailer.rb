require 'mail'

class UserMailer < Mailer

  def welcome_new_customer(user, subdomain, plan)
    set_translation_context(user, subdomain)

    @user = user
    subject = translator("email.welcome.subject_line", "Welcome to Consider.it!")
    @subdomain = subdomain
    @plan = plan

    to = format_email @user.email, @user.name
    from = format_email('admin@consider.it', 'Consider.it')
    
    params = {
      :from => from, 
      :to => to, 
      :bcc => ['hello@consider.it'], 
      :subject => subject_line(subject, subdomain)
    }
    mail params do |format|
      @part = 'text'
      format.text
      @part = 'html'
      format.html
    end
    clear_translation_context()
  end


  def reset_password_instructions(user, token, subdomain)
    set_translation_context(user, subdomain)

    @user = user
    @token = token 
    subject = translator("email.password_reset.subject_line", "password reset instructions")
    @subdomain = subdomain

    to = format_email @user.email, @user.name
    from = format_email(default_sender(subdomain), (subdomain.title))
    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
    clear_translation_context()
  end

  def verification(user, subdomain)
    set_translation_context(user, subdomain)

    @user = user
    @token = user.auth_token(subdomain)
    @subdomain = subdomain
    subject = translator("email.email_verification.subject_line", "please verify your email address")

    # puts "And the token is ", @token
    to = format_email @user.email, @user.name
    from = format_email(default_sender(subdomain), (subdomain.title))
    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
    clear_translation_context()
  end

  def invitation(inviter, invitee, invitation_obj, role, subdomain, message = nil)
    set_translation_context(invitee, subdomain)

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
      subject = translator({id: "email.invitation.#{role}", name: inviter.name, place: invitation_obj.name}, 
                           "{name} invites you to #{@action} {place}")
    when 'Proposal'
      subject = translator({id: "email.invitation.#{role}", name: inviter.name, place: invitation_obj.name}, 
                           "{name} invites you to #{@action} {place}")

    else
      raise "Why are you trying to send an invitation to a #{invitation_obj.class.to_s}?"
    end

    mail(:from => from, :to => to, :subject => subject, :reply_to => reply_to)
    clear_translation_context()
  end

end

