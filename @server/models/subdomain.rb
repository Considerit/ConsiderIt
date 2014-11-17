class Subdomain < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  # has_attached_file :homepage_pic, 
  #     :styles => { 
  #       :large => "x100>",
  #     },
  #     :processors => [:thumbnail, :compression]

  # validates_attachment_content_type :homepage_pic, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :name, :about_page_url, :notifications_sender_email, :app_title, :external_project_url, :assessment_enabled, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :has_civility_pledge]

  scope :public_fields, -> { select(self.my_public_fields) }

  def as_json(options={})
    options[:only] ||= Subdomain.my_public_fields
    json = super(options)
    json['moderated_classes'] = classes_to_moderate().map {|c| c.name}
    json['key'] = '/subdomain'
    if current_user.is_admin?
      json['roles'] = self.user_roles
    end
    json
  end

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end

  def user_roles
    r = JSON.parse(roles || "{}")
    ['admin', 'moderator', 'evaluator'].each do |role|
      if !r.has_key?(role) || !r[role]
        r[role] = []
      end
    end
    r
  end

  def set_roles(new_roles)
    self.roles = JSON.dump(new_roles)
    self.save
  end

  def self.all_themes
    Dir['app/assets/themes/*/'].map { |a| File.basename(a) }
  end

  def classes_to_moderate

    classes = []

    if moderate_points_mode > 0
      classes << Point
    end
    if moderate_comments_mode > 0
      classes << Comment
    end
    if moderate_proposals_mode > 0
      classes << Proposal
    end

    classes

  end

end
