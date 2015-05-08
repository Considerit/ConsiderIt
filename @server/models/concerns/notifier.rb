######################################################
# Notifier is the core of the Notifications subsystem.
#
# You can include Notifier in any model that will generate notifications. 
#
# Notifier is also responsible for: 
#    - Defining the subscription channels, events, and defaults that
#      are available to users. 
#
#    - Handling Notification creation when a relevant system event occurs
#
#    - Aggregating Notifications into a data structure that can be more
#      easily consumed by a system that consumes the Notifications
#      (e.g. email notifications or on-site messages)
#
# 
# 


module Notifier
  extend ActiveSupport::Concern

  included do 
    has_many :notifications, :as => :notifier, :class_name => 'Notification', :dependent => :destroy
  end


  #######################################
  # SUBSCRIPTION, CHANNEL, EVENT DEFAULTS
  #
  # Define subscription channels and event trigger defaults here. 
  #
  # The schema is : 
  #     object name {
  #         channels: {channel_name: channel_default, ...},
  #         events: {event_name: triggers_email_default, ...},
  #         constrained_to (optional): method(user)
  #     }, ...
  #
  # object name: the object type that the channels aggregate. 
  # channels: users can set different notification preferences per channel
  # events: the event types that get aggregated into these channels
  # triggers_email_default: whether this event can cause an email to be generated
  # constrained_to: A lambda that takes a user and is used to determine with the 
  #                 channels are relevant to this user. 
  #
  # These settings will get automatically consumed throughout the notifications 
  # subsystem. 
  @@subscriptions = {

    # Proposal-level channels
    'proposal' => {
      channels: {
        'my_proposal' => '24_hours', 
        'active_in_proposal' => '24_hours'},
      events: { 
        'new_comment_on_my_point' => true, 
        'new_assessment_on_my_point' => true,
        'new_comment_on_point_active_in' => true, 
        'new_assessment_on_point_active_in' => true,
        'new_comment' => false, 
        'new_assessment' => false,
        'new_point' => true, 
        'new_opinion' => false                           
      }
    }, 

    # Fact-checker channels
    'assessment' => {
      channels: {'evaluation' => '60_minutes'},
      events: { 'request' => true },
      constrained_to: lambda {|user| user.has_role?(:evaluator)}
    },
  }


  ################################
  # NOTIFICATION GENERATION
  ################################
  # This section of the code relates to the generation of Notifications
  # given system events.

  ########
  # PUBLIC
  # Notifier.create_notification should be called when there is an event
  # that should lead to a notification. 
  def self.create_notification(event, object)
    if !object.respond_to?(:notifications)
      pp "WARNING: Model #{object.class.name} does not include Notifier"
    end

    #object.delay.create_notifications(event)
    Notifier.create_notifications_offline(event, object)
  end



  #########
  # INTERNAL


  def self.create_notifications_offline(event, object)
    subdomain = Thread.current[:subdomain]

    # who should get notified?

    settings = nil
    unsubscribed = []

    proposal_channel = lambda do |user_id, proposal| 
      if proposal.user_id == user_id
        'my_proposal'
      else
        'active_in_proposal'
      end
    end

    object_name = object.class.name.downcase

    case "#{event}_#{object_name}"
    when 'create_comment', 'published_assessment'
      point = object.point
      proposal = point.proposal

      subscribed, unsubscribed = Notifier.subscribed_users "/proposal/#{proposal.id}", subdomain
          
      settings = [
        {
          channel: proposal_channel,          
          event: "new_#{object_name}_on_my_point",
          users: [point.user_id]
        }, {
          channel: proposal_channel,          
          event: "new_#{object_name}_on_point_active_in",
          users:  point.inclusions.select(:user_id).map {|x| x.user_id } \
                + point.comments.select(:user_id).map {|x| x.user_id } \
                + point.requests.select(:user_id).map {|x| x.user_id } \
                + subscribed.map {|u| u.id}
        }, {
          channel: proposal_channel,
          event: "new_#{object_name}",
          users:  proposal.opinions.published.select(:user_id).map {|x| x.user_id } \
                + [proposal.user_id]
        }
      ]

    when 'published_point', 'published_opinion'
      proposal = object.proposal
      subscribed, unsubscribed = Notifier.subscribed_users "/proposal/#{proposal.id}", subdomain

      settings = [ 
        {
          channel: proposal_channel,
          event: "new_#{object_name}",
          users:  proposal.opinions.published.select(:user_id).map {|x| x.user_id } \
                + [proposal.user_id] \
                + subscribed.map {|u| u.id}
        }
      ]

    when 'create_assessment'
      # notify the fact checkers

      evaluators = subdomain.user_roles()['evaluator'] || []
      
      settings = [
        {
          channel: "evaluation",
          event: "request",
          users: evaluators.map {|e| key_id(e)}
        }
      ]

    end

    notified = {}

    for event_group in settings

      for user_id in (event_group[:users] || [])
        if !notified.key?(user_id) && !unsubscribed.include?(user_id)
          channel = event_group[:channel].class.name != 'String' \
                  ? event_group[:channel].call(user_id, proposal) \
                  : event_group[:channel]
          Notifier.notify_user object, User.find_by(id: user_id), channel, event_group[:event]

          notified[user_id] = 1
        end
      end
    end
  end

  # Find users who have explicitly subscribed or unsubscribed to this object
  def self.subscribed_users(key, subdomain)
    explicit = subdomain.users.where("subscriptions like '%#{key}%'")
    subscribed = []
    unsubscribed = []
    for user in explicit
      subs = user.subscription_settings
      if subs[key]['method'] == 'none'
        unsubscribed.push user
      else 
        subscribed.push user
      end
    end

    [subscribed, unsubscribed]
  end

  def self.notify_user(object, user, channel, event_type)
    return if !user

    notifier_type = object.class.name

    if user.subscription_settings.key?("/#{notifier_type.downcase}/#{object.id}")
      notification_pref = user.subscription_settings["/#{notifier_type.downcase}/#{object.id}"]
    else 
      notification_pref = user.subscription_settings[channel]
    end

    if notification_pref != 'none'
      subdomain = Thread.current[:subdomain]
      notification = Notification.create!({
        user_id: user.id,
        notifier_id: object.id,
        notifier_type: notifier_type,
        event_type: event_type,
        event_channel: channel,
        sent_email: notification_pref == 'on-site' ? nil : false,
        subdomain_id: subdomain.id
      })
    end
  end




  ################################
  # NOTIFICATION AGGREGATION
  ################################
  # This section of the code relates to helpers for aggregating the Notifications
  # into a data structure that can easily be consumed by notification subsystems.

  def self.aggregate(channels, group_by)
    grouped = {}

    candidates = Notification
      .where(sent_email: false)
      .where("event_channel IN (?)", channels)

    for notification in candidates

      # Don't include notifications that aren't ready, such as a point that
      # hasn't passed moderation yet on a subdomain with strict moderation control
      if notification.root_object.respond_to?(:okay_to_email_notification)
        next if !notification.root_object.okay_to_email_notification
      end

      obj = grouped
      key = nil
      group_by.each_with_index do |group, idx| 
        key = group.call(notification)

        obj[key] ||= idx == group_by.length - 1 ? [] : {}
        obj = obj[key]
      end

      obj.push notification
    end

    grouped

  end

  def self.aggregate_by_proposal
    # Notifications that the Proposal-level digest cares about
    channels = Notifier.subscriptions['proposal'][:channels].keys

    group_by = [ 
      lambda {|notification| notification.user_id },
      lambda {|notification| notification.event_channel },
      lambda {|notification| notification.root_object.respond_to?(:proposal_id) \
                              ? notification.root_object.proposal_id \
                              : notification.root_object.point.proposal_id  },
      lambda {|notification| notification.event_type },
    ]

    Notifier.aggregate(channels, group_by)
  end


  def self.subscriptions
    @@subscriptions
  end

end