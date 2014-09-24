require 'open-uri'
require 'role_model'

class User < ActiveRecord::Base
  include RoleModel

  has_secure_password validations: false
  alias_attribute :password_digest, :encrypted_password

  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :proposals
  has_many :follows, :dependent => :destroy, :class_name => 'Follow'
  has_many :page_views, :dependent => :destroy

  acts_as_tenant :account

  roles :superadmin, :admin, :analyst, :moderator, :manager, :evaluator, :developer


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
    
    current = Rails.cache.read("avatar-digest-#{self.account_id}") || 0
    Rails.cache.write("avatar-digest-#{self.account_id}", current + 1)   
  end

  validates_attachment_content_type :avatar, :content_type => %w(image/jpeg image/jpg image/png image/gif)


  # This will output the data for this user _as if this user is currently logged in_
  # So make sure to only send this data to the client if the client is authorized. 
  def current_user_hash(form_authenticity_token, legacy = false)
    data = {
      id: id, #leave the id in for now for backwards compatability with Dash
      key: '/current_user',
      user: "/user/#{id}",
      logged_in: registration_complete,
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
      tags: JSON.parse(tags),
      is_admin: is_admin?
    }

    # temporary for legacy dashboard:

    if legacy
      data.merge! ({
              :third_party_authenticated => third_party_authenticated, 
              :follows => follows,
              :roles_mask => roles_mask,
              :avatar_file_name => avatar_file_name
            })
    end

    data
    
  end

  def as_json(options={})
    return { 'key' => "/user/#{id}",
             'name' => name,
             'avatar_file_name' => avatar_file_name }
  end

  def logged_in?
    # Logged-in now means that the current user account is registered
    self.registration_complete
  end

  def unsubscribe!
    self.follows.update_all( {:explicit => true, :follow => false} )
  end

  def is_admin?
    has_any_role? :admin, :superadmin
  end

  # def password_digest=(what)
  #     encrypted_password = what
  # end
  # def password_digest
  #   encrypted_password
  # end

  def role_list
    if roles_mask == 0
      return '-'
    else
      roles.map {|role| role.to_s}.join(', ').gsub(':', '')
    end
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

  def self.find_by_third_party_token(access_token)
    case access_token.provider
      when 'twitter'
        user = User.find_by_twitter_uid(access_token.uid)
      when 'facebook'
        user = User.find_by_facebook_uid(access_token.uid) || User.find_by_lower_email(access_token.info.email)
      when 'google_oauth2'
        user = User.find_by_google_uid(access_token.uid) || User.find_by_lower_email(access_token.info.email)
    end

    # If we didn't find a user by the uid, perhaps they already have a user
    # registered by the given email address, but just haven't authenticated 
    # yet by this particular third party. For example, say I register by 
    # email/password with me@gmail.com, but then later I try to authenticate
    # via google oauth. We'll want to match with the existing user and 
    # set the proper google uid. 
    if !user && access_token.info.email
      user = User.find_by_lower_email(access_token.info.email)
      if user
        user["#{access_token.provider}_uid".intern] = access_token.uid
        user.save
      end
    end

    user

  end

  def update_from_third_party_data(access_token)
    params = {
      'name' => access_token.info.name
    }
            
    case access_token.provider

      when 'google_oauth2'
        third_party_params = {
          'google_uid' => access_token.uid,
          'email' => access_token.info.email,
          'avatar_url' => access_token.info.image,
        }        

      when 'facebook'
        third_party_params = {
          'facebook_uid' => access_token.uid,
          'email' => access_token.info.email,
          #'url' => access_token.info.urls.Website ? access_token.info.urls.Website : nil, #TODO: fix this for facebook
          'avatar_url' => 'https://graph.facebook.com/' + access_token.uid + '/picture?type=large'
        }

      when 'twitter'
        third_party_params = {
          'twitter_uid' => access_token.uid,
          'bio' => access_token.info.description,
          'url' => access_token.info.urls.Website ? access_token.info.urls.Website : access_token.info.urls.Twitter,
          # 'twitter_handle' => access_token.info.nickname,
          'avatar_url' => access_token.info.image.gsub('_normal', ''), #'_reasonably_small'),
        }

      else
        raise 'Unsupported provider'
    end

    params.update third_party_params
    params = ActionController::Parameters.new(params).permit!
    self.update_attributes! params

  end

  def key
    "/user/#{self.id}"
  end

  def username
    name ? 
      name
      : email ? 
        email.split('@')[0]
        : "#{account.app_title} participant"
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

  def addTags(new_tags, overwrite_type = false)
    self.tags ||= ''
    existing_tags = getTags()

    if overwrite_type
      types = new_tags.map{|t| t.split(':')[0]}
      existing_tags.delete_if {|t| types.include?(t.split(':')[0])}
    end

    self.tags = (existing_tags | new_tags).join(';')
    self.save
  end

  def getTags
    tags = self.tags ||= ''
    tags.split(';')
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
  #   Account.all.each do |accnt|

  #     accnt.users.each do |user|
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
                  Follow, Moderation, PageView ] 

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
