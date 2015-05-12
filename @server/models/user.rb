require 'open-uri'

class User < ActiveRecord::Base
  has_secure_password validations: false
  alias_attribute :password_digest, :encrypted_password

  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :proposals
  has_many :follows, :dependent => :destroy, :class_name => 'Follow'
  has_many :notifications, :dependent => :destroy

  attr_accessor :avatar_url, :downloaded

  before_validation :download_remote_image, :if => :avatar_url_provided?
  before_save do 
    self.email = self.email.downcase if self.email

    self.name = self.name.sanitize if self.name   
    self.bio = self.bio.sanitize if self.bio
  end

  #validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'
  after_create :add_token

  has_attached_file :avatar, 
      :styles => { 
        :large => "250x250#",
        :small => "50x50#"
      },
      :processors => [:thumbnail, :compression]

  process_in_background :avatar

  after_post_process do 
    img_data = self.avatar.queued_for_write[:small].read
    self.avatar.queued_for_write[:small].rewind
    data = Base64.encode64(img_data)
    self.b64_thumbnail = "data:image/jpeg;base64,#{data.gsub(/\n/,' ')}"
    
    JSON.parse(self.active_in).each do |subdomain_id|
      Rails.cache.delete("avatar-digest-#{subdomain_id}") 
    end
  end

  validates_attachment_content_type :avatar, :content_type => %w(image/jpeg image/jpg image/png image/gif)


  # This will output the data for this user _as if this user is currently logged in_
  # So make sure to only send this data to the client if the client is authorized. 
  def current_user_hash(form_authenticity_token)
    data = {
      id: id, #leave the id in for now for backwards compatability with Dash
      key: '/current_user',
      user: "/user/#{id}",
      logged_in: registered,
      email: email,
      password: nil,
      csrf: form_authenticity_token,
      avatar_remote_url: avatar_remote_url,
      url: url,
      name: name,
      reset_password_token: nil,
      b64_thumbnail: b64_thumbnail,
      tags: JSON.parse(tags || '{}'),
      is_super_admin: self.super_admin,
      is_admin: is_admin?,
      is_moderator: permit('moderate content', nil) > 0,
      is_evaluator: permit('factcheck content', nil) > 0,
      trying_to: nil,
      subscriptions: subscription_settings(current_subdomain),
      notifications: Notification.where(:user_id => self.id),      
      verified: verified,
      needs_to_set_password: registered && !name #happens for users that were created via email invitation
    }

    data
    
  end

  # Gets all of the users active for this subdomain
  def self.all_for_subdomain
    fields = "CONCAT('\/user\/',id) as 'key',users.name,users.avatar_file_name,users.groups"
    if current_user.is_admin?
      fields += ",email"
    end
    users = ActiveRecord::Base.connection.exec_query( "SELECT #{fields} FROM users WHERE registered=1 AND active_in like '%\"#{current_subdomain.id}\"%'")
    users.each{|u| u['groups']=JSON.parse(u['groups']||'[]')}

    {key: '/users', users: users.as_json}
  end

  # Note: This is barely used in practice, because most users are
  # generated by the all_for_subdomain() method above.
  def as_json(options={})
    result = { 'key' => "/user/#{id}",
               'name' => name,
               'avatar_file_name' => avatar_file_name,
               'tags' => JSON.parse(tags || '{}')  }
                  # TODO: filter private tags
    if current_user.is_admin?
      result['email'] = email
    end
    result
  end

  def is_admin?(subdomain = nil)
    subdomain ||= current_subdomain
    has_any_role? [:admin, :superadmin], subdomain
  end

  def has_role?(role, subdomain = nil)
    role = role.to_s

    if role == 'superadmin'
      return self.super_admin
    else
      subdomain ||= current_subdomain
      roles = subdomain.roles ? JSON.parse(subdomain.roles) : {}
      return roles.key?(role) && roles[role] && roles[role].include?("/user/#{id}")
    end
  end

  def has_any_role?(roles, subdomain = nil)
    subdomain ||= current_subdomain
    for role in roles
      return true if has_role?(role, subdomain)
    end
    return false
  end

  def logged_in?
    # Logged-in now means that the current user account is registered
    self.registered
  end

  def add_to_active_in(subdomain=nil)
    if !subdomain 
      subdomain = current_subdomain
    end
    
    active_subdomains = JSON.parse(self.active_in) || []

    if !active_subdomains.include?("#{subdomain.id}")
      active_subdomains.push "#{subdomain.id}"
      self.active_in = JSON.dump active_subdomains
      self.save

      # if we're logging in to a subdomain that we didn't originally register, we'll have to 
      # regenerate the avatars file. Note that there is still a bug where the avatar won't be there 
      # on initial login to the new subdomain.
      if self.avatar_file_name && active_subdomains.length > 1
        subdomain_id = subdomain.id
        Rails.cache.delete("avatar-digest-#{subdomain_id}")
      end
    end

  end

  def emails_received
    JSON.parse(self.emails || "{}")
  end

  def sent_email_about(key, time=nil)
    time ||= Time.now().to_s
    settings = emails_received
    emails_received[key] = time
    self.emails = JSON.dump emails_received
    save
  end


  ####
  # subscription_settings
  #
  # Which channels this user subscribes. e.g. comments on points I've written.
  # Outputs a hash with the following levels: 
  #   - subdomain_id
  #     - digest
  #      - digest relation
  #        . default
  #        . description
  #        . ui_label
  #        - events
  #          - event_type
  #            . true or false
  #
  # If you pass a subdomain, it will just return the settings for that subdomain
  #
  def subscription_settings(constrain_to_subdomain = nil)

    my_subs = JSON.parse(subscriptions || "{}")
    notifier_config = Notifier::subscription_config

    if constrain_to_subdomain 
      subdomains = [constrain_to_subdomain.id.to_s]
    else
      subdomains = JSON.load(self.active_in || '[]')
      subdomains.push current_subdomain.id.to_s if current_subdomain
      subdomains.uniq!
    end

    # Make sure the default subscription settings defined in Notifier
    # are present for this user.     
    for subdomain_id in subdomains
      subdomain = Subdomain.find_by id: subdomain_id
      next if !subdomain

      my_subs[subdomain_id] ||= {}

      for digest, digest_config in notifier_config[:subscription_digests]
        my_subs[subdomain_id][digest] ||= {}
        my_digest_config = my_subs[subdomain_id][digest] 
        
        for digest_relation, relation_config in digest_config['digest_relations']
          
          if !relation_config['allowed'] || relation_config['allowed'].call(self, subdomain)
            my_digest_config[digest_relation] ||= {}
            my_relation_config = my_digest_config[digest_relation]

            my_relation_config['ui_label'] = relation_config['ui_label']
            my_relation_config['default_subscription'] = relation_config['default_subscription']
            my_relation_config['subscription'] ||= relation_config['default_subscription']
          
            my_relation_config['events'] ||= {}
            for event, event_config in digest_config['events']
              my_relation_config['events'][event] ||= {}
              my_event_config = my_relation_config['events'][event]
              for event_relation, event_relation_config in event_config
                default_trigger = event_relation_config['email_trigger_default'].call(digest_relation)
                if default_trigger != nil
                  my_event_config[event_relation] ||= {}
                  my_event_relation_config = my_event_config[event_relation]
                  my_event_relation_config['default_email_trigger'] = default_trigger
                  if !my_event_relation_config.key?('email_trigger')
                    my_event_relation_config['email_trigger'] = default_trigger
                  end
                  my_event_relation_config['ui_label'] = event_relation_config['ui_label']
                end
              end
            end
          end
        end
      end
    end


    if constrain_to_subdomain
      my_subs = my_subs[constrain_to_subdomain.id.to_s]
    end

    my_subs['subscription_options'] = notifier_config[:subscription_options]

    my_subs
  end

  def update_subscriptions(new_settings, subdomain = nil)
    subdomain ||= current_subdomain

    subs = self.subscription_settings
    subs[subdomain.id.to_s] = new_settings

    # Strip out unnecessary items that we can reconstruct from the 
    # notification configuration 
    clean = proc do |k, v|        

      if v.respond_to?(:key?)
        if v.key?('default_subscription') && 
            v['default_subscription'] == v['subscription']
          v.delete('subscription')
        elsif v.key?('default_email_trigger') && 
            v['default_email_trigger'] == v['email_trigger']
          v.delete('email_trigger')
        end

        v.delete_if(&clean) # recurse if v is a hash
      end

      v.respond_to?(:key) && v.keys().length == 0 || \
      ['subscription_options', 'ui_label', \
       'default_subscription', 'default_email_trigger'].include?(k)

    end

    subs.delete_if &clean

    JSON.dump subs
  end

  # get all the items this user gets notifications for
  # TODO: update for new system!
  def notifications

    followable_objects = {
      'Proposal' => {},
      'Point' => {}
    }

    for followable_type in followable_objects.keys

      if followable_type == 'Point'
        following = self.inclusions.map {|i| "/point/#{i.point_id}"} + \
                 self.comments.map {|c| "/point/#{c.point_id}" } 
      elsif followable_type == 'Proposal'
        following = self.opinions.published.map {|o| "/proposal/#{o.proposal_id}"}
      end

      following += self.follows.where(:follow => true, :followable_type => followable_type, :subdomain_id => current_subdomain.id).map {|f| "/#{f.followable_type.downcase}/#{f.followable_id}" }

      followable_objects[followable_type] = following.uniq.compact #remove dupes and nils

      # remove objs that have been explicitly unfollowed already
      self.follows.where(:follow => false, :followable_type => followable_type).each do |f|
        followable_objects[f.followable_type].delete("/#{f.followable_type.downcase}/#{f.followable_id}")
      end

    end

    followable_objects
  end

  def avatar_url_provided?
    !self.avatar_url.blank?
  end

  def download_remote_image
    if self.downloaded.nil?
      self.downloaded = true
      self.avatar_url = self.avatar_remote_url if avatar_url.nil?
      io = open(URI.parse(self.avatar_url))
      def io.original_filename; base_uri.path.split('/').last; end

      self.avatar = io if !(io.original_filename.blank?)
      self.avatar_remote_url = avatar_url
      self.avatar_url = nil
    end

  end


  def key
    "/user/#{self.id}"
  end

  def username
    name ? 
      name
      : email ? 
        email.split('@')[0]
        : "#{current_subdomain.app_title or current_subdomain.name} participant"
  end
  
  def first_name
    username.split(' ')[0]
  end

  def short_name
    split = username.split(' ')
    if split.length > 1
      return "#{split[0][0]}. #{split[-1]}"
    end
    return split[0]  
  end


  def add_token
    self.unique_token = SecureRandom.hex(10)
    self.save
  end

  def self.add_token
    User.where(:unique_token => nil).each do |u|
      u.unique_token
    end
  end


  def absorb (user)
    return if not (self and user)

    dest_user = self.id #user that will do the absorbing
    source_user = user.id #user that will be absorbed

    puts("Merging!  Kill User #{source_user}, put into User #{dest_user}")

    return if dest_user == source_user
    
    dirty_key("/current_user") # in case absorb gets called outside 
                               # of CurrentUserController

    # Not only do we need to merge the user objects, but we'll need to
    # merge their opinion objects too.

    # To do this, we take the following steps
    #  1. Merge both users' opinions
    #  2. Change user_id for every object that has one to the new user_id
    #  3. Delete the old user

    # 1. Merge opinions
    #    ASSUMPTION: The Opinion of the user being absorbed is _newer_ than 
    #                the Opinion of the user doing the absorbtion. 
    #                This is currently TRUE for considerit. 
    #    TODO: Reconsider this assumption. Should we use Opinion.updated_at to 
    #          decide which is the new one and which is the old, and consequently 
    #          which gets absorbed into the other?
    new_ops = Opinion.where(:user_id => source_user)
    old_ops = Opinion.where(:user_id => dest_user)
    puts("Merging opinions from #{old_ops.map{|o| o.id}} to #{new_ops.map{|o| o.id}}")

    for new_op in new_ops
      puts("Looking for opinion to absorb into #{new_op.id}...")
      old_op = Opinion.where(:user_id => dest_user,
                             :proposal_id => new_op.proposal.id).first

      if old_op
        puts("Found opinion to absorb into #{new_op.id}: #{old_op.id}")
        # Merge the two opinions. We'll absorb the old opinion into the new one!
        # Update new_ops' user_id to the old user. 
        new_op.absorb(old_op, true)
      else
        # if this is the first time this user is saving an opinion for this proposal
        # we'll just change the user id of the opinion, seeing as there isn't any
        # opinion to absorb into
        new_op.user_id = dest_user
        new_op.save
        dirty_key("/opinion/#{new_op.id}")
      end
      
    end

    # 2. Change user_id columns over in bulk
    # TRAVIS: Opinion & Inclusion is taken care of when absorbing an Opinion

    # Follow can't be updated in bulk because it can result in duplicates of what should be a unique 
    # (user, followable) constraint. So we'll first handle any duplicates. Then the rest can be bulk updated. 
    self.follows.each do |my_follow|
      new_follow = user.follows.where(:followable_type => my_follow.followable_type, :followable_id => my_follow.followable_id)
      if new_follow.count > 0
        f = new_follow.last
        if f.explicit || !my_follow.explicit
          my_follow.follow = f.follow
          my_follow.explicit = f.explicit
          my_follow.save 
        end
        new_follow.destroy_all
      end
    end

    # Bulk updates...
    for table in [Point, Proposal, Comment, Assessment, Assessable::Request, \
                  Follow, Moderation ] 

      # First, remember what we're dirtying
      table.where(:user_id => source_user).each{|x| dirty_key("/#{table.name.downcase}/#{x.id}")}
      table.where(:user_id => source_user).update_all(user_id: dest_user)
    end

    # log table, which doesn't use user_id
    Log.where(:who => source_user).update_all(who: dest_user)

    # 3. Delete the old user
    # TODO: Enable this once we're confident everything is working.
    #       I see that this is being done in CurrentUserController#replace_user. 
    #       Where should it live? 
    # user.destroy()

  end

  def self.purge
    users = User.all.map {|u| u.id}
    missing_users = []
    classes = [Opinion, Point, Inclusion]
    classes.each do |cls|
      cls.where("user_id IS NOT NULL AND user_id NOT IN (?)", users ).each do |r|
        missing_users.push r.user_id
      end
    end
    classes.each do |cls|
      cls.where("user_id in (?)", missing_users.uniq).delete_all
    end

  end
   

end
