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

  def new_point(notification, to, from, subject, pnt, notification_type)
    @notification = notification
    @point = pnt
    @proposal = @point.proposal

    mail(:from => from, :to => to, :subject => subject)
  end

  def new_comment(notification, to, from, subject, comment, notification_type)
    @notification = notification
    @point = comment.point
    @proposal = @point.proposal
    @comment = comment

    mail(:from => from, :to => to, :subject => subject)
  end

  def new_assessment(user, pnt, assessment, subdomain, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @assessment = assessment
    @proposal = @point.proposal
    @subdomain = subdomain

    to = format_email user.email, user.name
    from = format_email(default_sender(subdomain), (subdomain.app_title or subdomain.name))

    if notification_type == 'your point'
      subject = "a point you wrote has been fact checked"
    else
      subject = "a point you follow has been fact checked"
    end

    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
  end



end

