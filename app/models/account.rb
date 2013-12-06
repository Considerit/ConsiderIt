class Account < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :page_views, :dependent => :destroy

  #TODO: replace with activity gem 
  has_many :activities, :class_name => 'Activity', :dependent => :destroy

  belongs_to :managing_account, :class_name => 'User'

  is_followable

  before_create :set_default

  attr_accessible :homepage_pic, :app_title, :header_text, :header_details_text, :project_url, :enable_user_conversations, :assessment_enabled, :enable_position_statement, :enable_moderation, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :pro_label, :con_label, :slider_left, :slider_right, :slider_prompt
  has_attached_file :homepage_pic, 
      :styles => { 
        :large => "x100>",
      },
      :processors => [:thumbnail, :paperclip_optimizer]



  def num_proposals_per_page 
    5
  end

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end


  def self.all_themes
    Dir['app/assets/themes/*/'].map { |a| File.basename(a) }
  end

  def set_default
    header_text ||= 'The main callout to participants'
    header_details_text ||= 'This is where you\'ll add more details about why this forum exists, and whom you want to participate.'
  end
end
