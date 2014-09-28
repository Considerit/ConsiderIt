########
# Email notification hooks
# http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html
########


##################################################
############ Notifications for moderatable models


#### notify_proposal is NOT MIGRATED / TESTED!!!!######
notify_proposal = Proc.new do |data|
  #params : proposal, current_tenant, mail_options
  proposal = data[:proposal] || data[:model]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  current_tenant.follows.where(:follow => true).each do |follow|
    # if follower's action triggered event, skip...
    if follow
      if follow.user_id == proposal.user_id 
        next
      # if follower doesn't have an email address, skip...
      elsif !follow.user.email || follow.user.email.length == 0
        next
      else 
        EventMailer.discussion_new_proposal(follow.user, proposal, mail_options, '').deliver!
      end
    end
  end

end

notify_point = Proc.new do |data|
  #params : point, current_tenant, mail_options

  point = data[:point] || data[:model]

  proposal = point.proposal
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  voters = proposal.opinions.published.select(:user_id).uniq.map {|x| x.user_id }

  current_tenant.users.each do |u|

    next if !proposal.following(u)

    # if follower's action triggered event, skip...
    if u.id == point.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !u.email || u.email.length == 0
      next

    # if follower is the proposal author
    elsif u.id == proposal.user_id
      notification_type = 'your proposal' 
    
    # if follower has submitted a opinion on this proposal
    elsif voters.include? u.id
      notification_type = 'opinion submitter'

    # lurker 
    else
      notification_type = 'lurker'

    end

    EventMailer.proposal_new_point(u, point, mail_options, notification_type).deliver!

  end

end

#### notify_comment is NOT MIGRATED / TESTED!!!!######
notify_comment = Proc.new do |args|
  #params: comment, current_tenant, mail_options
  comment = args[:model] || args[:comment]
  commentable = comment.root_object
  current_tenant = args[:current_tenant]
  mail_options = args[:mail_options]

  commenters = commentable.comments.select(:user_id).uniq.map {|x| x.user_id }
  includers = commentable.inclusions.select(:user_id).uniq.map {|x| x.user_id }

  commentable.follows.where(:follow => true).each do |follow|

    # if follower's action triggered event, skip...
    if follow.user_id == comment.user_id 
      next

    # if follower doesn't have an email address, skip...
    elsif !follow.user || !follow.user.email || follow.user.email.length == 0
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

# Checks whether now is an appropriate time to send a notification
def send_notification_on_create(moderatable_type, current_tenant)
  return true if !current_tenant.enable_moderation || [0,3].include?(current_tenant.send("moderate_#{moderatable_type}s_mode"))
end

########
# Creation notification events for moderatable models
########

def handle_moderatable_creation_event(moderatable_type, notification_method, args)
  data = args.last

  if send_notification_on_create(moderatable_type, data[:current_tenant])
    notification_method.call data
  end

  if current_tenant.enable_moderation
    # send to all users with moderator status
    moderators = []
    accnt.users.where('roles_mask > 0').each do |u|
      if u.has_any_role? :moderator #, :admin, :superadmin
        moderators.push(u)
      end
    end
    moderators.each do |user|
      AlertMailer.content_to_moderate(user, accnt).deliver!
    end
  end
  

end

ActiveSupport::Notifications.subscribe("proposal:published") do |*args|
  handle_moderatable_creation_event 'proposal', notify_proposal, args
end
ActiveSupport::Notifications.subscribe("point:published") do |*args|
  handle_moderatable_creation_event 'point', notify_point, args
end
ActiveSupport::Notifications.subscribe("comment:point:created") do |*args|
  handle_moderatable_creation_event 'comment', notify_comment, args
end

########
# Positive moderation events
########
def handle_moderation_pass_event(moderatable_type, notification_method, args)
  data = args.last

  if !send_notification_on_create(moderatable_type, data[:current_tenant])
    notification_method.call data
  end

end

ActiveSupport::Notifications.subscribe("moderation:proposal:passed") do |*args|
  handle_moderation_pass_event('proposal', notify_proposal, args)
end
ActiveSupport::Notifications.subscribe("moderation:point:passed") do |*args|
  handle_moderation_pass_event('point', notify_point, args)
end
ActiveSupport::Notifications.subscribe("moderation:comment:passed") do |*args|
  handle_moderation_pass_event('comment', notify_comment, args)
end




##################################################
########## Misc Notifications




###########################
##### PROPOSAL LEVEL ######
###########################

#### alert_proposal_publicity_changed is NOT MIGRATED / TESTED!!!!######

ActiveSupport::Notifications.subscribe("alert_proposal_publicity_changed") do |*args|
  data = args.last
  users = data[:users]
  inviter = data[:inviter]
  proposal = data[:proposal]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  users.delete(inviter.email) if inviter #don't email inviter twice if they specified themselves in the list

  users.each do |user|
    if user.length > 0
      UserMailer.invitation(user, proposal, 'invitee', mail_options).deliver!
    end
  end
  if inviter && !inviter.email.nil? && inviter.email.length > 0
    UserMailer.invitation(inviter.email, proposal, 'your proposal', mail_options).deliver!
  end

end


#### published_new_opinion is NOT MIGRATED / TESTED!!!!######
ActiveSupport::Notifications.subscribe("published_new_opinion") do |*args|

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
  opinion = data[:opinion]

  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]  
  proposal = opinion.proposal

  # do not send summary mail if one was already sent today
  if proposal.followable_last_notification === DateTime.now
    return
  end

  proposal.followable_last_notification_milestone ||= 0 
  threshhold_for_next_notification = fib(proposal.followable_last_notification_milestone + 1)
  opinions = proposal.opinions.published
  if proposal.user_id
    opinions = opinions.where("user_id != #{proposal.user_id}")
  end

  if opinions.count >= threshhold_for_next_notification 
    next_milestone = milestone_greater_than(opinions.count)

    pp "Notification for Proposal '#{proposal.title}', because #{opinions.count} >= #{threshhold_for_next_notification}. Setting next milestone for #{next_milestone} (#{fib(next_milestone)})}"

    proposal.follows.where(:follow => true).where("user_id != #{opinion.user_id}").each do |follow|
      pp "\t Notifying #{follow.user.name}"
      EventMailer.proposal_milestone_reached(follow.user, proposal, fib(next_milestone), mail_options).deliver!
    end
    proposal.followable_last_notification_milestone = next_milestone
    proposal.followable_last_notification = DateTime.now
    proposal.save

  end
end
