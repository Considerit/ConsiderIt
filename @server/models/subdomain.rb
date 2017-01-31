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
  self.my_public_fields = [:id, :lang, :name, :created_at, :about_page_url, :notifications_sender_email, :app_title, :external_project_url, :assessment_enabled, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :host_with_port, :plan, :SSO_domain]

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
    json['key'] = !options[:include_id] ? '/subdomain' : "/subdomain/#{self.id}"
    if current_user.is_admin?
      json['roles'] = self.user_roles
      json['invitations'] = nil
      json['google_analytics_code'] = self.google_analytics_code
    else
      json['roles'] = self.user_roles(filter = true)
    end

    json['branding'] = self.branding_info

    if self.customizations || current_user.super_admin
      shared = File.read("@client/customizations_helpers.coffee")
      if current_user.super_admin
        json['shared_code'] = shared
      end 
    end

    if self.customizations 
      str = self.customizations.gsub('"', '\\"').gsub('$', '\\$')
      if current_user.super_admin
        json['customizations'] = self.customizations
      end 
      json['customization_obj'] = %x(echo "#{shared.gsub '"', '\\"'}\nwindow.customization_obj={\n#{str}\n}" | coffee -scb)
    end 
    
    json
  end

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end

  def rename(new_name)
    existing = Subdomain.where(:name => new_name)
    if existing
      raise "Sorry, #{new_name}.consider.it is already taken"
    end
    
    self.host = self.host.gsub(self.name, new_name)
    self.host_with_port = self.host_with_port.gsub(self.name, new_name)
    self.name = new_name
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
  #   description
  #      HTML description of the site, displayed in the default headers
  def branding_info
    brands = Oj.load(self.branding || "{}")

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
    result = Oj.load(roles || "{}")
    ['admin', 'moderator', 'evaluator', 'proposer', 'visitor'].each do |role|

      # default roles if they haven't been set
      default_role = ['visitor', 'proposer'].include?(role) ? ['*'] : []
      result[role] = default_role if !result.has_key?(role) || !result[role]

      # Filter role if the client isn't supposed to see it
      if filter # && role != 'proposer'
        # Remove all specific email address for privacy. Leave wildcards.
        # Is used by client permissions system to determining whether 
        # to show action buttons for unauthenticated users. 
        result[role] = result[role].map{|email_or_key|
          email_or_key.index('*') || email_or_key.match("/user/") ? email_or_key : '-'
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
