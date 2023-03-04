class Subdomain < ApplicationRecord
  belongs_to :user, :foreign_key => 'created_by', :class_name => 'User'
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :moderations, :dependent => :destroy

  has_many :visits, class_name: 'Ahoy::Visit', :dependent => :destroy  
  has_many :events, class_name: 'Ahoy::Event', :dependent => :destroy  

  has_many :logs

  has_attached_file :logo, :processors => [:thumbnail]
  has_attached_file :masthead, :processors => [:thumbnail]

  validates_attachment_content_type :masthead, :content_type => ["image/jpg", "image/jpeg", "image/pjpeg", "image/png","image/x-png", "image/gif", "image/webp"], message: "Only jpeg, png, gif, and webp images types are allowed"
  validates_attachment_content_type :logo, :content_type => ["image/jpg", "image/jpeg", "image/pjpeg", "image/png","image/x-png", "image/gif", "image/webp"], message: "Only jpeg, png, gif, and webp images types are allowed"

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :lang, :name, :created_at, :about_page_url, :external_project_url, :moderation_policy, :plan, :SSO_domain]

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
    json['key'] = !options[:include_id] ? '/subdomain' : "/subdomain/#{self.id}"
    if current_user.is_admin?
      json['roles'] = self.user_roles
      json['invitations'] = nil
    else
      json['roles'] = self.user_roles(filter = true)
    end


    if current_user.super_admin
      shared = File.read("@client/customizations_helpers.coffee")
      json['shared_code'] = shared
    end

    json['host'] = considerit_host
    json['customizations'] = self.customization_json
    json
  end

  def url
    self.custom_url || considerit_url
  end

  def considerit_host
    "#{self.name}.#{APP_CONFIG[:domain]}"
  end


  def import_configuration(copy_from_subdomain)
    customizations = copy_from_subdomain.customizations.clone
    if customizations.has_key?('user_tags')
      if self.plan == 0 || self.plan == nil
        customizations.delete 'user_tags'
        if customizations.has_key?('host_questions_framing')
          customizations.delete('host_questions_framing')
        end
      else 
        # don't reuse tags between forums because it can create incoherent data
        # when one forum changes the options and/or labels
        customizations['user_tags'] = customizations['user_tags'].clone
        customizations['user_tags'].each do |tag|
          if tag['key'].start_with?("#{copy_from_subdomain.name}-")
            tag['key'] = tag['key'].sub "#{copy_from_subdomain.name}-", "#{self.name}-"
          end
        end
      end
    end

    self.customizations = customizations
    self.roles = copy_from_subdomain.roles
    self.masthead = copy_from_subdomain.masthead
    self.logo = copy_from_subdomain.logo
    self.lang = copy_from_subdomain.lang
    self.SSO_domain = copy_from_subdomain.SSO_domain
    self.moderation_policy = copy_from_subdomain.moderation_policy
    self.save
  end

  def rename(new_name)
    existing = Subdomain.where(:name => new_name).first
    if existing
      raise "Sorry, #{new_name}.#{APP_CONFIG[:domain]} is already taken"
    end

    self.name = new_name
    self.save
  end

  def customization_json
    begin
      config = self.customizations || {}
    rescue => e
      config = {}
      ExceptionNotifier.notify_exception e
    end 

    config['banner'] ||= {}
    config['banner']['logo'] ||= {}

    if self.logo_file_name
      config['banner']['logo']['url'] = self.logo.url
    elsif config['banner']['logo'].has_key?('url')
      config['banner']['logo']['url'] = nil
    end 

    if self.masthead_file_name
      config['banner']['background_image_url'] = self.masthead.url
    elsif config['banner'].has_key?('background_image_url')
      config['banner'].delete('background_image_url')
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
    rolez = roles ? roles.deep_dup : {}
    ['admin', 'proposer', 'visitor', 'participant'].each do |role|

      # default roles if they haven't been set
      default_role = ['visitor', 'proposer', 'participant'].include?(role) ? ['*'] : []
      rolez[role] = default_role if !rolez.has_key?(role) || !rolez[role]

      # Filter role if the client isn't supposed to see it
      if filter
        # Remove all specific email address for privacy. Leave wildcards.
        # Is used by client permissions system to determining whether 
        # to show action buttons for unauthenticated users. 
        rolez[role] = rolez[role].map{|email_or_key|
          email_or_key.index('*') || email_or_key.match("/user/") ? email_or_key : '-'
        }.uniq
      end
    end

    rolez
  end

  def title 
    self.name
  end

  def classes_to_moderate
    if moderation_policy > 0
      [Proposal, Point, Comment]
    else
      []
    end

  end



end
