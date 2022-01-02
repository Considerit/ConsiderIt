# coding: utf-8

class Proposal < ApplicationRecord
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy

  has_attached_file :pic, 
    :processors => [:thumbnail],
    :styles => { 
        :square => "250x250#"
    }

  validates_attachment_content_type :pic, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  has_attached_file :banner, :processors => [:thumbnail]
  validates_attachment_content_type :banner, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  belongs_to :user

  acts_as_tenant :subdomain

  include Moderatable, Notifier
  
  class_attribute :my_public_fields
  self.my_public_fields = [:id, :slug, :cluster, :user_id, :created_at, :updated_at, :name, :description, :active, :hide_on_homepage, :published, :subdomain_id, :json]

  scope :active, -> {where( :active => true, :published => true )}

  before_validation :strip_html
  before_save :set_slug

  def self.all_proposals_for_subdomain(subdomain = nil)
    subdomain ||= current_subdomain
    proposals = nil 

    if subdomain.moderation_policy == 1
      moderation_status_check = "(moderation_status=1 OR user_id=#{current_user.id})"
    else 
      moderation_status_check = "(moderation_status IS NULL OR moderation_status=1 OR user_id=#{current_user.id})"
    end

    proposals = subdomain.proposals.where(:hide_on_homepage => false).where(moderation_status_check)
    proposals

  end 

  def self.summaries(subdomain = nil, all_points = false)
    subdomain ||= current_subdomain
    
    proposals = all_proposals_for_subdomain(subdomain)

    # Impose access control restrictions for current user    
    proposals = proposals.select {|p| permit('read proposal', p) > 0 }

    proposals_obj = {
      key: '/proposals',
    }

    proposals_map = {}
    proposals.each do |p|
      proposals_map[p.id] = true
    end

    if subdomain.moderation_policy == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    points = subdomain.points.where("(published=1 AND #{moderation_status_check})").select {|pnt| proposals_map.has_key?(pnt.proposal_id)}
    points_by_proposals = {}
    points.each do |pnt|
      if !points_by_proposals.has_key?(pnt.proposal_id)
        points_by_proposals[pnt.proposal_id] = []
      end 
      points_by_proposals[pnt.proposal_id].push pnt
    end

    opinions = ActiveRecord::Base.connection.execute """\
      SELECT created_at, id, point_inclusions, proposal_id, 
      stance, user_id, updated_at, explanation
          FROM opinions 
          WHERE subdomain_id=#{subdomain.id} AND
                published=1;
      """
    opinions_by_proposal = {}
    opinions.each do |o|
      proposal_id = o[3]
      if !opinions_by_proposal.has_key?(proposal_id)
        opinions_by_proposal[proposal_id] = []
      end

      op = {
        key: "/opinion/#{o[1]}",
        # created_at: o[0],
        updated_at: o[6],
        # proposal: "/proposal/#{o[3]}",
        user: "/user/#{o[5]}",
        # published: true,
        stance: o[4].to_f        
      }

      if o[7]
        op['explanation'] = o[7]
      end

      if o[2] && o[2] != '[]'
        op[:point_inclusions] = Oj.load(o[2]).map! {|p| "/point/#{p}"}
      end 

      opinions_by_proposal[proposal_id].push op 
    end 

    proposals_obj[:proposals] = proposals.map do |p|
      options = {
        :points => (points_by_proposals[p.id] or []),
        :opinions => (opinions_by_proposal[p.id] or [])
      }
      p.as_json options
    end 

    if all_points 
      proposals_obj[:points] = points.public_fields.map {|p| p.as_json}
    end

    proposals_obj

  end

  def full_data

    if self.subdomain.moderation_policy == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    pointz = self.points.where("(published=1 AND #{moderation_status_check}) OR user_id=#{current_user.id}")
    pointz = pointz.public_fields.map {|p| p.as_json}

    data = { 
      key: "/page/#{self.slug}",
      proposal: "/proposal/#{self.id}",
      points: pointz
    }

    data

  end

  def as_json(options={})
    # options[:only] ||= Proposal.my_public_fields
    # json = super(options)

    json = {
      "id" => self.id, 
      "slug" => self.slug, 
      "cluster" => self.cluster, 
      "user_id" => self.user_id, 
      "created_at" => self.created_at, 
      "updated_at" => self.updated_at, 
      "name" => self.name, 
      "description" => self.description, 
      "active" => self.active, 
      "hide_on_homepage" => self.hide_on_homepage, 
      "published" => self.published, 
      "subdomain_id" => self.subdomain_id, 
      "json" => self.json
    }

    # Find an existing opinion for this user
    if !options.has_key?(:opinions)
      if current_user.logged_in?
        your_opinion = self.opinions.where(:user_id => current_user.id).order('id DESC')
        if your_opinion.length > 1
          pp "Duplicate opinions for user #{current_user}: #{your_opinion.map {|o| o.id} }!"
        end      
        your_opinion = your_opinion.first
      else 
        your_opinion = nil 
      end
    else 
      user_key = "/user/#{current_user.id}"
      options[:opinions].find { |o| o[:user] == user_key }
    end

    if your_opinion
      json['your_opinion'] = your_opinion 
    else 
      json['your_opinion'] = {
        stance: 0,
        user: "/user/#{current_user.id}",
        point_inclusions: [],
        proposal: "/proposal/#{self.id}",
        published: false
      }
    end

    if !options.has_key?(:opinions)

      o = ActiveRecord::Base.connection.execute """\
        SELECT created_at, id, point_inclusions, proposal_id, 
        stance, user_id, updated_at, explanation
            FROM opinions 
            WHERE subdomain_id=#{self.subdomain_id} AND
                  proposal_id=#{self.id} AND 
                  published=1;
        """

      json['opinions'] = o.map do |op|
        r = {
          key: "/opinion/#{op[1]}",
          # created_at: op[0],
          updated_at: op[6],
          # proposal: "/proposal/#{op[3]}",
          user: "/user/#{op[5]}",
          # published: true,
          stance: op[4].to_f

        }
        if op[7]
          r['explanation'] = op[7]
        end

        if op[2] && op[2] != '[]'
          r[:point_inclusions] = Oj.load(op[2]).map! {|p| "/point/#{p}"}
        end 

        r 
      end 
    else
      json['opinions'] = options[:opinions]
    end


    json['json'] = json['json'] || {}

    make_key(json, 'proposal')
    stubify_field(json, 'user')

    if permit('update proposal', self) > 0
      json['roles'] = self.user_roles
      json['invitations'] = nil
    else
      json['roles'] = self.user_roles(filter = true)
    end

    if self.subdomain.moderation_policy == 1 && self.moderation_status == nil 
      json['under_review'] = true
    end 

    if self.pic_file_name 
      json['pic'] = self.pic.url(:square)
    end

    if self.banner_file_name 
      json['banner'] = self.banner.url
    end

    if self.subdomain.moderation_policy == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    if options[:points]
      json['point_count'] = options[:points].length
    else 
      json['point_count'] = self.points.where("(published=1 AND #{moderation_status_check} AND json_length(includers) > 0) OR user_id=#{current_user.id}").count
    end 

    json
  end


  def key
    "/proposal/#{id}"
  end

  # Returns a hash of all the roles. Each role is expressed
  # as a list of (1) user keys, (2) email addresses (for users w/o an account)
  # and (3) email wildcards ('*', '*@consider.it'). 
  # 
  # Setting filter to try returns a roles hash that strips out 
  # all specific email addresses / user keys that are not the
  # current user. 
  #
  # TODO: consolidate with subdomain.user_roles
  def user_roles(filter = false)
    rolez = roles ? roles.deep_dup : {}


    ['editor', 'participant', 'observer'].each do |role|

      # Initialize empty role
      if !rolez[role]
        if role == 'observer' && current_subdomain
          # default to subdomain setting
          rolez[role] = current_subdomain.user_roles['visitor'] || ['*']
        elsif role == 'participant' && current_subdomain
          rolez[role] = current_subdomain.user_roles['participant'] || ['*']
        else
          rolez[role] = [] 
        end
      end

      # Filter role if the client isn't supposed to see it
      if filter
        # Remove all specific email address for privacy.
        # Is used by client permissions system to determining whether 
        # to show action buttons for unauthenticated users. 
        rolez[role] = rolez[role].map{|email_or_key|
          email_or_key.index('*') || email_or_key == "/user/#{current_user.id}" || email_or_key.index('@') == nil ? email_or_key : '-'
        }.uniq
      end
    end
    rolez
  end

  
  def title(max_len = 140)
    if name && name.length > 0
      my_title = name
    elsif description
      my_title = description
    else
      raise 'Name and description nil'
    end

    if my_title.length > max_len
      "#{my_title[0..max_len]}..."
    else
      my_title
    end
    
  end


  def open_to_public
    !hide_on_homepage && user_roles['observer'].index('*')
  end


  def add_seo_keyword(keyword)
    self.seo_keywords ||= ""
    self.seo_keywords += "#{keyword}," if !self.seo_keywords.index("#{keyword},")
  end




  private 

  # Sanitize the HTML fields that we insert dangerously in the client. 
  # We allow superadmins to post arbitrary HTML though.
  def strip_html
    if !defined?(Rails::Console) && current_user && !current_user.is_admin?
      # Initialize fields if empty
      self.description        = self.description || '' 
    end

    if current_user && !current_user.is_admin?
      # Sanitize description
      self.description = sanitize_helper(self.description)
    end
  end 

  def set_slug
    if !self.slug || self.slug.length == 0 || self.slug.length >= 120
      
      if self.id
        str_id = self.id.to_s
      else 
        ActsAsTenant.without_tenant do 
          str_id = Proposal.last ? (Proposal.last.id + 1).to_s : "1"
        end 
      end

      len_name = self.name.length 
      len_cluster = (self.cluster || '').length
      len_id = str_id.length

      if len_name + len_cluster + len_id + 2 >= 120
        if len_cluster > 32
          self.slug = slugify "#{self.name[0...88]}-#{self.cluster[0...(31-len_id)]}-#{str_id}"
        else 
          self.slug = slugify "#{self.name[0...(120-len_cluster-1-len_id)]}-#{self.cluster}-#{str_id}"
        end
      else 
        self.slug = slugify "#{self.name}-#{self.cluster}-#{str_id}"
      end

    end 
  end



end
