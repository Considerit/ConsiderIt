require 'mail'

class DigestMailer < Mailer


  def proposal(proposal, user, notifications)
    @notifications = notifications
    @proposal = proposal
    @subdomain = proposal.subdomain
    @user = user

    @digest_object = proposal

    subject = user.id == proposal.id \
                         ? "New activity on your" \
                         : "New activity on"

    subject = subject_line "#{subject} \"#{proposal.title(50)}\"", @subdomain

    send_mail from: from_field(@subdomain), to: to_field(user), subject: subject
  end

  def subdomain(subdomain, user, notifications)
    @notifications = notifications
    @subdomain = subdomain
    @user = user

    @digest_object = subdomain

    subject = nil

    subject = "New activity"

    subject = subject_line subject, @subdomain

    send_mail from: from_field(@subdomain), to: to_field(user), subject: subject
  end


  def send_mail(**message_params) 
    mail message_params do |format|
      @part = 'text'
      format.text
      @part = 'html'
      format.html
    end
  end

  def to_field(user)
    format_email user.email, user.name
  end

  def from_field(subdomain)
    format_email default_sender(subdomain), \
                (subdomain.app_title or subdomain.name)
  end

end