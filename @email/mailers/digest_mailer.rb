require 'mail'

class DigestMailer < Mailer

  def digest(subdomain, user, notifications)

    @subdomain_notifications = (notifications['Subdomain'] || {})[subdomain.id]
    @proposal_notifications = notifications['Proposal'] || {}

    @subdomain = subdomain
    @user = user

    subject = "Summary of recent activity"

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