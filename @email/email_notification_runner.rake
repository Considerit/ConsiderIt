task :send_email_notifications => :environment do


  def digest_proposal
    channels_to_aggregate = ['touched_proposal', 'my_proposal', 'touched_point', 'my_point']

    candidate_notifications = {}

    for notification in Notification.where(sent_email: false).where("event_channel IN (?)", channels_to_aggregate)
      user = notification.user_id
      proposal = notification.root_object.proposal.id
      channel = notification.event_channel
      etype = notification.event_type

      candidate_notifications[user] ||= {}
      candidate_notifications[user][proposal] ||= {}
      candidate_notifications[user][proposal][channel] ||= {}
      candidate_notifications[user][proposal][channel][etype] ||= []

      candidate_notifications[user][proposal][channel][etype] = 1

    end

    candidate_notifications
  end

  def digest_point
    channels_to_aggregate = ['touched_point', 'my_point']
  end

  pp digest_proposal

  # Aggregate notifications by user, proposal, channel, event_type
  # These are for notifications related to a particular proposal
  candidate_notifications = {}
  for notification in Notification.where(sent_email: false)
    candidate_notifications[notification.user_id] ||= {}

    candidate_notifications[notification.user_id][notification.event_channel] ||= {}

    candidate_notifications[notification.user_id][notification.event_channel][notification.event_type] ||= []

    candidate_notifications[notification.user_id][notification.event_channel][notification.event_type].push 1 #notification

  end

  pp candidate_notifications


  for notification in Notification.where(sent_email: false)
    object = notification.root_object
    subdomain = notification.subdomain

    to = format_email notification.user.email, notification.user.name
    from = format_email(default_sender(subdomain), (subdomain.app_title or subdomain.name))

    case notification.event_type


    when "new_point_on_my_proposal"
      subject = "new #{object.is_pro ? 'pro' : 'con'} point for your proposal \"#{object.proposal.title}\""
      subject = subject_line(subject, subdomain)

      notification_type = "your proposal"
      EventMailer.new_point(notification, to, from, subject, object, notification_type).deliver_now
      notification.sent_email = true
      notification.save


    when "new_point_on_touched_proposal"
      subject = "new #{object.is_pro ? 'pro' : 'con'} point for \"#{object.proposal.title}\""
      subject = subject_line(subject, subdomain)

      notification_type = "touched proposal"
      EventMailer.new_point(notification, to, from, subject, object, notification_type).deliver_now
      notification.sent_email = true
      notification.save

    when "comment_on_my_point"
      subject = "new comment on a #{object.point.is_pro ? 'pro' : 'con'} point you wrote"
      subject = subject_line(subject, subdomain)

      notification_type = "my point"

      EventMailer.new_comment(notification, to, from, subject, object, notification_type).deliver_now
      notification.sent_email = true
      notification.save

    when "comment_on_touched_point"
      subject = "new comment on a #{object.point.is_pro ? 'pro' : 'con'} point you follow"
      subject = subject_line(subject, subdomain)

      notification_type = "touched point"

      EventMailer.new_comment(notification, to, from, subject, object, notification_type).deliver_now
      notification.sent_email = true
      notification.save


    when "evaluation_of_my_point"
      # EventMailer.new_assessment(follow.user, assessable, assessment, subdomain, notification_type).deliver_now

    when "evaluation_of_touched_point"

    end



    # AdminMailer.content_to_assess(assessment, user, subdomain).deliver_now
  end

end


def send_email_to_user(user)
  return !!(user.email && user.email.length > 0 && !user.email.match('\.ghost') && !user.no_email_notifications)
end

def format_email(addr, name = nil)
  address = Mail::Address.new addr # ex: "john@example.com"
  if name
    address.display_name = name # ex: "John Doe"
  end
  # Set the From or Reply-To header to the following:
  address.format # returns "John Doe <john@example.com>"
end  

def default_sender(subdomain)
  subdomain && subdomain.notifications_sender_email && subdomain.notifications_sender_email.length > 0 ? subdomain.notifications_sender_email : APP_CONFIG[:email]
end

def subject_line(subject, subdomain)
  title = subdomain.app_title or subdomain.name
  "[#{title}] #{subject}"
end