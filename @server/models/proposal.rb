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

  validates_attachment_content_type :pic, :content_type => ["image/jpg", "image/jpeg", "image/pjpeg", "image/png","image/x-png", "image/gif", "image/webp"], message: "Only jpeg, png, gif, and webp images types are allowed"

  has_attached_file :banner, :processors => [:thumbnail]
  validates_attachment_content_type :banner, :content_type => ["image/jpg", "image/jpeg", "image/pjpeg", "image/png","image/x-png", "image/gif", "image/webp"], message: "Only jpeg, png, gif, and webp images types are allowed"

  belongs_to :user

  acts_as_tenant :subdomain

  include Moderatable, Notifier
  
  class_attribute :my_public_fields
  self.my_public_fields = [:id, :slug, :cluster, :user_id, :created_at, :updated_at, :name, :description, :active, :hide_on_homepage, :published, :subdomain_id, :json]

  scope :active, -> {where( :active => true, :published => true )}

  before_validation :strip_html

  before_save do 
    self.name = sanitize_helper(self.name) if self.name
    self.description = sanitize_helper(self.description) if self.description
    self.cluster = sanitize_helper(self.cluster) if self.cluster

    self.roles = sanitize_json(self.roles) if self.roles
    self.json = sanitize_json(self.json) if self.json
  end

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

  def self.summaries(subdomain = nil, all_points = false)
    subdomain ||= current_subdomain
    
    # Impose access control restrictions for current user
    read_proposals = permit('read proposal')
    if read_proposals <= 0
      proposals = []
    else

      is_admin = current_user.is_admin?(subdomain)
      registered = current_user.registered
      user_key = "/user/#{current_user.id}"
      moderation_policy = subdomain.moderation_policy
      asset_host = Rails.application.config.action_controller.asset_host

      ############
      # OPINIONS
      opinions = ActiveRecord::Base.connection.execute """\
        SELECT CONCAT('/opinion/', id) as \"key\", point_inclusions, proposal_id, 
        stance, CONCAT('/user/', user_id) as user, updated_at, published
            FROM opinions 
            WHERE subdomain_id=#{subdomain.id};
        """
      opinions_by_proposal = {}
      your_opinions_by_proposal = {}

      opinions.each(:as => :hash) do |o|
        next if o["published"] == 0 && o["user"] != user_key

        proposal_id = o["proposal_id"]
        if !opinions_by_proposal.has_key?(proposal_id)
          opinions_by_proposal[proposal_id] = []
        end

        o.delete("published")
        o.delete("proposal_id")

        if o["point_inclusions"] && o["point_inclusions"] != '[]'
          o["point_inclusions"] = Oj.load(o["point_inclusions"]).map! {|p| "/point/#{p}"}
        else
          o.delete "point_inclusions"
        end 

        opinions_by_proposal[proposal_id].push o 

        if o["user"] == user_key
          # o["proposal"] = "/proposal/#{proposal_id}"
          your_opinions_by_proposal[proposal_id] = o
        end
      end 

      ############
      # POINTS

      if subdomain.moderation_policy == 1
        moderation_status_check = 'moderation_status=1'
      else 
        moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
      end

      ppoints = ActiveRecord::Base.connection.execute """\
        SELECT comment_count, created_at, updated_at, id, includers, is_pro, nutshell, 
               proposal_id, published, text, user_id, hide_name, last_inclusion, subdomain_id
            FROM points 
            WHERE subdomain_id=#{subdomain.id} AND
                  published=1 AND
                  #{moderation_status_check};
        """

      points_by_proposal = {}
      ppoints.each do |pnt|
        proposal_id = pnt[7]

        ppnt = {
          "id" => pnt[3],
          "comment_count" => pnt[0],
          "created_at" => pnt[1], 
          "updated_at" => pnt[2], 
          "key" => "/point/#{pnt[3]}",
          "includers" => pnt[4],
          "is_pro" => pnt[5] == 1, 
          "nutshell" => pnt[6],
          "proposal" => "/proposal/#{pnt[7]}",
          "published" => pnt[8] == 1,
          "text" => pnt[9],
          "user" => "/user/#{pnt[10]}",
          "hide_name" => pnt[11] == 1,
          "last_inclusion" => pnt[12],
          "subdomain_id" => pnt[13]
        }


        if ppnt["includers"]
          ppnt["includers"] = JSON.load(ppnt["includers"]).map! {|u| u.is_a?(Integer) ? "/user/#{u}" : u}
        else 
          ppnt["includers"] = []
        end 


        # If anonymous, hide user id
        if ppnt["hide_name"]
          ppnt["includers"].map! {|u| u == ppnt["user"] ? "/user/-1" : u }

          if current_user.nil? || current_user.id != pnt[10]
            ppnt["user"] = "/user/-1"
          end 

        end


        points_by_proposal[proposal_id] ||= []
        points_by_proposal[proposal_id].push ppnt

      end


      #################
      # PROPOSALS
      if subdomain.moderation_policy == 1
        moderation_status_check = "(moderation_status=1 OR user_id=#{current_user.id})"
      else 
        moderation_status_check = "(moderation_status IS NULL OR moderation_status=1 OR user_id=#{current_user.id})"
      end

      pproposals = ActiveRecord::Base.connection.execute """\
        SELECT id, concat('/proposal/', id) as \"key\", slug, cluster, concat('/user/', user_id) as user, created_at, 
               updated_at, name, 
               description, active, published, subdomain_id, json,
               moderation_status, pic_file_name, banner_file_name, roles
            FROM proposals 
            WHERE subdomain_id=#{subdomain.id} AND
                  hide_on_homepage = false AND
                  #{moderation_status_check};
        """

      json_proposals = []
      pproposals.each(:as => :hash) do |p|
        if p["json"]
          p["json"] = JSON.load(p["json"])
        else 
          p["json"] = {}
        end

        if moderation_policy == 1 && !p["moderation_status"] # TODO: is p[14] nil or "null"?
          p["under_review"] = true
        end

        if p["pic_file_name"]
          p['pic'] = "#{asset_host}/system/pics/#{p["id"]}/square/#{p["pic_file_name"]}"
        end

        if p["banner_file_name"]
          p['banner'] = "#{asset_host}/system/banners/#{p["id"]}/original/#{p["banner_file_name"]}"
        end

        p.delete("banner_file_name")          
        p.delete("pic_file_name")
        p.delete("moderation_status")

        p["active"] = p["active"] == 1
        p["published"] = p["published"] == 1

        roles = Oj.load(p["roles"])

        # this logic taken from 'update proposal' permission, so those need to be kept in sync
        can_update = registered && (is_admin || Permitted::matchEmail(Proposal.user_roles(roles)['editor'], current_user))
        p['roles'] = Proposal.user_roles roles, !can_update
        if can_update
          p['invitations'] = nil
        end

        opinions = opinions_by_proposal[p["id"]] || []
        p['opinions'] = opinions

        # Find an existing opinion for this user
        your_opinion = your_opinions_by_proposal.fetch(p["id"], nil)

        if your_opinion
          p['your_opinion'] = your_opinion 
        else 
          p['your_opinion'] = {
            stance: 0,
            user: user_key,
            point_inclusions: [],
            proposal: p["key"],
            published: false
          }
        end

        pnts = points_by_proposal.fetch(p["id"], [])

        if all_points
          p[:points] = pnts
        end 

        pnts_with_inclusions = pnts.select{ |pnt| pnt["includers"].length > 0 }

        p['point_count'] = pnts_with_inclusions.length
        json_proposals.push p
      end

    end


    proposals_obj = {
      key: '/proposals',
      proposals: json_proposals
    }

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
      "created_at" => self.created_at.to_time.utc, 
      "updated_at" => self.updated_at.to_time.utc, 
      "name" => self.name, 
      "description" => self.description, 
      "active" => self.active, 
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

      your_opinion = options[:opinions].find { |o| o["user"] == user_key }
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
        # if op[7]
        #   r['explanation'] = op[7]
        # end

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


    if options[:points]
      pnts_with_inclusions = options[:points].select{ |p| p.includers.length > 0 }

      json['point_count'] = pnts_with_inclusions.length
    else 
      if self.subdomain.moderation_policy == 1
        moderation_status_check = 'moderation_status=1'
      else 
        moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
      end
      
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
  def user_roles(filter = false, user = nil)
    rolez = roles ? roles.deep_dup : {}
    Proposal.user_roles rolez, filter, user, self.subdomain
  end

  def self.user_roles(rolez, filter = false, user = nil, subdomain = nil)
    rolez ||= {}
    user ||= current_user
    subdomain ||= current_subdomain

    ['editor', 'participant', 'observer'].each do |role|

      # Initialize empty role
      if !rolez[role]
        if role == 'observer' && subdomain
          # default to subdomain setting
          rolez[role] = subdomain.user_roles['visitor'] || ['*']
        elsif role == 'participant' && subdomain
          rolez[role] = subdomain.user_roles['participant'] || ['*']
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
          email_or_key.index('*') || email_or_key == "/user/#{user.id}" || email_or_key.index('@') == nil ? email_or_key : '-'
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
