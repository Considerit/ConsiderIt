require 'mail'

class EventMailer < Mailer


  def send_message(message, current_user, subdomain)
    @message = message
    @subdomain = subdomain

    recipient = message.addressedTo()

    to = format_email recipient.email, recipient.name

    # from e.g. Moderator <hank@cityclub.org>
    from = format_email default_sender(subdomain), current_user.name
    reply_to = format_email current_user.email, current_user.name

    mail(:from => from, :to => to, :subject => subject_line(@message.subject, subdomain), :bcc => from, :reply_to => reply_to)

  end

  def new_point(user, pnt, subdomain, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @proposal = @point.proposal
    @subdomain = subdomain

    to = format_email user.email, user.name    
    from = format_email(default_sender(subdomain), (subdomain.app_title or subdomain.name))

    if notification_type == 'your proposal'
      subject = "new #{@point.is_pro ? 'pro' : 'con'} point for your proposal \"#{@point.proposal.title}\""
    else
      subject = "new #{@point.is_pro ? 'pro' : 'con'} point for \"#{@point.proposal.title}\""
    end

    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
  end

  def new_comment(user, pnt, comment, subdomain, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @comment = comment
    @proposal = @point.proposal
    @subdomain = subdomain

    to = format_email user.email, user.name
    from = format_email(default_sender(subdomain), (subdomain.app_title or subdomain.name))

    if notification_type == 'your point'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote"
    elsif notification_type == 'participant'
      subject = "#{@comment.user.name} commented on a discussion in which you participated"
    elsif notification_type == 'included point'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you follow"
    else
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you follow"
    end

    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))
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

