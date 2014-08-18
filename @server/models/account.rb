class Account < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :page_views, :dependent => :destroy

  #TODO: replace with activity gem 
  has_many :activities, :class_name => 'Activity', :dependent => :destroy

  belongs_to :managing_account, :class_name => 'User'

  include Followable

  before_create :set_default

  #attr_accessible :hibernation_message, :theme, :enable_hibernation, :enable_sharing, :contact_email, :homepage_pic, :app_title, :header_text, :header_details_text, :project_url, :enable_user_conversations, :assessment_enabled, :enable_position_statement, :enable_moderation, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :pro_label, :con_label, :slider_left, :slider_right, :slider_prompt, :requires_civility_pledge_on_registration
  has_attached_file :homepage_pic, 
      :styles => { 
        :large => "x100>",
      },
      :processors => [:thumbnail, :compression]

  validates_attachment_content_type :homepage_pic, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :theme, :identifier, :hibernation_message, :enable_hibernation, :enable_sharing, :contact_email, :homepage_pic_remote_url, :homepage_pic_file_name, :app_title, :header_text, :header_details_text, :project_url, :enable_user_conversations, :assessment_enabled, :enable_position_statement, :enable_moderation, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :pro_label, :con_label, :slider_left, :slider_right, :slider_prompt, :requires_civility_pledge_on_registration]

  scope :public_fields, -> { select(self.my_public_fields) }

  def as_json(options={})
    options[:only] ||= Account.my_public_fields
    json = super(options)
    json['key'] = 'customer'
    json
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

  def classes_to_moderate

    classes = []

    if enable_moderation && moderate_points_mode > 0
      classes << Point
    end
    if enable_moderation && moderate_comments_mode > 0
      classes << Comment
    end
    if enable_moderation && moderate_proposals_mode > 0
      classes << Proposal
    end

    classes

  end

end
