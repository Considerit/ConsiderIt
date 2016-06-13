require 'mail'

class DigestMailer < Mailer
  layout 'digest'

  def digest(subdomain, user, notifications, new_stuff, last_sent_at, send_limit)

    @send_limit = send_limit
    @last_sent_at = last_sent_at
    @new_stuff = new_stuff
    @subdomain_notifications = (notifications['Subdomain'] || {})[subdomain.id]
    # @proposal_notifications = notifications['Proposal'] || {}

    @subdomain = subdomain
    @user = user

    subject = "New activity at #{subdomain.title}"

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
                (subdomain.title)
  end

  def subject_line(subject, subdomain)
    "[considerit] #{subject}"
  end


end