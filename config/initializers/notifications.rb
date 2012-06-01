##############################
##### DISCUSSION LEVEL #######
##############################

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
      UserMailer.proposal_milestone_reached(follow.user, proposal, fib(next_milestone), mail_options).deliver!
    end
    # proposal.followable_last_notification_milestone = next_milestone
    # proposal.followable_last_notification = DateTime.now
    # proposal.save

  end
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

    # if follower has submitted a position on this proposal
    elsif voters.include? follow.user_id
      #TODO: customize this for position takers
      UserMailer.proposal_new_point_for_position_takers(follow.user, point, mail_options).deliver!

    # TODO
    # lurker 
    else

    end

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
      UserMailer.someone_discussed_your_point(follow.user, commentable, comment, mail_options).deliver!

    # else if follower is a participant in the discussion
    elsif commenters.include? follow.user_id
      UserMailer.someone_commented_on_thread(follow.user, commentable, comment, mail_options).deliver!

    # else if follower included the point
    elsif includers.include? follow.user_id
      UserMailer.someone_commented_on_an_included_point(follow.user, commentable, comment, mail_options).deliver!

    # TODO
    # lurker 
    else

    end

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

  comment.follows.where(:follow => true).each do |follow|

    # if follower's action triggered event, skip...
    if follow.user_id == comment.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !follow.user.email || follow.user.email.length == 0
      next

    # if follower is author of commentable
    elsif follow.user_id == commentable.user_id
      UserMailer.someone_discussed_your_position(follow.user, commentable, comment, mail_options).deliver!

    # else if follower is a participant in the discussion
    elsif commenters.include? follow.user_id
      #TODO: make sure this message is relevant for position
      UserMailer.someone_commented_on_thread(follow.user, commentable, comment, mail_options).deliver!

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

  follow = bullet.comment.root_object.follows.where(:user_id => bullet.comment.user_id, :follow => true).first
  if follow && follow.user.email && follow.user.email.length == 0
    UserMailer.someone_reflected_your_point(follow.user, bullet, bullet.comment, mail_options).deliver!
  end
end

ActiveSupport::Notifications.subscribe("response_to_bullet_on_a_comment") do |*args|
  data = args.last
  response = data[:response]
  bullet = response.bullet_revision
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  follow = bullet.comment.root_object.follows.where(:user_id => bullet.user_id, :follow => true).first
  if follow && follow.user.email && follow.user.email.length == 0
    UserMailer.your_reflection_was_responded_to(follow.user, response, bullet, bullet.comment, mail_options).deliver!
  end
end