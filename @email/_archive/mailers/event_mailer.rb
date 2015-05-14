require 'mail'

class EventMailer < Mailer

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

