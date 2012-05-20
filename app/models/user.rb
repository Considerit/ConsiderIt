require 'open-uri'

class User < ActiveRecord::Base
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :point_listings, :dependent => :destroy
  has_many :point_similarities, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :point_links, :dependent => :destroy
  has_many :proposals

  belongs_to :domain
  acts_as_tenant(:account)
  is_trackable
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable


  validates :email, :uniqueness => {:scope => :account_id}, :format => Devise.email_regexp, :allow_blank => true

  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :avatar, :registration_complete

  attr_accessor :avatar_url
  before_validation :download_remote_image, :if => :avatar_url_provided?
  validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'

  has_attached_file :avatar, 
      :default_url => "#{ENV['RAILS_RELATIVE_URL_ROOT'] || ''}/assets/:attachment/:style_default-profile-pic.png",
      :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
      :url => "/system/:attachment/:id/:style/:filename",   
      :styles => { 
        #:golden_horizontal => "100x62#", 
        #:golden_vertical => "62x100#", 
        :medium => "70x70#", 
        :medium_dark => "70x70#",
        :small => "50x50#"
      }

  def is_admin?
    #TODO: scope this based on current_tenant
    return admin
  end
  def third_party_authenticated?
    self.facebook_uid || self.google_uid || self.yahoo_uid || self.openid_uid || self.twitter_uid
  end

  def avatar_url_provided?
    !self.avatar_url.blank?
  end

  def download_remote_image
    io = open(URI.parse(avatar_url))
    def io.original_filename; base_uri.path.split('/').last; end
    self.avatar = io.original_filename.blank? ? nil : io
    self.avatar_remote_url = avatar_url
  end

  def self.find_for_third_party_auth(access_token, signed_in_resource=nil)
    case access_token.provider
      when 'twitter'
        user = User.find_by_twitter_uid(access_token.uid)
      else
        user = User.find_by_email(access_token.info.email)
    end

    if not user
      user = User.new do |u|
        u.password = Devise.friendly_token[0,20]
                
        case access_token.provider
          when 'google'
            u.name = access_token.info.name
            u.google_uid = access_token.uid
            u.email = access_token.info.email
          when 'yahoo'
            u.name = access_token.info.name
            u.yahoo_uid = access_token.uid
            u.email = access_token.info.email
          when 'twitter'
            u.name = access_token.info.name
            u.twitter_uid = access_token.uid
            u.bio = access_token.info.description
            u.url = access_token.info.urls.Website ? access_token.info.urls.Website : access_token.info.urls.Twitter
            u.twitter_handle = access_token.info.nickname
            u.avatar_url = access_token.info.image
          when 'facebook'
            u.name = access_token.info.name
            u.email = access_token.info.email
            u.facebook_uid = access_token.uid
            u.url = access_token.info.urls.Website ? access_token.info.urls.Website : access_token.info.urls.Twitter
            u.avatar_url = 'http://graph.facebook.com/' + access_token.uid + '/picture?type=large'
          else
            raise 'Unsupported provider'
        end
      end
      user.skip_confirmation!
      user.save
      user.track!
    end

    user
  end

  def email_required? 
    twitter_uid.nil?
  end   
  
  def first_name
    name.split(' ')[0]  
  end

  def short_name
    split = name.split(' ')
    if split.length > 1
      return "#{split[0][0]}. #{split[-1]}"
    end
    return split[0]  
  end
      
end
