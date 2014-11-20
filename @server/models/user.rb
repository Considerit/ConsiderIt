require 'open-uri'
#require 'role_model'

class User < ActiveRecord::Base
  has_secure_password validations: false
  alias_attribute :password_digest, :encrypted_password

  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :proposals
  has_many :follows, :dependent => :destroy, :class_name => 'Follow'

  attr_accessor :avatar_url, :downloaded

  before_validation :download_remote_image, :if => :avatar_url_provided?
  before_save do 
    self.email.downcase! if self.email

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
      current = Rails.cache.read("avatar-digest-#{subdomain_id}") || 0
      Rails.cache.write("avatar-digest-#{subdomain_id}", current + 1)   
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
      bio: bio,
      twitter_uid: twitter_uid,
      facebook_uid: facebook_uid,
      google_uid: google_uid,
      name: name,
      reset_my_password: false,
      reset_password_token: nil,
      b64_thumbnail: b64_thumbnail,
      tags: JSON.parse(tags) || {},
      is_super_admin: self.super_admin,
      is_admin: is_admin?,
      is_moderator: has_any_role?([:admin, :superadmin, :moderator]),
      is_evaluator: has_any_role?([:admin, :superadmin, :evaluator]),
      trying_to: nil,
      no_email_notifications: no_email_notifications
    }

    data
    
  end

  # Gets all of the users active for this subdomain
  def self.all_for_subdomain
    current_subdomain = Thread.current[:subdomain]
    fields = "CONCAT('\/user\/',id) as 'key',users.name,users.avatar_file_name"
    if current_user.is_admin?
      fields += ",email"
    end
    users = ActiveRecord::Base.connection.select( "SELECT #{fields} FROM users WHERE registered=1 AND active_in like '%\"#{current_subdomain.id}\"%'")
    users = users.as_json
    jsonify_objects(users, 'user')

    {key: '/users', users: users}

  end

  def as_json(options={})
    return { 'key' => "/user/#{id}",
             'name' => name,
             'avatar_file_name' => avatar_file_name }
  end

  def is_admin?
    has_any_role? [:admin, :superadmin]
  end

  def has_role?(role)
    role = role.to_s

    if role == 'superadmin'
      return self.super_admin
    else
      roles = Thread.current[:subdomain].roles ? JSON.parse(Thread.current[:subdomain].roles) : {}
      return roles.has_key?(role) && roles[role] && roles[role].include?("/user/#{id}")
    end
  end

  def has_any_role?(roles)
    roles.each do |role|
      return true if has_role?(role)
    end
    return false
  end

  def logged_in?
    # Logged-in now means that the current user account is registered
    self.registered
  end

  def add_to_active_in
    current_subdomain = Thread.current[:subdomain]
    active_subdomains = JSON.parse(self.active_in) || []

    if !active_subdomains.include?("#{current_subdomain.id}")
      active_subdomains.push "#{current_subdomain.id}"
      self.active_in = JSON.dump active_subdomains
      self.save

      # if we're logging in to a subdomain that we didn't originally register, we'll have to 
      # regenerate the avatars file. Note that there is still a bug where the avatar won't be there 
      # on initial login to the new subdomain.
      if self.avatar_file_name && active_subdomains.length > 1
        subdomain_id = Thread.current[:subdomain].id
        current = Rails.cache.read("avatar-digest-#{subdomain_id}") || 0
        Rails.cache.write("avatar-digest-#{subdomain_id}", current + 1)   
      end
    end

  end

  # get all the items this user gets notifications for
  def notifications
    current_subdomain = Thread.current[:subdomain]

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


  def third_party_authenticated
    if !!self.facebook_uid
      'Facebook' 
    elsif !!self.google_uid
      'Google'
    elsif !!self.twitter_uid
      'Twitter'
    else
      nil
    end
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

  def self.find_by_lower_email(email)
    if email       
      find_by_email email.downcase
    else
      nil
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
        : "#{subdomain.app_title} participant"
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

  # def update_metrics
  #   referenced_proposals = {}
  #   opinions = 0

  #   self.opinions.published.each do |opinion|
  #     if !referenced_proposals.has_key?(opinion.proposal_id)
  #       proposal = Proposal.find(opinion.proposal_id) 
  #       #if can?(:read, proposal)  
  #       referenced_proposals[opinion.proposal_id] = proposal
  #       opinions += 1          
  #     end
  #   end

  #   influenced_users = {}
  #   accessible_points = []

  #   my_points = self.points.published.where(:hide_name => false)
  #   my_points.each do |pnt|
  #     accessible_points.push pnt.id
  #     pnt.inclusions.where("user_id != #{self.id}").each do |inc|
  #       influenced_users[inc.user_id] = 0 if ! influenced_users.has_key?(inc.user_id)
  #       influenced_users[inc.user_id] +=1
  #     end
  #   end

  #   attrs = {
  #     :metric_points => my_points.count,
  #     :metric_opinions => opinions,
  #     :metric_comments => self.comments.count,
  #     :metric_influence => influenced_users.keys().count, 
  #     :metric_conversations => self.proposals.open_to_public.count }

  #   if self.name.blank?
  #     attrs[:name] = 'Not Specified'
  #   end

  #   values_changed = false
  #   attrs.keys.each do |key|
  #     if self[key] != attrs[key]
  #       values_changed = true
  #       break
  #     end
  #   end
  #   self.update_attributes!(ActionController::Parameters.new(attrs).permit!) if values_changed

  # end

  # def self.update_user_metrics
  #   Account.all.each do |subdomain|

  #     subdomain.users.each do |user|
  #       begin
  #         user.update_metrics()
  #       rescue
  #         pp "Could not update User #{user.id}"
  #       end
  #     end
  #   end
  # end

  def absorb (user)
    return if not (self and user)

    dest_user = self.id #user that will do the absorbing
    source_user = user.id #user that will be absorbed

    puts("Merging!  Kill User #{source_user}, put into User #{dest_user}")

    return if dest_user == source_user
    
    remap_key("/user/#{source_user}", "/user/#{dest_user}")
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
    for table in [Point, Proposal, Comment, Assessable::Assessment, Assessable::Request, \
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
