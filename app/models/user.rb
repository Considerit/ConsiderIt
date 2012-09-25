#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

require 'open-uri'
require 'role_model'

class User < ActiveRecord::Base
  include RoleModel

  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :point_listings, :dependent => :destroy
  has_many :point_similarities, :dependent => :destroy
  #has_many :comments, :dependent => :destroy, :class_name => 'Commentable::Comment'
  has_many :proposals

  belongs_to :domain
  acts_as_tenant(:account)
  is_trackable
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable

  validates :email, :uniqueness => {:scope => :account_id}, :format => Devise.email_regexp, :allow_blank => true

  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :avatar, :registration_complete, :roles_mask

  attr_accessor :avatar_url

  before_validation :download_remote_image, :if => :avatar_url_provided?
  validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'
  after_create :add_token

  roles :superadmin, :admin, :analyst, :moderator, :manager, :evaluator, :developer

  has_attached_file :avatar, 
      :styles => { 
        :medium => "70x70#", 
        :medium_dark => "70x70#",
        :small => "50x50#"
      }

  def send_on_create_confirmation_instructions
    #don't deliver confirmation instructions. We will wait for them to submit a position. 
    #self.devise_mailer.confirmation_instructions(self).deliver
  end

  def is_admin?
    has_any_role? :admin, :superadmin
  end

  def third_party_authenticated?
    self.facebook_uid || self.google_uid || self.yahoo_uid || self.openid_uid || self.twitter_uid
  end

  def avatar_url_provided?
    !self.avatar_url.blank?
  end

  def download_remote_image
    if avatar_url.nil?
     avatar_url = avatar_remote_url
    end
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

  def add_token
    self.unique_token = SecureRandom.hex(10)
    self.save
  end

  def self.add_token
    User.where(:unique_token => nil).each do |u|
      u.unique_token
    end
  end     
      
end
