require 'open-uri'
require 'role_model'

class User < ActiveRecord::Base
  include RoleModel

  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :point_listings, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :proposals
  has_many :follows, :dependent => :destroy, :class_name => 'Followable::Follow'
  has_many :page_views, :dependent => :destroy

  acts_as_tenant(:account)
  is_trackable

  #devise :omniauthable, :omniauth_providers => [:facebook, :twitter, :google_oauth2]
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable
  devise :omniauthable, :omniauth_providers => [:facebook, :twitter, :google_oauth2]

  validates :name, :presence => true
  validates :email, :uniqueness => {:scope => :account_id}, :format => Devise.email_regexp, :allow_blank => true

  #attr_accessible :name, :bio, :email, :password, :password_confirmation, :remember_me, :avatar, :registration_complete, :roles_mask, :url, :google_uid, :twitter_uid, :twitter_handle, :facebook_uid, :referer, :avatar_url, :metric_points, :metric_conversations, :metric_positions, :metric_comments, :metric_influence, :b64_thumbnail

  attr_accessor :avatar_url, :downloaded

  before_validation :download_remote_image, :if => :avatar_url_provided?
  before_save do 
    self.email.downcase! if self.email

    self.name = Sanitize.clean(self.name) if self.name   
    self.bio = Sanitize.clean(self.bio, Sanitize::Config::RELAXED) if self.bio
    if self.avatar_file_name_changed?
      img_data = self.avatar.queued_for_write[:small].read
      self.avatar.queued_for_write[:small].rewind
      data = Base64.encode64(img_data)

      thumbnail = "data:image/jpeg;base64,#{data.gsub(/\n/,' ')}"
      self.b64_thumbnail = thumbnail

    end

  end


  #validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'
  after_create :add_token

  roles :superadmin, :admin, :analyst, :moderator, :manager, :evaluator, :developer

  has_attached_file :avatar, 
      :styles => { 
        :large => "250x250#",
        :small => "50x50#"
      },
      :processors => [:thumbnail, :paperclip_optimizer]


  def unsubscribe!
    self.follows.update_all( {:explicit => true, :follow => false} )
  end

  def send_on_create_confirmation_instructions
    #don't deliver confirmation instructions. We will wait for them to submit a position. 
    #self.devise_mailer.confirmation_instructions(self).deliver
  end

  def is_admin?
    has_any_role? :admin, :superadmin
  end

  def role_list
    if roles_mask == 0
      return '-'
    else
      lst = []
      roles.each do |role|
        lst.push(role.to_s)
      end
      lst.join(', ').gsub(':', '')
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
    find_by_email email.downcase
  end

  def self.find_by_third_party_token(access_token)
    case access_token.provider
      when 'twitter'
        user = User.find_by_twitter_uid(access_token.uid)
      when 'facebook'
        user = User.find_by_facebook_uid(access_token.uid) || User.find_by_lower_email(access_token.info.email)
        if user
          user.facebook_uid = access_token.uid
        end
      when 'google'
        user = User.find_by_google_uid(access_token.uid) || User.find_by_lower_email(access_token.info.email)
        if user
          user.google_uid = access_token.uid
        end

      when 'google_oauth2'
        user = User.find_by_google_uid(access_token.uid) || User.find_by_lower_email(access_token.info.email)  #for_google_oauth2(request.env["omniauth.auth"], current_user)

        if user
          user.google_uid = access_token.uid
        end

      else  
        user = User.find_by_lower_email(access_token.info.email)
    end

    user

  end

  def self.create_from_third_party_token(access_token)
    params = {
      'name' => access_token.info.name,
      'password' => Devise.friendly_token[0,20]
    }
            
    case access_token.provider
      when 'google'
        third_party_params = {
          'google_uid' => access_token.uid,
          'email' => access_token.info.email
        }

      when 'google_oauth2'
        third_party_params = {
          'google_uid' => access_token.uid,
          'email' => access_token.info.email,
          'avatar_url' => access_token.info.image
        }        

      when 'twitter'
        third_party_params = {
          'twitter_uid' => access_token.uid,
          'bio' => access_token.info.description,
          'url' => access_token.info.urls.Website ? access_token.info.urls.Website : access_token.info.urls.Twitter,
          'twitter_handle' => access_token.info.nickname,
          'avatar_url' => access_token.info.image.gsub('_normal', '') #'_reasonably_small'),
        }

      when 'facebook'
        third_party_params = {
          'facebook_uid' => access_token.uid,
          'email' => access_token.info.email,
          'url' => access_token.info.urls.Website ? access_token.info.urls.Website : access_token.info.urls.Twitter, #TODO: fix this for facebook
          'avatar_url' => 'http://graph.facebook.com/' + access_token.uid + '/picture?type=large'
        }

      else
        raise 'Unsupported provider'
    end
    params.update third_party_params

  end

  def email_required? 
    twitter_uid.nil?
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

  def last_name
    username.split(' ').last
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

  def update_metrics
    referenced_proposals = {}
    positions = 0

    self.positions.published.each do |position|
      if !referenced_proposals.has_key?(position.proposal_id)
        proposal = Proposal.find(position.proposal_id) 
        #if can?(:read, proposal)  
        referenced_proposals[position.proposal_id] = proposal
        positions += 1          
      end
    end

    influenced_users = {}
    accessible_points = []

    my_points = self.points.published.where(:hide_name => false)
    my_points.each do |pnt|
      accessible_points.push pnt.id
      pnt.inclusions.where("user_id != #{self.id}").each do |inc|
        influenced_users[inc.user_id] = 0 if ! influenced_users.has_key?(inc.user_id)
        influenced_users[inc.user_id] +=1
      end
    end

    attrs = {
      :metric_points => my_points.count,
      :metric_positions => positions,
      :metric_comments => self.comments.count,
      :metric_influence => influenced_users.keys().count, 
      :metric_conversations => self.proposals.open_to_public.count }

    if self.name.blank?
      attrs[:name] = 'Not Specified'
    end

    values_changed = false
    attrs.keys.each do |key|
      if self[key] != attrs[key]
        values_changed = true
        break
      end
    end
    self.update_attributes!(ActionController::Parameters.new(attrs).permit!) if values_changed

  end

  def self.update_user_metrics
    Account.all.each do |accnt|

      accnt.users.each do |user|
        user.update_metrics()
      end
    end
  end

  def self.purge
    users = User.all.map {|u| u.id}
    missing_users = []
    classes = [Position, Point, PointListing, Inclusion]
    classes.each do |cls|
      cls.where("user_id IS NOT NULL AND user_id NOT IN (?)", users ).each do |r|
        missing_users.push r.user_id
      end
    end
    classes.each do |cls|
      cls.where("user_id in (?)", missing_users.uniq).delete_all
    end

    pp missing_users.uniq
  end
      
end
