class Subdomain < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :logs

  has_attached_file :logo, :processors => [:thumbnail, :compression]
  has_attached_file :masthead, :processors => [:thumbnail, :compression]

  validates_attachment_content_type :masthead, :content_type => %w(image/jpeg image/jpg image/png image/gif)
  validates_attachment_content_type :logo, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :lang, :name, :created_at, :about_page_url, :external_project_url, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :host_with_port, :plan, :SSO_domain]

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


    if current_user.super_admin
      shared = File.read("@client/customizations_helpers.coffee")
      json['shared_code'] = shared
    end

    json['customizations'] = JSON.pretty_generate(self.customization_json)
    json
  end

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end

  def rename(new_name)
    existing = Subdomain.where(:name => new_name).first
    if existing
      raise "Sorry, #{new_name}.consider.it is already taken"
    end

    self.host = self.host.gsub(self.name, new_name)
    self.host_with_port = self.host_with_port.gsub(self.name, new_name)
    self.name = new_name
    self.save
  end

  def customization_json
    config = Oj.load (self.customizations || "{}")

    if self.logo_file_name
      config['banner'] ||= {}
      config['banner']['logo'] ||= {}
      config['banner']['logo']['url'] = self.logo.url
    end 

    if self.masthead_file_name
      config['banner'] ||= {}
      config['banner']['background_image_url'] = self.masthead.url
    end 

    config

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
    ['admin', 'moderator', 'proposer', 'visitor'].each do |role|

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
    self.name
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
