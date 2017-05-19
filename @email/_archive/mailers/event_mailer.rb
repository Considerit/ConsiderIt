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


end

