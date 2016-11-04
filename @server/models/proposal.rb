# coding: utf-8
class Proposal < ActiveRecord::Base
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy

  has_many :assessments, :through => :points, :dependent => :destroy
  has_many :claims, :through => :assessments, :dependent => :destroy
  has_many :requests, :through => :assessments, :dependent => :destroy

  belongs_to :user

  acts_as_tenant :subdomain

  include Moderatable, Notifier
  
  class_attribute :my_public_fields
  self.my_public_fields = [:id, :slug, :cluster, :user_id, :created_at, :updated_at, :name, :description, :description_fields, :active, :hide_on_homepage, :published, :histocache, :subdomain_id]

  scope :active, -> {where( :active => true, :published => true )}


  # Sanitize the HTML fields that we insert dangerously in the client. 
  # We allow superadmins to post arbitrary HTML though. 
  before_validation(on: [:create]) do

    if !defined?(Rails::Console) && current_user && !current_user.is_admin?
      # Initialize fields if empty
      self.description        = self.description || '' 
      self.description_fields = self.description_fields || '[]' 
    end

    if current_user && !current_user.is_admin?
      # Sanitize description
      self.description = sanitize_helper(self.description)
      # Sanitize description_fields[i].html
      self.description_fields =
        JSON.dump(JSON.parse(self.description_fields || '{}').map { |field|
                    field['html'] = sanitize_helper(field['html'])
                    field
                  })    
    end
  end

  

  def self.all_proposals_for_subdomain(subdomain = nil)
    subdomain ||= current_subdomain
    proposals = nil 

    # if a subdomain wants only specific clusters, ordered in a particular way, specify here
    manual_clusters = nil
    always_shown = [] 

    if subdomain.moderate_proposals_mode == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    if subdomain.name == 'livingvotersguide'
      local_jurisdictions = []   
      
      user_tags = current_user.tags ? JSON.load(current_user.tags) : nil
      if user_tags && user_tags['zip.editable']
        # If the user has a zipcode, we'll want to include all the jurisdictions 
        # associated with that zipcode. We'll also want to insert them between the statewide
        # measures and the advisory votes, since we hate the advisory votes. 
        local_jurisdictions = ActiveRecord::Base.connection.exec_query( 
          "SELECT distinct(cluster) FROM proposals WHERE subdomain_id=#{subdomain.id} AND hide_on_homepage=1 AND zips like '%#{user_tags['zip.editable']}%'")
          .map {|r| r['cluster']}
      end
      manual_clusters = ['Statewide measures', local_jurisdictions, 'Advisory votes'].flatten
      proposals = subdomain.proposals.where('cluster IN (?)', manual_clusters)

    elsif subdomain.name == 'homepage'        
      ActsAsTenant.without_tenant do 
        proposals = Proposal
                      .where(:hide_on_homepage => false)
                      .where('name != "Consider.it can help me"')
                      .where(:published => true)
      end 
    else 
      proposals = subdomain.proposals.where(:hide_on_homepage => false)
    end

    proposals = proposals.where(moderation_status_check)
    proposals

  end 

  def self.summaries(subdomain = nil, all_points = false)
    subdomain ||= current_subdomain
    
    proposals = all_proposals_for_subdomain(subdomain)

    # Impose access control restrictions for current user    
    proposals = proposals.select {|p| permit('read proposal', p) > 0 }

    # make sure that there is an opinion created for current
    # user for all proposals
    your_opinions = {}
    if subdomain.name != 'homepage'
      Opinion.where(:user => current_user).order('id DESC').each do |opinion|
        your_opinions[opinion.proposal_id] = opinion
      end 

      if your_opinions.keys().length < proposals.length
        missing_opinions = []
        proposals.each do |proposal|
          if !your_opinions.has_key?(proposal.id)
            missing_opinions << Opinion.new({
              :proposal_id => proposal.id,
              :user => current_user ? current_user : nil,
              :subdomain_id => current_subdomain.id,
              :stance => 0,
              :point_inclusions => '[]',
            })
          end 
        end 

        Opinion.import missing_opinions

        Opinion.where(:user => current_user).each do |opinion|
          your_opinions[opinion.proposal_id] = opinion
        end 
      end 
    end

    proposals_obj = {
      key: '/proposals',
      proposals: proposals.map {|p| p.as_json({}, your_opinions[p.id])}
    }

    if all_points 
      points = []
      proposals.each do |proposal|
        if subdomain.moderate_points_mode == 1
          moderation_status_check = 'moderation_status=1'
        else 
          moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
        end

        points.concat proposal.points.where("(published=1 AND #{moderation_status_check})").public_fields.map {|p| p.as_json}
      end
      proposals_obj[:points] = points
    end

    proposals_obj

  end

  def full_data

    if self.subdomain.moderate_points_mode == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    pointz = self.points.where("(published=1 AND #{moderation_status_check}) OR user_id=#{current_user.id}")
    pointz = pointz.public_fields.map {|p| p.as_json}

    # published_opinions = self.opinions.published
    # ops = published_opinions.public_fields.map {|x| x.as_json}

    # if published_opinions.where(:user_id => nil).count > 0
    #   throw "We have published opinions without a user: #{published_opinions.map {|o| o.id}}"
    # end

    data = { 
      key: "/page/#{self.slug}",
      proposal: "/proposal/#{self.id}",
      points: pointz,
      # opinions: ops
    }

    if self.subdomain.assessment_enabled
      data.update({
        :assessments => self.assessments.completed,
        :claims => self.assessments.completed.map {|a| a.claims}.compact.flatten,
        :verdicts => Assessable::Verdict.all
      })
    end

    data

  end

  def as_json(options={}, your_opinion=nil)
    options[:only] ||= Proposal.my_public_fields
    json = super(options)

    # Find an existing opinion for this user
    if current_subdomain.name != 'homepage'
      if !your_opinion
        your_opinion = Opinion.get_or_make(self)
      end 

      json['your_opinion'] = your_opinion #if your_opinion
    end

    # published_opinions = self.opinions.published
    # ops = published_opinions.public_fields.map {|x| x.as_json}

    o = ActiveRecord::Base.connection.execute """\
      SELECT created_at, id, point_inclusions, proposal_id, 
      stance, user_id, updated_at, subdomain_id
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

      if op[2] && op[2] != '[]'
        r[:point_inclusions] = Oj.load(op[2]).map! {|p| "/point/#{p}"}
      end 

      r 
    end 


    # The JSON.parse is expensive...
    json['histocache'] = Oj.load(json['histocache'] || '{}')


    make_key(json, 'proposal')
    stubify_field(json, 'user')

    if fact_check_request_enabled?
      json['assessment_enabled'] = true
    end

    if permit('update proposal', self) > 0
      json['roles'] = self.user_roles
      json['invitations'] = nil
    else
      json['roles'] = self.user_roles(filter = true)
    end

    #json['description_fields'] = JSON.parse(json['description_fields'] || '[]')


    json
  end

  def notifications
    current_user.notifications
      .where(
        digest_object_type: 'Proposal', 
        digest_object_id: self.id)
      .order('created_at DESC')
  end

  def safe_notifications
    Notifier.filter_unmoderated(notifications)
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
    result = Oj.load(roles || "{}")


    ['editor', 'writer', 'commenter', 'opiner', 'observer'].each do |role|

      # Initialize empty role
      if !result[role]
        if role == 'observer'
          # default to subdomain setting
          result[role] = subdomain.user_roles['visitor']
        else
          result[role] = [] 
        end
      end

      # Filter role if the client isn't supposed to see it
      if filter && role != 'editor'   # FIND BETTER FIX: mike added
                                      # "result != editor" so bitcoin
                                      # candidates can see the editor,
                                      # because he's temporarily
                                      # encoding 'editor' as
                                      # 'candidate' and needs to
                                      # display their photo.

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


  def fact_check_request_enabled?
    #return false # nothing can be requested to be fact-checked currently

    enabled = current_subdomain.assessment_enabled
    if current_subdomain.name == 'livingvotersguide'
      # only some issues in LVG are fact-checkable
      enabled = ['i_1366_state_taxes_and_fees', 'i_1401_trafficking_of_animal_species'].include? slug
      #['I-1351_Modify_K-12_funding', 'I-591_Match_state_gun_regulation_to_national_standards', 'I-594_Increase_background_checks_on_gun_purchases'].include? slug
    end
    enabled && active
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



end
