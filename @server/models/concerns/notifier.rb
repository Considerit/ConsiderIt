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

    protagonist = hash[:protagonist] || event_object.user

    digest_object = hash[:digest_object] || \
                    Notifier.infer_digest_object(event_object, event_type)

    Notifier.delay.create_notifications_offline(event_type, event_object, 
                                          current_subdomain, protagonist, 
                                          digest_object)
  end

  # An identifier for a channel to which a user can subscribe. This is a 
  # combination of a digest (e.g. proposal) and the relationship a user
  # has with that digest (e.g. authored the proposal)
  def self.subscription_channel(digest_object, user)
    digest = digest_object.class.name.downcase
    relation = Notifier.digest_object_relationship(digest_object, user)
    "#{digest}_#{relation}"
  end

  #####
  # aggregate
  #
  # Aggregates the Notifications into a data structure that can be consumed
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

  def self.aggregate(filter=nil)

    levels = [:subdomain_id, :user_id, 
              :digest_object_type, :digest_object_id, 
              :event, :event_object_relationship]

    aggregation = {}

    candidates = filter ? Notification.where(filter) : Notification.all

    for notification in candidates

      # Don't announce things prematurely...
      if notification.event_object.respond_to?(:okay_to_email_notification) && \
         notification.event_type != 'moderate'
        next if !notification.event_object.okay_to_email_notification
      end

      obj = aggregation
      levels.each_with_index do |level, idx|
        key = notification.send(level)
        key = key.downcase if key.respond_to?(:downcase)

        obj[key] ||= idx == levels.length - 1 ? [] : {}
        obj = obj[key]
      end
      obj.push notification

    end

    aggregation
  end



  #######################################
  # Configuration
  #######################################
  #
  # This is where you come to configure new events, digests, defaults, etc. 
  #
  # I've tried to make the notifications system declarative. This configuration
  # might be a bit complex, but hopefully it is flexible enough to prevent the
  # need to rustle around in the bowels of the notification system. 

  @@proposal_level_notifications = {      

    #############
    # In what ways can a user be related to the proposal?
    'digest_relations' => {

      'authored' => {
        # a proposal author will by default get notified like this
        'default_subscription' => '1_hour',
        # a description of the proposal_authored channel for UI
        'ui_label' => "Proposals I've authored", 
        
        'allowed' => lambda {|user, subdomain| 
                        #permit('create proposal', subdomain) > 0
                        user.is_admin?(subdomain) || \
                        Permitted.matchEmail(subdomain.user_roles['proposer'], user)
                      }
      }, 
      'watched' => {
        'default_subscription' => '1_hour',
        'ui_label' => "Proposals in my watchlist"
      }, 
      'engaged' => {
        'default_subscription' => '1_day',
        'ui_label' => "Proposals in which I’ve participated"
      },
    },

    # ... and how will we know how a particular user is related to a 
    #     particular proposal?
    'digest_relationship_mapper' => lambda {|proposal, user|         
        if proposal.user_id == user.id
          'authored'
        else 
          'engaged'
        end
      },

    ##########

    ########
    # Which system events are grouped into this proposal digest?

    'events' => {

      # for this event, define all of the different relationships that
      # the notified user might have with event object
      'new_comment' => {
        'point_authored' => {
          # a description of this relation for UIs
          'ui_label' => 'Comment on a Pro or Con point you wrote',

          # Whether this event qualifies for triggering an email by default.
          'email_trigger_default' => lambda {|digest_relation| true }
        },
        'point_engaged' => {
          'ui_label' => 'Comment on a Pro or Con point you\'ve engaged',
          'email_trigger_default' => lambda {|digest_relation| true }
        },
        'proposal_interested' => {
          'ui_label' => 'Comment on other points',
          'email_trigger_default' => lambda {|digest_relation| false }
        }
      },

      # TODO: This should only be available for subdomains with 
      #       fact-checking enabled
      # 'new_assessment' => {
      #   'point_authored' => {
      #     # a description of this relation for UIs
      #     'ui_label' => 'Factcheck of a Pro or Con point you wrote',

      #     # Whether this event qualifies for triggering an email by default.
      #     'email_trigger_default' => lambda {|digest_relation| true }
      #   },
      #   'point_engaged' => {
      #     'ui_label' => 'Factcheck of a Pro or Con point you\'ve engaged',
      #     'email_trigger_default' => lambda {|digest_relation| true }
      #   },
      #   'proposal_interested' => {
      #     'ui_label' => 'Factcheck on other points',
      #     'email_trigger_default' => lambda {|digest_relation| false }
      #   }
      # },

      'new_opinion' => {
        'proposal_interested' => {
          'ui_label' => 'New opinion',
          'email_trigger_default' => lambda {|digest_relation| false }
        }
      },

      'new_point' => {
        'proposal_interested' => {
          'ui_label' => 'New Pro or Con point',
          'email_trigger_default' => lambda {|digest_relation| 
            case digest_relation
            when 'authored', 'watched' 
              true
            when 'engaged' 
              false
            else 
              false
            end
          },
        },
      },

    },

    # ... And given a specific system event, find which users are interested
    #     and their particular relationship with the event?
    'event_relationship_mapper' => lambda {|event_type, event_object|
      event = "#{event_type}_#{event_object.class.name.downcase}"
      event_relationships = []

      case event
        when 'new_comment', 'new_assessment'
          point = event_object.point
          proposal = point.proposal
          subdomain = proposal.subdomain

          watchers = Notifier.subscribed_users "/proposal/#{proposal.id}", subdomain
          event_relationships = [{
              'event_object_relationship' => 'point_authored',
              'users' => [point.user_id]
            }, {
              'event_object_relationship' => 'point_engaged',
              'users' =>  point.inclusions.select(:user_id).map {|x| x.user_id } \
                        + point.comments.select(:user_id).map {|x| x.user_id } \
                        + point.requests.select(:user_id).map {|x| x.user_id }
            }, {
              'event_object_relationship' => 'proposal_interested',
              'users' =>   proposal.opinions.published.select(:user_id).map {|x| x.user_id } \
                        + [proposal.user_id] \
                        + watchers.map {|u| u.id}
            },
          ]

        when 'new_point', 'new_opinion'
          proposal = event_object.proposal
          subdomain = proposal.subdomain      

          watchers = Notifier.subscribed_users "/proposal/#{proposal.id}", subdomain
          event_relationships = [{
            'event_object_relationship' => 'proposal_interested',
            'users' =>  proposal.opinions.published.select(:user_id).map {|x| x.user_id } \
                      + [proposal.user_id] \
                      + watchers.map {|u| u.id}           
          }]

        else 
          raise """
            Can't find relationships for #{event_type} 
            #{event_object.class.name} #{event_object.id}"""        
      end

      event_relationships
    },


    ##########


  }

  @@subdomain_level_notifications = {

    #############
    # In what ways can a user be related to the subdomain?
    'digest_relations' => {
        'admin' => {
          'default_subscription' => '1_hour',
          'ui_label' => "The site as a whole", 
          'allowed' => lambda {|user, subdomain| 
                                user.is_admin?(subdomain)}
          }, 
        'moderator' => {
          'default_subscription' => '1_hour',
          'ui_label' => "The site as a whole, like new content to moderate",
          'allowed' => lambda {|user, subdomain| 
                                user.has_role?(:moderator, subdomain)}          
          }, 
        'evaluator' => {
          'default_subscription' => '1_hour',
          'ui_label' => "The site as a whole, like new factcheck requests",
          'allowed' => lambda {|user, subdomain| 
                                user.has_role?(:evaluator, subdomain)}          
          },
        'subdomain_interested' => {
          'default_subscription' => '1_day',
          'ui_label' => "The site as a whole, like new proposals",
          'allowed' => lambda {|user, subdomain| 
                                !user.is_admin?(subdomain) &&
                                  !user.has_any_role?(
                                    [:evaluator, :moderator], subdomain)}
          },
    },

    # ... and how will we know how a particular user is related to a 
    #     particular proposal?
    'digest_relationship_mapper' => lambda {|subdomain, user| 
        if user.is_admin?(subdomain)
          'admin'
        elsif user.has_role?(:evaluator, subdomain)
          'evaluator'
        elsif user.has_role?(:moderator, subdomain)
          'moderator'
        elsif user.proposals.where(:subdomain => subdomain.id).count > 0 || \
              user.opinions.published.where(:subdomain => subdomain.id).count > 0
          'subdomain_interested'
        else
          "none"
        end

      },

    ##########

    ########
    # Which system events are grouped into this proposal digest?

    'events' => {

      'new_proposal' => {
        'subdomain_interested' => {
          'ui_label' => 'New proposal',
          'email_trigger_default' => lambda {|digest_relation| true }
        }
      },

      'moderate' => {
        'moderator' => {
          'ui_label' => 'New content to moderate',
           #   * Returning nil means that this event will not show up as a
           #     preference
          'email_trigger_default' => lambda {|digest_relation| 
                                      case digest_relation
                                      when 'admin', 'moderator' 
                                        true
                                      else 
                                        nil
                                      end
                                     },
        }
      },

      'new_request' => {
        'evaluator' => {
          'ui_label' => 'New factcheck request',
          'email_trigger_default' => lambda {|digest_relation| 
                                      case digest_relation
                                      when 'admin', 'evaluator' 
                                        true
                                      else 
                                        nil
                                      end
                                    },
        },
      },

    },

    # ... And given a specific system event, how do we know which users
    #     may be interested and their particular relationship to the event?
    'event_relationship_mapper' => lambda {|event_type, event_object|
      event = "#{event_type}_#{event_object.class.name.downcase}"
      event_relationships = []
      subdomain = event_object.subdomain

      if event == 'new_proposal'
        event_relationships = [{
            'event_object_relationship' => 'subdomain_interested',
            'users' => subdomain.proposals.map {|p| p.user_id} + \
                        subdomain.opinions.published.map {|o| o.user_id}
          }]

      else
        roles = event_object.subdomain.user_roles

        if event =~ /moderate_/
          users = []
          for email_or_key in roles['moderator']
            if email_or_key =~ /\/user\//
              users.push key_id(email_or_key)
            end
          end
          event_relationships = [{
              'event_object_relationship' => 'moderator',
              'users' => users
            }]

        elsif event == 'new_request'
          users = []
          for email_or_key in roles['evaluator']
            if email_or_key =~ /\/user\//
              users.push key_id(email_or_key)
            end
          end
          event_relationships = [{
              'event_object_relationship' => 'evaluator',
              'users' => users
            }]

        else
          raise """
            Can't find relationships for #{event_type} 
            #{event_object.class.name} #{event_object.id}"""        
        end
      end


      event_relationships
    },
  }

  @@config = {

    # The user can choose how they receive notifications based on these options
    subscription_options: [
      {
        'name' => 'email',
        'ui_label' => 'Email'
      }, {
        'name' => 'on-site',
        'ui_label' => 'On-site message'
      }, {
        'name' => 'none',
        'ui_label' => 'Ignore'
      }],

    # The available subscription levels that notifications aggregate into.
    subscription_digests: {
      'proposal' => @@proposal_level_notifications,
      'subdomain' => @@subdomain_level_notifications
    }
  }



  def self.subscription_config
    @@config
  end  


  #############
  # THE BOWELS
  #
  # Stay out of here unless you've got to extend the notifications system or debug!


  def self.create_notifications_offline(event_type, event_object, subdomain, 
                                        protagonist, digest_object)

    digest_name = digest_object.class.name.downcase
    digest_object_key = "/#{digest_name}/#{digest_object.id}"
    event = "#{event_type}_#{event_object.class.name.downcase}"

    # Build a map of the users who might be interested in this event, and why
    mapper = @@config[:subscription_digests][digest_name]['event_relationship_mapper']
    event_object_relations = mapper.call(event_type, event_object)

    # Remove the event protagonist so that the person who triggered an event 
    # doesn't get notified
    if protagonist
      for relationship in event_object_relations
        relationship['users'].delete protagonist.id
      end
    end

    notified = {}

    for event_object_relation in event_object_relations
      for user_id in event_object_relation['users']
        next if notified[user_id]

        user = User.find(user_id)

        # Does this user _want_ to get notifications for this event??
        channel = subscription_channel digest_object, user
        subscriptions = user.subscription_settings(subdomain)
        method = subscriptions[digest_object_key] || subscriptions[channel]
        next if method == 'none'

        # Finally, let's create that Notification for this user!
        notification = Notification.create!({
          subdomain_id: subdomain.id,
          user_id: user_id,

          digest_object_id: digest_object.id,
          digest_object_type: digest_object.class.name,
          event_object_id: event_object.id,
          event_object_type: event_object.class.name,

          digest_object_relationship: digest_object_relationship(digest_object, user),
          event_object_relationship: event_object_relation['event_object_relationship'],

          event_type: event_type,

          sent_email: method == 'on-site' ? nil : false,
        })

        notified[user_id] = 1 
      end
    end
    
  end

  # Find users who have explicitly subscribed or unsubscribed to this object
  def self.subscribed_users(key, subdomain)
    explicit = subdomain.users.where("subscriptions like '%#{key}%'")
    subscribed = []
    for user in explicit
      subs = user.subscription_settings(subdomain)
      if subs.key?(key) && subs[key] == 'none'
        subscribed.push user
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
      event_object.subdomain
    when 'assessment'
      event_object.point.proposal
    when 'request'
      event_object.assessment.point.subdomain
    else
      raise "Could not infer digest object of type #{event_obj_type}"
    end

  end


  # Determine the relationship between a user and the digest object
  def self.digest_object_relationship(digest_object, user)
    digest_name = digest_object.class.name.downcase
    digest_key = "/#{digest_name}/#{digest_object.id}"

    subdomain = digest_object.class.name == 'Subdomain' ? digest_object : digest_object.subdomain

    subs = user.subscription_settings(subdomain)

    # Allow subscription overrides, like watching a proposal or unsubscribing
    if subs.key?(digest_key)
      return subs[digest_key]  
    end

    mapper = @@config[:subscription_digests][digest_name]['digest_relationship_mapper']
    mapper.call(digest_object, user)

  end



end