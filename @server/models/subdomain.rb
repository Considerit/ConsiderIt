class Subdomain < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :assessments, :dependent => :destroy

  has_attached_file :logo, :processors => [:thumbnail, :compression]
  has_attached_file :masthead, :processors => [:thumbnail, :compression]

  validates_attachment_content_type :masthead, :content_type => %w(image/jpeg image/jpg image/png image/gif)
  validates_attachment_content_type :logo, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :name, :about_page_url, :notifications_sender_email, :app_title, :external_project_url, :assessment_enabled, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode]

  scope :public_fields, -> { select(self.my_public_fields) }

  def users(registered=true)
    qry = User
    if registered
      qry = qry.where(registered: true)
    end

    qry.where("active_in like '%\"#{self.id}\"%'")
  end

  def as_json(options={})
    options[:only] ||= Subdomain.my_public_fields
    json = super(options)
    json['moderated_classes'] = classes_to_moderate().map {|c| c.name}
    json['key'] = '/subdomain'
    if current_user.is_admin?
      json['roles'] = self.user_roles
      json['invitations'] = nil
    else
      json['roles'] = self.user_roles(filter = true)
    end

    json['branding'] = self.branding_info
    json
  end

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end

  # Subdomain-specific info
  # Assembled from a couple image fields and a serialized "branding" field.
  # 
  # This can be a bit annoying during development. Hardcode colors here
  # for different subdomains during development. 
  #
  # The serialized branding object can contain: 
  #   masthead_header_text
  #      This is bolded, white text in the header of the page.
  #   primary_color
  #      Used throughout site. Should be dark.
  #   masthead_background_image
  #      If this is set, the image is applied as a height = 300px background 
  #      image covering the area
  #   logo
  #      A customer's logo. Shown in the footer if set. Isn't sized, just puts in whatever is uploaded. 
  def branding_info
    brands = JSON.parse(self.branding || "{}")

    if !brands.has_key?('primary_color') || brands['primary_color'] == ''
      brands['primary_color'] = '#eee'
    end

    brands['masthead'] = self.masthead_file_name ? self.masthead.url : nil
    brands['logo'] = self.logo_file_name ? self.logo.url : nil

    brands
  end

  # Returns a hash of all the roles. Each role is expressed
  # as a list of (1) user keys, (2) email addresses (for users w/o an account)
  # and (3) email wildcards ('*', '*@consider.it'). 
  # 
  # Setting filter to try returns a roles hash that strips out 
  # all specific email addresses / user keys that are not the
  # current user. 
  #
  # TODO: consolidate with proposal.user_roles
  def user_roles(filter = false)
    result = JSON.parse(roles || "{}")
    ['admin', 'moderator', 'evaluator', 'proposer', 'visitor'].each do |role|

      # default roles if they haven't been set
      default_role = ['visitor', 'proposer'].include?(role) ? ['*'] : []
      result[role] = default_role if !result.has_key?(role) || !result[role]

      # Filter role if the client isn't supposed to see it
      if filter && role != 'proposer'
        # Remove all specific email address for privacy. Leave wildcards.
        # Is used by client permissions system to determining whether 
        # to show action buttons for unauthenticated users. 
        result[role] = result[role].map{|email_or_key|
          email_or_key.index('*') || email_or_key == "/user/#{current_user.id}" ? email_or_key : '-'
        }.uniq
      end
    end

    result
  end

  def title 
    if self.app_title && self.app_title.length > 0
      self.app_title
    else 
      self.name
    end
  end

  def set_roles(new_roles)
    self.roles = JSON.dump(new_roles)
    self.save
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
