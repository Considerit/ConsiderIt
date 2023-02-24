require 'mail'

class EventMailer < Mailer

  def send_message(message, current_user, subdomain)

    message['recipient'] = User.find key_id(message['recipient'])
    message['sender'] = current_user

    Translations::Translation.SetTranslationContext(message['recipient'], subdomain)

    @message = message
    @subdomain = subdomain

    to = format_email message['recipient'].email, message['recipient'].name

    # from e.g. Moderator <hank@cityclub.org>
    from = format_email default_sender(subdomain), message['sender_mask']
    reply_to = format_email current_user.email, message['sender_mask']

    mail(:from => from, :to => to, :subject => subject_line(@message['subject'], subdomain), :bcc => from, :reply_to => reply_to)
    Translations::Translation.ClearTranslationContext()
  end


  #################################
  # TRANSLATIONS
  # HARDCODING ALERT BELOW!!!
  def translations_proposed(subdomain, updates)

    @subdomain = subdomain
    @url = "https://#{subdomain.name}.#{APP_CONFIG[:domain]}/dashboard/translations"
    @updates = updates


    to = "translations@consider.it"

    from = format_email default_sender(subdomain), "Considerit Translator subsystem"

    mail(:from => from, :to => to, :subject => subject_line("[considerit-#{APP_CONFIG[:region]}] translations awaiting approval", subdomain))
  end

  def translations_native_changed(subdomain, native_updates)

    @subdomain = subdomain
    @url = "https://#{subdomain.name}.#{APP_CONFIG[:domain]}/dashboard/translations"
    @native_updates = native_updates

    to = "translations@consider.it"

    from = format_email default_sender(subdomain), "Considerit Translator subsystem"

    mail(:from => from, :to => to, :subject => subject_line("[considerit-#{APP_CONFIG[:region]}] native translations added", subdomain))
  end
  #####################################################

end

