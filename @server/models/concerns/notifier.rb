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

require Rails.root.join('@server', 'extras', 'permissions')


DEBUG = Rails.env.development?

module Notifier
  extend ActiveSupport::Concern


  #######################################
  # Configuration
  #
  # This is where you come to configure new events, digests, defaults, etc. 

  def self.default_subscription
    '1_day'
  end

  def self.config(subdomain)

    {
      'new_proposal' => {
        'email_trigger_default' => true
      },

      'content_to_moderate' => {
        'email_trigger_default' => true
      },

      'new_comment:point_authored' => {
        'email_trigger_default' => true
      },

      'new_comment:point_engaged' => {
        'email_trigger_default' => true
      },

      'new_comment' => {
        'email_trigger_default' => false
      },

      'new_opinion' => {
        'email_trigger_default' => false
      },

      'new_opinion:proposal_authored' => {
        'email_trigger_default' => true
      },

      'edited_proposal' => {
        'email_trigger_default' => true
      },

      'new_point' => {
        'email_trigger_default' => true
      },

      'new_point:proposal_authored' => {
        'email_trigger_default' => true
      }

    }

  end

  # ... And how is a user related to a specific event?
  def self.event_relationship_mapper(event_object, user)

    if event_object.class.name == 'Point'
      proposal = event_object.proposal
      if proposal.user_id == user.id
        'proposal_authored'
      else 
        'watched'
      end

    elsif event_object.class.name == 'Comment'
      point = event_object.point
      if point.user_id == user.id
        'point_authored'
      elsif  (point.inclusions.select(:user_id).map {|x| x.user_id } \
            + point.comments.select(:user_id).map {|x| x.user_id }).include?(user.id)
        'point_engaged'
      else 
        'watched'
      end
    elsif event_object.class.name == 'Opinion'
      proposal = event_object.proposal 
      if proposal.user_id == user.id
        'proposal_authored'
      else 
        'watched'
      end
    else
      'watched'
    end
  end


  def self.notify_parties(event_type, event_object, digest_object = nil)
    digest_object ||= Notifier.infer_digest_object(event_object, event_type)
    subdomain = current_subdomain
    protagonist = event_object.user
    caller = DEBUG ? Notifier : Notifier.delay
    caller.notify_parties_offline(event_type, 
                                  event_object.class.name, event_object.id, 
                                  subdomain.id, protagonist.id, 
                                  digest_object.class.name, digest_object.id)
  end


  def self.notify_parties_offline(event_type, event_object_type, event_object_id, subdomain_id, 
                                  protagonist_id, digest_object_type, digest_object_id)

    begin
      subdomain = Subdomain.find(subdomain_id)
      subdomain.digest_triggered_for ||= {}
      event_object = event_object_type.constantize.find(event_object_id)
      digest_object = digest_object_type.constantize.find(digest_object_id)
    rescue ActiveRecord::RecordNotFound
      # one of the objects has disappeared during the delay of creating a notification
      return 
    end

    # Don't notify yet if this needs to be moderated
    return if event_type != 'content_to_moderate' && event_object.respond_to?(:okay_to_email_notification) && !event_object.okay_to_email_notification

    # Who is watching this object?
    if event_type == 'content_to_moderate'
      watchers = User.where("id in (?)", subdomain.user_roles['admin'].map {|key| key_id(key)})
    elsif event_object_type == 'Proposal' && event_type == 'new'
      watchers = subdomain.users.where(registered: true)
    else
      watchers = Notifier.subscribed_users(digest_object)
    end

    for user in watchers

      # User is already marked for getting a digest
      next if subdomain.digest_triggered_for.fetch(user.id, false)

      # Remove the event protagonist so that the person who triggered an event 
      # doesn't get notified
      next if user.id == protagonist_id

      # only create notifications for permitted users (relevant if the forum permissions have changed)
      next if permit("access forum", subdomain, user) < 0 

      settings = user.subscription_settings(subdomain)

      # don't trigger if they're not receiving email notifications
      next if settings['send_emails'] == nil 

      # don't trigger if they've said this event doesn't trigger them
      next if !Notifier.valid_triggering_event(user, event_type, event_object, settings)

      subdomain.digest_triggered_for[user.id] = true

    end
    subdomain.save

  end

  def self.valid_triggering_event(user, event_type, event_object, subscription_settings)
    event_relation = Notifier.event_relationship_mapper(event_object, user)

    if event_type != 'content_to_moderate'
      event_type = "#{event_type.downcase}_#{event_object.class.name.downcase}"
    end

    if subscription_settings.key? "#{event_type}:#{event_relation}"
      key = "#{event_type}:#{event_relation}"
    else 
      key = event_type
    end

    if !subscription_settings[key]
      pp "missing event prefs for #{key}", subscription_settings
      raise "missing event prefs for #{key}"
    end

    subscription_settings[key] && subscription_settings[key]['email_trigger']

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

    subscribed = []
    subdomain.users.where(registered: true).where('subscriptions is not null').each do |user|
      if user.subscriptions.fetch("#{subdomain.id}", {}).fetch(key, false) == 'watched'
        subscribed.append user
      end
    end

    subscribed
    
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