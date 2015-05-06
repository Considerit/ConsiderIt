########
# Email notification hooks
# http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html
########

def send_email_to_user(user)
  return !!(user.email && user.email.length > 0 && !user.email.match('\.ghost') && !user.no_email_notifications)
end

##################################################
############ Notifications for moderatable models


# Notifications for new proposals are not enabled
notify_proposal = Proc.new do |data|
  proposal = data[:proposal] || data[:model]
  current_subdomain = data[:current_subdomain]

  # current_subdomain.follows.where(:follow => true).each do |follow|
  #   # if follower's action triggered event, skip...
  #   if follow
  #     if follow.user_id == proposal.user_id 
  #       next
  #     # if follower doesn't have an email address, skip...
  #     elsif !follow.user.email || follow.user.email.length == 0
  #       next
  #     else 
  #       EventMailer.discussion_new_proposal(follow.user, proposal, current_subdomain '').deliver_later
  #     end
  #   end
  # end

end

notify_point = Proc.new do |data|

  point = data[:point] || data[:model]

  proposal = point.proposal
  current_subdomain = data[:current_subdomain]

  voters = proposal.opinions.published.select(:user_id).uniq.map {|x| x.user_id }
  proposal.followers.each do |u|
    next if !send_email_to_user(u)

    # if follower's action triggered event, skip...
    if u.id == point.user_id 
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

    EventMailer.new_point(u, point, current_subdomain, notification_type).deliver_later

  end

end


notify_comment = Proc.new do |args|
  comment = args[:model] || args[:comment]
  point = comment.point
  current_subdomain = args[:current_subdomain]

  commenters = point.comments.select(:user_id).uniq.map {|x| x.user_id }
  includers = point.inclusions.select(:user_id).uniq.map {|x| x.user_id }

  point.followers.each do |u|
    next if !send_email_to_user(u)

    # if follower's action triggered event, skip...
    if u.id == comment.user_id 
      next

    # if follower is author of point
    elsif u.id == point.user_id
      notification_type = 'your point'

    # if follower is a participant in the discussion
    elsif commenters.include? u.id
      notification_type = 'participant'

    # if follower included the point
    elsif includers.include? u.id
      notification_type = 'included point'

    # lurker 
    else
      notification_type = 'lurker'
    end

    EventMailer.new_comment(u, point, comment, current_subdomain, notification_type).deliver_later
  end

end

# Checks whether now is an appropriate time to send a notification
def send_notification_on_create(moderatable_type, current_subdomain)
  return [nil, 0, 3].include?(current_subdomain.send("moderate_#{moderatable_type}s_mode"))
end

########
# Creation notification events for moderatable models
########

def handle_moderatable_creation_event(moderatable_type, notification_method, args)
  data = args.last

  if send_notification_on_create(moderatable_type, data[:current_subdomain])
    notification_method.call data
  end
  
  current_subdomain = data[:current_subdomain]
  if current_subdomain.classes_to_moderate.length > 0 && current_subdomain["moderate_#{moderatable_type}s_mode"] > 0
    # send to all users with moderator status
    roles = current_subdomain.user_roles()
    moderators = roles.has_key?('moderator') ? roles['moderator'] : []

    moderators.each do |key|
      begin
        user = User.find(key_id(key))
      rescue
      end
      if user
        AdminMailer.content_to_moderate(user, current_subdomain).deliver_later
      end
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

  if !send_notification_on_create(moderatable_type, data[:current_subdomain])
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


ActiveSupport::Notifications.subscribe("assessment_completed") do |*args|
  data = args.last
  assessment = data[:assessment]
  current_subdomain = data[:current_subdomain]

  assessable = assessment.root_object

  commenters = assessable.comments.select(:user_id).uniq.map {|x| x.user_id }
  includers = assessable.inclusions.select(:user_id).uniq.map {|x| x.user_id }
  requesters = assessment.requests.select(:user_id).uniq.map {|x| x.user_id }

  assessable.follows.where(:follow => true).each do |follow|

    if !follow.user || !follow.user.email || follow.user.email.length == 0
      next

    # if follower is author of point
    elsif follow.user_id == assessable.user_id
      notification_type = 'your point'

    # if follower requested the check
    elsif requesters.include?(follow.user_id)
      notification_type = 'requested by you'
    
    # if follower is a participant in the discussion
    elsif commenters.include? assessable.user_id
      notification_type = 'participant'

    # if follower included the point
    elsif includers.include? follow.user_id
      notification_type = 'included point'
    end

    next if !send_email_to_user(follow.user)

    EventMailer.new_assessment(follow.user, assessable, assessment, current_subdomain, notification_type).deliver_later

  end

end
