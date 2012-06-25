class EventMailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'

  #### DISCUSSION LEVEL ####
  def discussion_new_proposal(user, proposal, options, notification_type = '')
    @notification_type = notification_type
    @user = user
    @proposal = proposal
    @host = options[:host]
    @options = options
    @url = new_proposal_position_url(@proposal.long_id, :host => @host)

    email_with_name = "#{@user.username} <#{@user.email}>"

    subject = "new proposal \"#{@proposal.title}\""
    
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")

  end

  #### PROPOSAL LEVEL ####

  def proposal_milestone_reached(user, proposal, next_aggregate, options )
    @user = user
    @proposal = proposal
    @next_aggregate = next_aggregate
    @host = options[:host]
    @options = options
    email_with_name = "#{@user.username} <#{@user.email}>"

    subject = "update on \"#{@proposal.title}\""
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")

  end

  def proposal_new_point(user, pnt, options, notification_type)
    @notification_type = notification_type
    @user = user
    @point = pnt
    @host = options[:host]
    @proposal = @point.proposal
    @options = options
    email_with_name = "#{@user.username} <#{@user.email}>"

    if notification_type == 'your proposal'
      subject = "new #{@point.is_pro ? 'pro' : 'con'} point for your proposal \"#{@point.proposal.title}\""
    else
      subject = "new #{@point.is_pro ? 'pro' : 'con'} point for \"#{@point.proposal.title}\""
    end

    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")
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

    if notification_type == 'your point'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote"
    elsif notification_type == 'participant'
      subject = "#{@comment.user.username} commented on a discussion in which you participated"
    elsif notification_type == 'included point'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you follow"
    elsif notification_type == 'lurker'
      subject = "new comment on a #{@point.is_pro ? 'pro' : 'con'} point you follow"
    end

    email_with_name = "#{@user.username} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")
  end

  #### COMMENT LEVEL ####

  def reflect_new_bullet(user, bullet, comment, options, notification_type)
    @notification_type = notification_type
    @user = user
    @bullet = bullet
    @comment = comment
    @proposal = comment.root_object.proposal
    @host = options[:host]
    @options = options
    if comment.commentable_type == 'Point' 
      @url = proposal_point_url(comment.root_object.proposal.long_id, comment.root_object, :anchor => "comment-#{comment.id}", :host => @host)
    elsif comment.commentable_type == 'Position' 
      raise 'Need to implement position statement homepage'
    end   

    if notification_type == 'your comment'
      subject = "#{@bullet.user ? @bullet.user.username : 'Anonymous'} summarized your comment"
    elsif notification_type == 'other summarizer'
      subject = "#{@bullet.user ? @bullet.user.username : 'Anonymous'} summarized a comment you also summarized"
    end

    email_with_name = "#{@user.username} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")
  end

  def reflect_new_response(user, response, bullet, comment, options, notification_type)
    @notification_type = notification_type
    @user = user
    @bullet = bullet
    @comment = comment
    @response = response
    @proposal = comment.root_object.proposal
    @host = options[:host]
    @options = options
    if comment.commentable_type == 'Point' 
      @url = proposal_point_url(comment.root_object.proposal.long_id, comment.root_object, :anchor => "comment-#{comment.id}", :host => @host)
    elsif comment.commentable_type == 'Position' 
      raise 'Need to implement position statement homepage'
    end   

    if notification_type == 'your bullet'
      subject = "#{@comment.user.username} responded to your summary"
    elsif notification_type == 'other summarizer'
      subject = "#{@comment.user.username} responded to a summary of their comment"
    end

    email_with_name = "#{@user.username} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")
  end


  #### POSITION LEVEL ####

  private
    def current_tenant
      ApplicationController.find_current_tenant(request)
    end

end