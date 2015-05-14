require 'mail'

class EventMailer < Mailer

  def send_message(message, current_user, subdomain)
    message['recipient'] = User.find key_id(message['recipient'])
    message['sender'] = current_user

    @message = message
    @subdomain = subdomain

    to = format_email message['recipient'].email, message['recipient'].name

    # from e.g. Moderator <hank@cityclub.org>
    from = format_email default_sender(subdomain), message['sender_mask']
    reply_to = format_email current_user.email, message['sender_mask']

    mail(:from => from, :to => to, :subject => subject_line(@message['subject'], subdomain), :bcc => from, :reply_to => reply_to)
  end


end

