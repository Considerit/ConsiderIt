require 'mail'

class DigestMailer < Mailer
  layout 'digest'

  def digest(subdomain, user, new_stuff, last_sent_at, send_limit)
    Translations::Translation.SetTranslationContext(user, subdomain)

    @send_limit = send_limit
    @last_sent_at = last_sent_at
    @new_stuff = new_stuff

    @anonymize_everything = subdomain.customization_json['anonymize_everything']
    @hide_opinions = subdomain.customization_json['hide_opinions']
    @frozen = subdomain.customization_json['contribution_phase'] == 'frozen'

    @subdomain = subdomain
    @user = user

    subject = Translations::Translation.get( {id: "email.digest.subject_line", forum_name: subdomain.title},    
                  "New activity at {forum_name}")

    subject = subject_line subject, @subdomain

            
    u = user.email
    t = user.auth_token(subdomain)

    unsubscribe_link = "https://#{subdomain.considerit_host}/dashboard/email_notifications?unsubscribe=true&u=#{u}&t=#{t}"
    headers({
      "List-Unsubscribe-Post": "List-Unsubscribe=One-Click", 
      "List-Unsubscribe": "<#{unsubscribe_link}>"
    })

    send_mail from: from_field(@subdomain), to: to_field(user), subject: subject
    
    Translations::Translation.ClearTranslationContext()

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