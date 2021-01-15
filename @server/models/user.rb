require 'open-uri'
require 'onelogin/ruby-saml'

class User < ApplicationRecord
  has_secure_password validations: false
  alias_attribute :password_digest, :encrypted_password

  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :proposals
  has_many :notifications, :dependent => :destroy

  attr_accessor :avatar_url, :downloaded

  before_validation :download_remote_image, :if => :avatar_url_provided?
  before_save do 
    self.email = self.email.downcase if self.email

    self.name = sanitize_helper self.name if self.name   
    self.bio = sanitize_helper self.bio if self.bio
  end

  after_create :add_token

  has_attached_file :avatar, 
      :styles => { 
        :large => "250x250#",
        :small => "50x50#"
      },
      :processors => [:thumbnail]

  # process_in_background :avatar

  after_post_process do 
    if self.avatar.queued_for_write[:small]

      img_data = self.avatar.queued_for_write[:small].read

      self.avatar.queued_for_write[:small].rewind
      data = Base64.encode64(img_data)
      b64_thumbnail = "data:image/jpeg;base64,#{data.gsub(/\n/,' ')}"

      begin        
        qry = "UPDATE users SET b64_thumbnail='#{b64_thumbnail}' WHERE id=#{self.id}"
        ActiveRecord::Base.connection.execute(qry)
      rescue => e
        raise "Could not store image for user #{self.id}, it is too large!"
      end

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
      lang: lang,
      reset_password_token: nil,
      b64_thumbnail: b64_thumbnail,
      tags: tags || {},
      is_super_admin: self.super_admin,
      is_admin: is_admin?,
      is_moderator: permit('moderate content', nil) > 0,
      trying_to: nil,
      subscriptions: subscription_settings(current_subdomain),
      #notifications: notifications.order('created_at desc'),
      verified: verified,
      needs_to_complete_profile: self.registered && (self.complete_profile || !self.name),
                                #happens for users that were created via email invitation
      needs_to_verify: ['bitcoin', 'bitcoinclassic', 'bch'].include?(current_subdomain.name) && \
                               self.registered && !self.verified,
      completed_host_questions: has_answered_all_required_host_questions
    }

    data
    
  end

  def has_answered_all_required_host_questions(subdomain=nil)
    has_filled_required_fields = true
    customizations = (subdomain or current_subdomain).customization_json
    user_tags = customizations.fetch("user_tags", {})
    my_tags = self.tags || {}
    user_tags.each do |tag, vals|
      if vals.has_key?('self_report') && vals['self_report'].fetch('required', false) && !(['boolean', 'checklist'].index(vals['self_report']['input']))
        has_filled_required_fields = has_filled_required_fields && !!my_tags.fetch(tag, false)
      end
    end 
    has_filled_required_fields
  end

  # Gets all of the users active for this subdomain
  def self.all_for_subdomain
    fields = "CONCAT('\/user\/',id) as 'key',users.name,users.avatar_file_name,users.tags"
    if current_user.is_admin?
      fields += ",email"
    end
    users = ActiveRecord::Base.connection.exec_query( "SELECT #{fields} FROM users WHERE registered=1 AND active_in like '%\"#{current_subdomain.id}\"%'")

    anonymize_everything = current_subdomain.customization_json['anonymize_everything']

    tags_config = current_subdomain.customization_json.fetch('user_tags', {})
    users.each do |u| 
      u_tags = Oj.load(u['tags']||'{}')
      u['tags'] = {}
      tags_config.each do |tag, vals|
        if u_tags.has_key?(tag) && (current_user.is_admin? || vals.fetch('visibility', 'host-only') == 'open')
          u['tags'][tag] = u_tags[tag]
        end
      end

      if current_user.key != u['key'] && anonymize_everything
        u['name'] = 'Anonymous'
        u['avatar_file_name'] = nil
      end 
    end 
    
    {key: '/users', users: users.as_json}
  end

  def as_json(options={})
    data = {  
      'key' => "/user/#{id}",
      'name' => name,
      'avatar_file_name' => avatar_file_name
    }

    customizations = current_subdomain.customization_json
    anonymize_everything = customizations['anonymize_everything']
    if anonymize_everything
      data['name'] = 'Anonymous'
      data['avatar_file_name'] = nil
    end 

    if current_user.is_admin?
      data['email'] = email
    end

    tags_config = customizations.fetch('user_tags', {})
    tags = tags || {}
    data['tags'] = {}
    tags_config.each do |tag, vals|
      if tags.has_key?(tag) && (current_user.is_admin? || vals.fetch('visibility', 'host-only') == 'open')
        data['tags'][tag] = tags[tag]
      end
    end

    data
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
      roles = subdomain.roles ? subdomain.roles : {}
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
    subdomain ||= current_subdomain
    
    if !self.active_in 
      self.active_in = []
      self.save
    end 

    if !self.active_in.include?("#{subdomain.id}")
      self.active_in.push "#{subdomain.id}"
      self.save
      return "added"
    end
  end

  def self.fix_active_in
    ActsAsTenant.without_tenant do
      Subdomain.all.each do |subdomain|
        users = {}
        subdomain.opinions.published.each do |o|
          users[o.user_id] = o.user
        end
        subdomain.comments.each do |o|
          users[o.user_id] = o.user
        end
        subdomain.points.published.each do |o|
          users[o.user_id] = o.user
        end
        subdomain.proposals.each do |o|
          users[o.user_id] = o.user
        end       
        users.each do |k,u|
          if u 
            r = u.add_to_active_in(subdomain) 
            if r == 'added'
              begin
                raise "Had to add #{u.id} #{u.name} to active_in for #{subdomain.id} #{subdomain.name} resulting in #{u.active_in}"
              rescue => error
                ExceptionNotifier.notify_exception(error,
                        :data => {:message => "Had to add #{u.id} #{u.name} to active_in for #{subdomain.id} #{subdomain.name} resulting in #{u.active_in}"})            
              end
            end
          end
        end
      end
    end
  end

  def emails_received
    self.emails || {}
  end

  def sent_email_about(key, time=nil)
    time ||= Time.now().to_s
    settings = emails_received
    settings[key] = time
    self.emails = settings
    self.save
  end


  # Notification preferences. 
  def subscription_settings(subdomain)

    notifier_config = Notifier::config(subdomain)

    my_subs = (subscriptions || {})[subdomain.id.to_s] || {}

    for event, config in notifier_config
      if config.key? 'allowed'
        next if !config['allowed'].call(self, subdomain)
      end
      
      if my_subs.key?(event)
        my_subs[event].merge! config
      else 
        my_subs[event] = config
      end

      if !my_subs[event].key?('email_trigger')
        my_subs[event]['email_trigger'] = my_subs[event]['email_trigger_default']
      end

    end

    my_subs['default_subscription'] = Notifier.default_subscription
    if !my_subs.key?('send_emails')
      my_subs['send_emails'] = my_subs['default_subscription']
    end

    my_subs
  end


  def update_subscription_key(key, value, hash={})
    if hash.has_key?(:subdomain)
      subdomain = hash[:subdomain]
    else 
      subdomain = current_subdomain
    end

    sub_settings = subscription_settings(subdomain)
    return if !hash[:force] && sub_settings.key?(key)

    sub_settings[key] = value
    self.subscriptions = update_subscriptions(sub_settings)
    save
  end

  def update_subscriptions(new_settings, subdomain = nil)
    subdomain ||= current_subdomain

    subs = subscriptions || {}

    notifier_config = Notifier::config(subdomain)

    settings_for_subdomain = {}
    new_settings.each do |k, v|
      if notifier_config.has_key?(k)
        if v.has_key?('email_trigger') && notifier_config[k]['email_trigger_default'] != v['email_trigger']
          settings_for_subdomain[k] = {
            "email_trigger" => v['email_trigger']
          }
        end
      elsif k == 'default_subscription'
        if k == 'send_emails' && Notifier.default_subscription != v
          settings_for_subdomain[k] = v 
        end
      elsif k != 'default_subscription' 
        settings_for_subdomain[k] = v
      end

    end

    subs[subdomain.id.to_s] = settings_for_subdomain

    subs
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
        : "#{current_subdomain.name} participant"
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


  def auth_token(subdomain = nil)
    subdomain ||= current_subdomain
    ApplicationController.MD5_hexdigest("#{self.email}#{self.unique_token}#{subdomain.name}")
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

  def avatar_link(img_type='small')
    if self.avatar_file_name
      "#{Rails.application.config.action_controller.asset_host || ''}/system/avatars/#{self.id}/#{img_type}/#{self.avatar_file_name}"
    else 
      nil 
    end
  end

  # Check to see if this user has been referenced by email in any 
  # roles or permissions settings. If so, replace the email with the
  # user's key. 
  def update_roles_and_permissions
    ActsAsTenant.without_tenant do 
      for cls in [Subdomain, Proposal]
        objs_with_user_in_role = cls.where("roles like '%\"#{self.email}\"%'") 
                                         # this is case insensitive

        for obj in objs_with_user_in_role
          for role, users in obj.roles 
            if users.include?(self.email)  
              pp "UPDATING ROLES, replacing #{self.email} with #{self.id} for #{obj.name}"
              users.delete self.email
              users.append "/user/#{self.id}"
            end
          end 
          obj.save 
        end
      end
    end
  end


  def absorb (user)
    return if not (self and user)

    older_user = self.id #user that will do the absorbing
    newer_user = user.id #user that will be absorbed

    # puts("Merging!  Kill User #{newer_user}, put into User #{older_user}")

    return if older_user == newer_user
    
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
    new_ops = Opinion.where(:user_id => newer_user)
    old_ops = Opinion.where(:user_id => older_user)
    # puts("Merging opinions from #{old_ops.map{|o| o.id}} to #{new_ops.map{|o| o.id}}")

    for new_op in new_ops

      # we only need to absorb this user if they've dragged the slider 
      # or included a point
      # ATTENTION!! This will delete someone's opinion if they vote exactly neutral and 
      #             didn't include any points (and they're logging in)
      if new_op.stance == 0 && (new_op.point_inclusions || []).length == 0
        new_op.destroy
        next 
      end

      # puts("Looking for opinion to absorb into #{new_op.id}...")
      old_op = Opinion.where(:user_id => older_user,
                             :proposal_id => new_op.proposal.id).first

      if old_op
        # puts("Found opinion to absorb into #{new_op.id}: #{old_op.id}")
        # Merge the two opinions. We'll absorb the old opinion into the new one!
        # Update new_ops' user_id to the old user. 
        new_op.absorb(old_op, true)
      else
        # if this is the first time this user is saving an opinion for this proposal
        # we'll just change the user id of the opinion, seeing as there isn't any
        # opinion to absorb into
        new_op.user_id = older_user
        new_op.save
        dirty_key("/opinion/#{new_op.id}")
      end
      
    end

    # 2. Change user_id columns over in bulk
    # TRAVIS: Opinion & Inclusion is taken care of when absorbing an Opinion

    # Bulk updates...
    for table in [Point, Proposal, Comment] 

      # First, remember what we're dirtying
      table.where(:user_id => newer_user).each{|x| dirty_key("/#{table.name.downcase}/#{x.id}")}
      table.where(:user_id => newer_user).update_all(user_id: older_user)
    end

    # log table, which doesn't use user_id
    Log.where(:who => newer_user).update_all(who: older_user)

    subs = (self.active_in || []).concat(user.active_in || []).uniq
    self.active_in = subs
    save 

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
