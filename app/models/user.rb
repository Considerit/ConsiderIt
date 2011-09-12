require 'open-uri'

class User < ActiveRecord::Base
  has_many :points
  has_many :positions
  has_many :inclusions
  has_many :point_listings
  has_many :point_similarities
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
         
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :avatar
  
  attr_accessor :avatar_url
  before_validation :download_remote_image, :if => :avatar_url_provided?
  validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'

  has_attached_file :avatar, 
      :default_url => "/images/:attachment/:style_default-profile-pic.png",   
      :styles => { :large => "200x200#", :normal => "100x100#", :midsmall => "70x70#", :small => "50x50#", :thumb => "35x35#"}
      #:path => ":rails_root/public/images/:attachment/uploaded/:id/:style_:basename.:extension",
      #:url => "/images/:attachment/uploaded/:id/:style_:basename.:extension"

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
    pp access_token
    case access_token['provider']
      when 'twitter'
        user = User.find_by_twitter_uid(access_token['uid'])
      else
        user = User.find_by_email(access_token['user_info']['email'])
    end

    if not user
      user = User.new do |u|
        u.password = Devise.friendly_token[0,20]
                
        case access_token['provider']
          when 'google'
            u.name = access_token['user_info']['name']
            u.google_uid = access_token['uid']
            u.email = access_token['user_info']['email']          
          when 'yahoo'
            u.name = access_token['user_info']['name']
            u.yahoo_uid = access_token['uid']
            u.email = access_token['user_info']['email']          
          when 'twitter'
            u.name = access_token['user_info']['name']
            u.twitter_uid = access_token['uid']
            u.bio = access_token['user_info']['description']
            u.url = access_token['user_info']['urls']['Website'] ? access_token['user_info']['urls']['Website'] : access_token['user_info']['urls']['Twitter']
            u.twitter_handle = access_token['user_info']['nickname']

            u.avatar_url = access_token['user_info']['image']

          when 'facebook'
            u.name = access_token['user_info']['name']
            u.email = access_token['user_info']['email']
            u.facebook_uid = access_token['uid']
            u.url = access_token['user_info']['urls']['Website'] ? access_token['user_info']['urls']['Website'] : access_token['user_info']['urls']['Twitter']
            u.avatar_url = 'http://graph.facebook.com/' + access_token['uid'] + '/picture?type=large'
          else
            raise 'Not a supported provider'
        end
      end
      user.save
    end

    user
  end

  protected

  def email_required? 
    twitter_uid.nil?
  end   
  
      
end
