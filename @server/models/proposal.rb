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

  def self.clear_cache
    Proposal.clear_cache_points
    Proposal.clear_cache_proposals
    Proposal.clear_cache_opinions
  end
  def self.clear_cache_opinions
    Rails.cache.delete "#{current_subdomain.name}-Opinions"
  end
  def self.clear_cache_points
    Rails.cache.delete "#{current_subdomain.name}-Points"
  end
  def self.clear_cache_proposals
    Rails.cache.delete "#{current_subdomain.name}-Proposals"
  end

  def self.summaries(subdomain = nil, all_points = false)
    start_time = Time.now

    subdomain ||= current_subdomain
    
    # Impose access control restrictions for current user
    read_proposals = Permissions.permit('read proposal')
    if read_proposals <= 0
      proposals = []
    else

      moderation_policy = subdomain.moderation_policy
      asset_host = Rails.application.config.action_controller.asset_host
      current_user_key = "/user/#{current_user.id}"

      ############
      # OPINIONS

      opinions_key = "#{subdomain.name}-Opinions"
      opinions_by_proposal = Rails.cache.fetch(opinions_key, {expires_in: 29.minutes} ) do 
        opinions = ActiveRecord::Base.connection.execute """\
          SELECT CONCAT('/opinion/', id) as \"key\", point_inclusions, proposal_id, 
          stance, CONCAT('/user/', user_id) as user, updated_at
              FROM opinions 
              WHERE subdomain_id=#{subdomain.id};
          """
        by_proposal = {}

        opinions.each(:as => :hash) do |o|
          proposal_id = o["proposal_id"].to_i

          o.delete("proposal_id")

          if o["point_inclusions"] && o["point_inclusions"] != '[]'
            o["point_inclusions"] = Oj.load(o["point_inclusions"]).map! {|p| "/point/#{p}"}
          else
            o.delete "point_inclusions"
          end 

          by_proposal[proposal_id] ||= []          
          by_proposal[proposal_id].push o 
        end 
        JSON.dump by_proposal
      end

      opinions_by_proposal = JSON.parse opinions_by_proposal

      your_opinions_by_proposal = {}

      if current_user.registered
        your_opinions = ActiveRecord::Base.connection.execute """\
          SELECT CONCAT('/opinion/', id) as \"key\", point_inclusions, proposal_id, 
          stance, CONCAT('/user/', user_id) as user, updated_at
              FROM opinions 
              WHERE subdomain_id=#{subdomain.id} AND user_id=#{current_user.id};
          """

        your_opinions.each(:as => :hash) do |o|
          proposal_id = o["proposal_id"]
          o.delete("proposal_id")

          if o["point_inclusions"] && o["point_inclusions"] != '[]'
            o["point_inclusions"] = Oj.load(o["point_inclusions"]).map! {|p| "/point/#{p}"}
          else
            o.delete "point_inclusions"
          end 

          your_opinions_by_proposal[proposal_id] = o
        end
      end

      
      ############
      # POINTS

      points_key = "#{subdomain.name}-Points"
      moderation_status_check = "(moderation_status is NULL OR moderation_status != 0)"      

      pre_points_by_proposal = Rails.cache.fetch(points_key, expires_in: 59.minutes ) do 
        # if subdomain.moderation_policy == 1
        #   moderation_status_check = 'moderation_status=1'
        # else 
        #   moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
        # end

        ppoints = ActiveRecord::Base.connection.execute """\
          SELECT comment_count, created_at, updated_at, id, includers, is_pro, nutshell, 
                 proposal_id, published, text, user_id, hide_name, last_inclusion, subdomain_id, moderation_status
              FROM points 
              WHERE subdomain_id=#{subdomain.id} AND
                    published=1 AND
                    #{moderation_status_check};
          """

        by_proposal = {}
        ppoints.each(:as => :hash) do |pnt|
          proposal_id = pnt["proposal_id"]

          ppnt = {
            "id" => pnt["id"],
            "comment_count" => pnt["comment_count"],
            "created_at" => pnt["created_at"], 
            "updated_at" => pnt["updated_at"], 
            "key" => "/point/#{pnt["id"]}",
            "includers" => pnt["includers"],
            "is_pro" => pnt["is_pro"] == 1, 
            "nutshell" => pnt["nutshell"],
            "proposal" => "/proposal/#{pnt["proposal_id"]}",
            "published" => pnt["published"] == 1,
            "text" => pnt["text"],
            "user" => "/user/#{pnt["user_id"]}",
            "hide_name" => pnt["hide_name"] == 1,
            "last_inclusion" => pnt["last_inclusion"],
            "subdomain_id" => pnt["subdomain_id"],
            "moderation_status" => pnt["moderation_status"]
          }


          if ppnt["includers"]
            ppnt["includers"] = JSON.load(ppnt["includers"]).map! {|u| u.is_a?(Integer) ? "/user/#{u}" : u}
          else 
            ppnt["includers"] = []
          end 

          by_proposal[proposal_id] ||= []
          by_proposal[proposal_id].push ppnt

        end
        JSON.dump by_proposal
      end

      pre_points_by_proposal = JSON.parse pre_points_by_proposal

      points_by_proposal = {}
      
      pre_points_by_proposal.each do |proposal_id, points|
        points_by_proposal[proposal_id] = []
        points.each do |ppnt|
          # passes moderation
          passes = ppnt['moderation_status'] == 1 || ppnt['user'] == current_user_key

          if subdomain.moderation_policy != 1
            passes ||= ppnt['moderation_status'] == nil
          end
          next if !passes

          pnt = ppnt.deep_dup
          pnt.delete("moderation_status")

          # If anonymous, hide user id
          if pnt["hide_name"]
            pnt["includers"].map! {|u| u == pnt["user"] ? "/user/-1" : u }

            if current_user.nil? || current_user.id != pnt[10]
              pnt["user"] = "/user/-1"
            end 
          end
          points_by_proposal[proposal_id].push pnt
        end
      end

      #################
      # PROPOSALS
      proposals_key = "#{subdomain.name}-Proposals"
      moderation_status_check = "(moderation_status is NULL OR moderation_status != 0)"      
      
      json_proposals = Rails.cache.fetch(proposals_key, expires_in: 93.minutes ) do 
        pp "CACHING PROPOSALS"

        

        qry = """\
          SELECT id, concat('/proposal/', id) as \"key\", slug, cluster, concat('/user/', user_id) as user, created_at, 
                 updated_at, name, 
                 description, active, published, subdomain_id, json,
                 moderation_status, pic_file_name, banner_file_name, roles
              FROM proposals 
              WHERE subdomain_id=#{subdomain.id} AND
                    hide_on_homepage = false AND
                    #{moderation_status_check};
          """


        pproposals = ActiveRecord::Base.connection.execute qry

        j_proposals = []
        pproposals.each(:as => :hash) do |p|
          if p["json"]
            p["json"] = JSON.load(p["json"])
          else 
            p["json"] = {}
          end

          if moderation_policy == 1 && !p["moderation_status"] 
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

          p["active"] = p["active"] == 1
          p["published"] = p["published"] == 1

          j_proposals.push p
        end
        JSON.dump j_proposals
      end
      json_proposals = JSON.parse json_proposals

      proposals = []

      is_admin = current_user.is_admin?(subdomain)
      registered = current_user.registered
      user_key = "/user/#{current_user.id}"


      json_proposals.each do |p|
        proposal = p.deep_dup

        passes = proposal['moderation_status'] == 1 || proposal['user'] == current_user_key

        if subdomain.moderation_policy != 1
          passes ||= proposal['moderation_status'] == nil
        end

        next if !passes

        roles = Oj.load(proposal["roles"])

        # this logic taken from 'update proposal' permission, so those need to be kept in sync
        can_update = registered && (is_admin || Permissions::matchEmail(Proposal.user_roles(roles)['editor'], current_user))
        proposal['roles'] = Proposal.user_roles roles, !can_update
        if can_update
          proposal['invitations'] = nil
        end

        opinions = opinions_by_proposal["#{proposal["id"]}"] || []
        proposal['opinions'] = opinions

        # Find an existing opinion for this user
        your_opinion = your_opinions_by_proposal.fetch(proposal["id"], nil)

        if your_opinion
          proposal['your_opinion'] = your_opinion 
        else 
          proposal['your_opinion'] = {
            stance: 0,
            user: user_key,
            point_inclusions: [],
            proposal: p["key"],
            published: false
          }
        end

        pnts = points_by_proposal.fetch(proposal["id"], [])

        if all_points
          proposal[:points] = pnts
        end 

        pnts_with_inclusions = pnts.select{ |pnt| pnt["includers"].length > 0 }

        proposal['point_count'] = pnts_with_inclusions.length
        proposals.push proposal
      end
    end

    Rails.logger.info("Code execution took: #{Time.now - start_time} seconds")

    proposals_obj = {
      key: '/proposals',
      proposals: proposals # .map {|p| p["key"]}
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

    if Permissions.permit('update proposal', self) > 0
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

  def get_cluster
    self.cluster or 'Proposals'
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
