require 'mail'

class EventMailer < Mailer

  def send_message(message, current_user, options = {})
    @message = message

    domain = options[:host].end_with?('consider.it') ? 'consider.it' : options[:host]
    message.sender = message.sender.gsub '{{domain}}', domain

    recipient = message.addressedTo()

    reply_to = format_email @message.sender, @message.senderName()
    to = format_email recipient.email, recipient.name

    subject = "[#{options[:app_title]}] #{@message.subject}"

    mail(:from => format_email('admin@consider.it', options[:app_title]), :to => to, :subject => subject, :reply_to => reply_to, :bcc => current_user.email)

  end

  #### DISCUSSION LEVEL ####
  def discussion_new_proposal(user, proposal, options, notification_type = '')
    @notification_type = notification_type
    @user = user
    @proposal = proposal
    @host = options[:host]
    @options = options
    @url = new_opinion_proposal_url(@proposal.long_id, :host => @host)

    subject = "new proposal \"#{@proposal.title}\""

    from = format_email(options[:from], options[:app_title])
    to = format_email user.email, user.name

    mail(:from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")

  end

  #### PROPOSAL LEVEL ####

  def proposal_milestone_reached(user, proposal, next_aggregate, options )
    @user = user
    @proposal = proposal
    @next_aggregate = next_aggregate
    @host = options[:host]
    @options = options

    from = format_email(options[:from], options[:app_title])
    to = format_email user.email, user.name

    subject = "update on \"#{@proposal.title}\""
    mail(from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")

  end

  def proposal_new_point(user, pnt, options, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @host = options[:host]
    @proposal = @point.proposal
    @options = options


    to = format_email user.email, user.name    
    from = format_email(options[:from], options[:app_title])

    if notification_type == 'your proposal'
      subject = "new #{@point.is_pro ? 'pro' : 'con'} point for your proposal \"#{@point.proposal.title}\""
    else
      subject = "new #{@point.is_pro ? 'pro' : 'con'} point for \"#{@point.proposal.title}\""
    end

    mail(:from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")
  end

  #### POINT LEVEL ####

  def point_new_comment(user, pnt, comment, options, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @comment = comment
    @proposal = @point.proposal
    @host = options[:host]
    @options = options


    to = format_email user.email, user.name
    from = format_email(options[:from], options[:app_title])

    if notification_type == 'your point'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote"
    elsif notification_type == 'participant'
      subject = "#{@comment.user.username} commented on a discussion in which you participated"
    elsif notification_type == 'included point'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you follow"
    else
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you follow"
    end

    mail(:from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")
  end

  def point_new_assessment(user, pnt, assessment, options, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @assessment = assessment
    @proposal = @point.proposal
    @host = options[:host]
    @options = options
    from = format_email(options[:from], options[:app_title])

    if notification_type == 'your point'
      subject = "a point you wrote has been fact checked"
    else
      subject = "a point you follow has been fact checked"
    end

    to = format_email user.email, user.name

    mail(:from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")
  end


end