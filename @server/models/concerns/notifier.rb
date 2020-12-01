######################################################
# Notifier is the core of the Notifications system.
#
# Include Notifier in any model that will generate notifications. 
#
# Notifier is also responsible for: 
#    - Notification system configuration, including: 
#         - subscription channels
#         - events
#         - defaults
#
#    - Handling Notification creation when a relevant system event occurs
#
#    - Aggregating Notifications into a data structure to be consumed by a
#      Notifications subsystem. (e.g. email notifications or on-site messages)
#

require Rails.root.join('@server', 'permissions')


DEBUG = false

module Notifier
  extend ActiveSupport::Concern

  included do 
    has_many :notifications, :as => :event_object, 
             :class_name => 'Notification', :dependent => :destroy
  end


  #######################################
  # Notifier API
  #######################################

  #####
  # create_notification
  #
  # Called when there is an event that should produce notifications. 
  #
  # event_object:   The subject of the event
  # event_type:     An identifier for the event that occurred to the object, 
  #                 like 'new' or 'delete'
  # protagonist:    The user whose action triggered this event. This user will
  #                 not be notified of the event. The protagonist defaults to 
  #                 the user set on the event object. But this isn't always
  #                 correct, such as if an administrator closes a proposal that
  #                 another user authored. 
  # digest_object:  The object with which this event will aggregated. For example
  #                 new points are aggregated at the Proposal level. 
  #                 digest_object will be inferred by default; override by arg
  #                 if you're confident in what you're doing. 

  def self.create_notification(event_type, event_object, hash = {})
    if !event_object.respond_to?(:notifications)
      pp "WARNING: Model #{event_object.class.name} does not include Notifier"
    end

    subdomain = hash[:subdomain] || current_subdomain
    protagonist = hash[:protagonist] || event_object.user

    digest_object = hash[:digest_object] || \
                    Notifier.infer_digest_object(event_object, event_type)

    caller = DEBUG ? Notifier : Notifier.delay
    caller.create_notifications_offline(event_type, 
                                        event_object.class.name, event_object.id, 
                                        subdomain.id, protagonist.id, 
                                        digest_object.class.name, digest_object.id)
  end

  #####
  # aggregate
  #
  # Organizes the Notifications into a data structure that can be consumed
  # by notification subsystems. 
  # 
  # The aggregation is a deeply nested hash. In order:
  #   - subdomain_id
  #   - user_id
  #   - digest_object_type
  #   - digest_object_id
  #   - event_type
  #   - event_object_relationship
  #
  # Accepts an optional filter hash, such as {read: false} or {sent_email: false}. 
  #
  # Makes sure to filter out Notifications that shouldn't be announced just yet, 
  # such as unmoderated objects on a subdomain with strict moderation control.
  #
  # This could probably be refactored as a group_by query.


  def self.aggregate(options={})

    levels = [:subdomain_id, :user_id, 
              :digest_object_type, :digest_object_id, 
              :event]

    aggregation = {}

    candidates = options[:filter] ? Notification.where(options[:filter]) : Notification.all

    candidates = Notifier.filter_no_longer_existing(candidates)

    if !options[:skip_moderation_filter]
      candidates = Notifier.filter_unmoderated(candidates)
    end

    for notification in candidates
      obj = aggregation
      levels.each_with_index do |level, idx|
        key = notification.send(level)

        obj[key] ||= idx == levels.length - 1 ? [] : {}
        obj = obj[key]
      end
      obj.push notification

    end

    aggregation
  end

  def self.filter_no_longer_existing(notifications)
    exists = {}

    notifications.select {|n|
      event_key = "#{n.event_object_type}/#{n.event_object_id}"
      digest_key = "#{n.digest_object_type}/#{n.digest_object_id}"

      if !exists.key?(event_key) 
        begin 
          exists[event_key] = !!n.event_object
        rescue 
          exists[event_key] = false 
        end
      end 

      if !exists.key?(digest_key)
        begin 
          exists[digest_key] = !!n.digest_object 
        rescue 
          exists[digest_key] = false 
        end
      end  

      exists[event_key] && exists[digest_key]
    }

  end 

  def self.filter_unmoderated(notifications)
    event_objs = {}

    notifications.select {|n|
      event_key = "#{n.event_object_type}/#{n.event_object_id}"
      if !event_objs.key?(event_key)
        event_objs[event_key] = n.event_object
      end
      event_object = event_objs[event_key]
      !event_object.respond_to?(:okay_to_email_notification) || n.event_type == 'content_to_moderate' || event_object.okay_to_email_notification
    }
  end


  #######################################
  # Configuration
  #
  # This is where you come to configure new events, digests, defaults, etc. 

  def self.default_subscription(subdomain)
    if ['galacticfederation', 'ainaalohafutures'].include?(subdomain.name)
      nil
    else 
      '1_day'
    end
  end

  def self.config(subdomain)

    {

      'new_proposal' => {
        'ui_label' => 'If someone adds a new proposal',
        'email_trigger_default' => subdomain.name != 'consider'
        
      },

      'content_to_moderate' => {
        'ui_label' => 'When there is new content to help moderate',
         #   * Returning nil means that this event will not show up as a
         #     preference
        'email_trigger_default' => true,
        'allowed' => lambda {|user, subdomain| user.has_any_role?([:admin, :moderator], subdomain)}
        },


      # for this event, define all of the different relationships that
      # the notified user might have with event object
      'new_comment:point_authored' => {
        # a description of this relation for UIs
        'ui_label' => 'Someone comments on a Pro or Con point you wrote',

        # Whether this event qualifies for triggering an email by default.
        'email_trigger_default' => true
      },

      'new_comment:point_engaged' => {
        'ui_label' => 'Comments on a Pro or Con point you\'ve engaged',
        'email_trigger_default' => true
      },

      'new_comment' => {
        'ui_label' => 'A comment on any Pro or Con point of a proposal you watch',
        'email_trigger_default' => false
      },

      'new_opinion' => {
        'ui_label' => 'New opinions on a proposal you watch',
        'email_trigger_default' => false
      },

      'edited_proposal' => {
        'ui_label' => nil,
        'email_trigger_default' => true
      },

      'new_point' => {
        'ui_label' => 'New Pro or Con point on a watched proposal',
        'email_trigger_default' => true
      },

    }

  end

  # ... And how is a user related to a specific event?
  def self.event_relationship_mapper(event_object, user)

    if event_object.class.name == 'Comment'
      point = event_object.point
      if point.user_id == user.id
        'point_authored'
      elsif  (point.inclusions.select(:user_id).map {|x| x.user_id } \
            + point.comments.select(:user_id).map {|x| x.user_id }).include?(user.id)
        'point_engaged'
      else 
        'watched'
      end
    else
      'watched'
    end
  end


  #############
  # THE BOWELS
  #
  # Stay out of here unless you've got to extend the notifications system or debug!


  def self.create_notifications_offline(event_type, event_object_type, event_object_id, subdomain_id, 
                                        protagonist_id, digest_object_type, digest_object_id)

    begin
      subdomain = Subdomain.find(subdomain_id)
      event_object = event_object_type.constantize.find(event_object_id)
      digest_object = digest_object_type.constantize.find(digest_object_id)
    rescue ActiveRecord::RecordNotFound
      # one of the objects has disappeared during the delay of creating a notification
      return 
    end

    # Who is watching this object?
    if event_type == 'content_to_moderate'
      watchers = User.where("id in (?)", subdomain.user_roles['admin'].map {|key| key_id(key)})
    elsif event_object_type == 'Proposal' && event_type == 'new'
      watchers = subdomain.users.where(registered: true)
    else
      watchers = Notifier.subscribed_users(digest_object)
    end

    for user in watchers

      # Remove the event protagonist so that the person who triggered an event 
      # doesn't get notified
      next if user.id == protagonist_id

      # only create notifications for permitted users (relevant if the forum permissions have changed)
      next if permit("access forum", subdomain, user) < 0 

      event_object_relationship = Notifier.event_relationship_mapper(event_object, user)

      method = user.subscription_settings(subdomain)['send_emails']

      # Finally, let's create that Notification for this user!
      notification = Notification.create!({
        subdomain_id: subdomain.id,
        user_id: user.id,

        digest_object_id: digest_object.id,
        digest_object_type: digest_object.class.name,

        event_object_id: event_object.id,        
        event_object_type: event_object.class.name,

        event_object_relationship: event_object_relationship,
        event_type: event_type,

        sent_email: method == nil ? nil : false,
      })

    end
  end

  # Find users who are watching this object
  def self.subscribed_users(object)
    
    case object.class.name
      when 'Subdomain'
        subdomain = object
      when 'Proposal'
        subdomain = object.subdomain        
      else 
        raise "Can't find users subscribed to #{object.class.name}"
    end

    key = "/#{object.class.name.downcase}/#{object.id}"
    subdomain.users.where(registered: true).where("subscriptions like '%\"#{key}\":\"watched\"%'")
    
  end

  # Tries to infer the digest object from the event_object
  def self.infer_digest_object(event_object, event_type)
    case event_object.class.name.downcase
    when 'comment'
      event_object.point.proposal
    when 'point', 'opinion'
      event_object.proposal
    when 'proposal'
      if event_type == 'edited'
        event_object
      else
        event_object.subdomain
      end
    else
      raise "Could not infer digest object of type #{event_obj_type}"
    end

  end


end