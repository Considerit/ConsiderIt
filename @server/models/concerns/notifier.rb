module Notifier
  extend ActiveSupport::Concern

  included do 
    has_many :notifications, :as => :object, :class_name => 'Notification', :dependent => :destroy
  end


  def self.create_notification(event, object)
    #object.delay.create_notifications(event)
    object.create_notifications(event)
  end

  def create_notifications(event)
    subdomain = Thread.current[:subdomain]

    # who should get notified?

    # TODO: These methods don't yet support people explicitly subscribing to 
    #       a particular object without interacting with it at first

    case "#{event}_#{self.class.name}"
    when 'create_Comment', 'published_Assessment'
      comment = self
      point = self.point

      subject = self.class.name == 'Assessment' ? 'evaluation_of' : 'comment_on'

      # the author
      notify_user point.user, 'my_point', "#{subject}_my_point"

      # anyone who has included
      # anyone who has commented
      to_notify = point.inclusions.select(:user_id).map {|x| x.user_id }
      to_notify.concat point.comments.select(:user_id).map {|x| x.user_id }
      to_notify.concat point.requests.select(:user_id).map {|x| x.user_id }

      for user_id in to_notify.uniq
        if ![self.user_id, point.user_id].include?(user_id)
          notify_user User.find(user_id), 'touched_point', "#{subject}_touched_point"
        end
      end

    when 'published_Point'
      point = self
      proposal = point.proposal

      # the proposal author
      notify_user proposal.user, 'my_proposal', "new_point_on_my_proposal"
      # TODO: any WRITER, not just author

      # anyone who has opined
      to_notify = proposal.opinions.published.select(:user_id).map {|x| x.user_id }
      # TODO: notify anyone who has explicitly subscribed

      for user_id in to_notify.uniq
        if ![self.user_id, proposal.user_id].include?(user_id)
          notify_user User.find(user_id), 'touched_proposal', "new_point_on_touched_proposal"
        end
      end


    when 'create_Assessment'
      # notify the fact checkers
      roles = subdomain.user_roles()
      evaluators = roles.has_key?('evaluator') ? roles['evaluator'] : []

      for key in evaluators
        user = User.find_by id: key_id(key)
        # if send_email_to_user(user)
        #   AdminMailer.content_to_assess(assessment, user, subdomain).deliver_later
        # end
        notify_user user, "evaluator", "request"
      end


    end

  end

  def notify_user(user, channel, event_type)
    return if !user

    notifier_type = self.class.name

    if user.subscription_settings.has_key?("/#{notifier_type.downcase}/#{self.id}")
      notification_pref = user.subscription_settings["/#{notifier_type.downcase}/#{self.id}"]
    else 
      notification_pref = user.subscription_settings[channel]
    end

    if notification_pref != 'none'
      subdomain = Thread.current[:subdomain]
      notification = Notification.create!({
        user_id: user.id,
        notifier_id: self.id,
        notifier_type: notifier_type,
        event_type: event_type,
        event_channel: channel,
        sent_email: notification_pref == 'on-site' ? nil : false,
        subdomain_id: subdomain.id
      })
    end
  end

end