
##############################
##### DISCUSSION LEVEL #######
##############################

ActiveSupport::Notifications.subscribe("new_published_proposal") do |*args|
  data = args.last
  proposal = data[:proposal]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  current_tenant.follows.where(:follow => true).each do |follow|

    # if follower's action triggered event, skip...
    if follow.user_id == proposal.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !follow.user.email || follow.user.email.length == 0
      next

    else 
      EventMailer.discussion_new_proposal(follow.user, proposal, mail_options, '').deliver!

    end

  end
  if current_tenant.tweet_notifications
    msg = new_published_proposal_tweet(proposal)
    post_to_twitter_client(current_tenant, msg)
  end
end

def new_published_proposal_tweet(proposal)
  proposal_link = Rails.application.routes.url_helpers.new_proposal_position_url(proposal.long_id, :host => proposal.account.host_with_port)
  proposal_link = shorten_link(proposal_link)

  space_for_body = 140 - proposal_link.length - 23
  "New proposal: \"#{proposal.title_with_hashtags(space_for_body)} ...\" #{proposal_link}"
end


###########################
##### PROPOSAL LEVEL ######
###########################

ActiveSupport::Notifications.subscribe("published_new_position") do |*args|
  def fib(n)
    curr = 0; succ = 1
    n.times do |i|
      curr, succ = succ, curr + succ
    end
    curr
  end

  def milestone_greater_than(n)
    curr = 0;succ = 1;milestone = 0
    until curr > n do
      curr, succ = succ, curr + succ
      milestone += 1
    end
    milestone
  end

  data = args.last
  position = data[:position]

  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]  
  proposal = position.proposal

  # do not send summary mail if one was already sent today
  if proposal.followable_last_notification === DateTime.now
    return
  end

  proposal.followable_last_notification_milestone ||= 0 
  threshhold_for_next_notification = fib(proposal.followable_last_notification_milestone + 1)
  positions = proposal.positions.published
  if proposal.user_id
    positions = positions.where("user_id != #{proposal.user_id}")
  end

  if positions.count >= threshhold_for_next_notification 
    next_milestone = milestone_greater_than(positions.count)

    pp "Notification for Proposal '#{proposal.title}', because #{positions.count} >= #{threshhold_for_next_notification}. Setting next milestone for #{next_milestone} (#{fib(next_milestone)})}"

    proposal.follows.where(:follow => true).where("user_id != #{position.user_id}").each do |follow|
      pp "\t Notifying #{follow.user.name}"
      EventMailer.proposal_milestone_reached(follow.user, proposal, fib(next_milestone), mail_options).deliver!
    end
    proposal.followable_last_notification_milestone = next_milestone
    proposal.followable_last_notification = DateTime.now
    proposal.save

    if positions.count > 10 #only send tweets for milestones past 10 positions
      msg = new_proposal_milestone_tweet(proposal)
      post_to_twitter_client(current_tenant, msg)
    end

  end
end

def new_proposal_milestone_tweet(proposal)
  proposal_link = Rails.application.routes.url_helpers.proposal_url(proposal.long_id, :host => proposal.account.host_with_port)
  proposal_link = shorten_link(proposal_link)

  lead = "Milestone: #{proposal.positions.count} positions for "
  space_for_body = 140 - proposal_link.length - lead.length - 9
  "#{lead}\"#{proposal.title_with_hashtags(space_for_body)} ...\" #{proposal_link}"
end

ActiveSupport::Notifications.subscribe("new_published_Point") do |*args|

  data = args.last
  point = data[:point]
  proposal = point.proposal
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  voters = proposal.positions.published.select(:user_id).uniq.map {|x| x.user_id }

  proposal.follows.where(:follow => true).each do |follow|

    # if follower's action triggered event, skip...
    if follow.user_id == point.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !follow.user.email || follow.user.email.length == 0
      next

    # if follower is the proposal author
    elsif follow.user_id == proposal.user_id
      notification_type = 'your proposal' 
    
    # if follower has submitted a position on this proposal
    elsif voters.include? follow.user_id
      notification_type = 'position submitter'

    # lurker 
    else
      notification_type = 'lurker'

    end

    EventMailer.proposal_new_point(follow.user, point, mail_options, notification_type).deliver!

  end

end

#########################
##### POINT LEVEL #######
#########################

ActiveSupport::Notifications.subscribe("new_comment_on_Point") do |*args|

  data = args.last
  commentable = data[:commentable]
  comment = data[:comment]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]


  commenters = commentable.comments.select(:user_id).uniq.map {|x| x.user_id }
  includers = commentable.inclusions.select(:user_id).uniq.map {|x| x.user_id }

  commentable.follows.where(:follow => true).each do |follow|

    # if follower's action triggered event, skip...
    if follow.user_id == comment.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !follow.user.email || follow.user.email.length == 0
      next

    # if follower is author of commentable
    elsif follow.user_id == commentable.user_id
      notification_type = 'your point'

    # if follower is a participant in the discussion
    elsif commenters.include? follow.user_id
      notification_type = 'participant'

    # if follower included the point
    elsif includers.include? follow.user_id
      notification_type = 'included point'

    # lurker 
    else
      notification_type = 'lurker'
    end

    EventMailer.point_new_comment(follow.user, commentable, comment, mail_options, notification_type).deliver!
  end

end

ActiveSupport::Notifications.subscribe("new_comment_on_Position") do |*args|
  data = args.last
  commentable = data[:commentable]
  comment = data[:comment]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  commenters = commentable.comments.select(:user_id).uniq
  includers = commentable.inclusions.select(:user_id).uniq

  commentable.follows.where(:follow => true).each do |follow|

    # if follower's action triggered event, skip...
    if follow.user_id == comment.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !follow.user.email || follow.user.email.length == 0
      next

    # if follower is author of commentable
    elsif follow.user_id == commentable.user_id
      #EventMailer.someone_discussed_your_position(follow.user, commentable, comment, mail_options).deliver!

    # else if follower is a participant in the discussion
    elsif commenters.include? follow.user_id
      #TODO: make sure this message is relevant for position
      #EventMailer.someone_commented_on_thread(follow.user, commentable, comment, mail_options).deliver!

    # TODO
    # lurker 
    else

    end

  end

end


###########################
##### COMMENT LEVEL #######
###########################

ActiveSupport::Notifications.subscribe("new_bullet_on_a_comment") do |*args|
  data = args.last
  bullet = data[:bullet]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  bullet.comment.follows.where(:follow => true).each do |follow|

    if follow.user_id == bullet.user_id
      next

    elsif !follow.user.email || follow.user.email.length == 0
      next

    elsif follow.user_id == bullet.comment.user_id
      notification_type = 'your comment'
    
    else
      notification_type = 'other summarizer'
    end

    EventMailer.reflect_new_bullet(follow.user, bullet, bullet.comment, mail_options, notification_type).deliver!

  end

end

ActiveSupport::Notifications.subscribe("response_to_bullet_on_a_comment") do |*args|
  data = args.last
  response = data[:response]
  bullet = response.bullet_revision
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  bullet.comment.follows.where(:follow => true).each do |follow|

    if follow.user_id == response.user_id
      next

    elsif !follow.user.email || follow.user.email.length == 0
      next

    elsif follow.user_id == bullet.user_id
      notification_type = 'your bullet'
    
    else
      notification_type = 'other summarizer'
    end

    EventMailer.reflect_new_response(follow.user, response, bullet, bullet.comment, mail_options, notification_type).deliver!

  end

end

##########################
### USERS ###
####################


ActiveSupport::Notifications.subscribe("first_position_by_new_user") do |*args|
  data = args.last
  user = data[:user]
  proposal = data[:proposal]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]


  UserMailer.confirmation_instructions(user, proposal, mail_options).deliver!

end



##########################
### Twitter
##########################

def shorten_link(link)
  shortened_link = ''
  if link && APP_CONFIG.has_key?(:bitly)
    bitly_client = Bitly.new(APP_CONFIG[:bitly][:user_name], APP_CONFIG[:bitly][:api_key])
    shortened_link = bitly_client.shorten(link).short_url
  end
  shortened_link
end

def post_to_twitter_client(account, msg)
  if account.tweet_notifications

    twitter_client = Twitter::Client.new(
      :consumer_key => account.socmedia_twitter_consumer_key,
      :consumer_secret => account.socmedia_twitter_consumer_secret,
      :oauth_token => account.socmedia_twitter_oauth_token,
      :oauth_token_secret => account.socmedia_twitter_oauth_token_secret
    )
    begin
      twitter_client.update(msg)
      #logger.info "Sent tweet: #{msg}"
      pp "Sent tweet: #{msg}"
    rescue
      pp "Could not send tweet: #{msg}"
      #begin
        #logger.error "Could not send tweet: #{msg}"
      #rescue
      #end
    end
  end
end
