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

  include Followable, Moderatable
  
  class_attribute :my_public_fields, :my_summary_fields
  self.my_public_fields = [:id, :slug, :cluster, :user_id, :created_at, :updated_at, :category, :designator, :name, :description, :description_fields, :active, :hide_on_homepage, :published]

  scope :active, -> {where( :active => true, :published => true )}


  # Sanitize the HTML fields that we insert dangerously in the client. 
  # We allow superadmins to post arbitrary HTML though. 
  before_validation(on: [:create, :update]) do

    if !current_user.super_admin
      # Initialize fields if empty
      self.description        = '' if not attribute_present?("description")
      self.description_fields = '' if not attribute_present?("description_fields")

      # Sanitize description
      self.description = ActionController::Base.helpers.sanitize(self.description)
      # Sanitize description_fields[i].html
      self.description_fields =
        JSON.dump(JSON.parse(self.description_fields).map { |field|
                    field['html'] = ActionController::Base.helpers.sanitize(field['html'])
                    field
                  })
    end
  end

  def self.summaries(current_subdomain = nil)
    current_subdomain = Thread.current[:subdomain] if !current_subdomain

    # if a subdomain wants only specific clusters, ordered in a particular way, specify here
    manual_clusters = nil

    if current_subdomain.moderate_proposals_mode == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    if current_subdomain.name == 'livingvotersguide'
      year = 2014
      local_jurisdictions = []   
      
      user_tags = current_user.tags ? JSON.load(current_user.tags) : nil
      if user_tags && user_tags['zip']
        # If the user has a zipcode, we'll want to include all the jurisdictions 
        # associated with that zipcode. We'll also want to insert them between the statewide
        # measures and the advisory votes, since we hate the advisory votes. 
        local_jurisdictions = ActiveRecord::Base.connection.exec_query( "SELECT distinct(cluster) FROM proposals WHERE subdomain_id=#{current_subdomain.id} AND hide_on_homepage=1 AND zips like '%#{user_tags['zip']}%' ").map {|r| r['cluster']}
      end
      manual_clusters = ['Statewide measures', local_jurisdictions, 'Advisory votes'].flatten
      proposals = current_subdomain.proposals.where("YEAR(created_at)=#{year}").where('cluster IN (?)', manual_clusters)
    else 
      proposals = current_subdomain.proposals.where(:hide_on_homepage => false)
    end

    proposals = proposals.where(moderation_status_check)

    clustered_proposals = {}

    # group all proposals into clusters

    proposals.each do |proposal|

      # Impose access control restrictions for current user
      next if permit('read proposal', proposal) < 0

      clustered_proposals[proposal.cluster] = [] if !clustered_proposals.has_key? proposal.cluster
      clustered_proposals[proposal.cluster].append proposal.as_json
    end

    # now order the clusters
    if !manual_clusters
      #TODO: order the group for the general case. Probably sort groups by the most recent Opinion.
      ordered_clusters = clustered_proposals.keys()
    else 
      ordered_clusters = manual_clusters
    end
    clusters = ordered_clusters.map {|cluster| {:name => cluster, :proposals => clustered_proposals[cluster] } }.select {|c| c[:proposals]}
    proposals = {
      key: '/proposals',
      clusters: clusters
    }

    proposals

  end


  def as_json(options={})
    options[:only] ||= Proposal.my_public_fields
    json = super(options)

    # Find an existing opinion for this user
    your_opinion = Opinion.where(:proposal_id => self.id, :user => current_user).first
    json['your_opinion'] = "/opinion/#{your_opinion.id}" if your_opinion

    json['top_point'] = self.points.published.order(:score).last

    make_key(json, 'proposal')
    stubify_field(json, 'user')
    follows = get_explicit_follow(current_user) 
    json["is_following"] = follows ? follows.follow : true #default the user to being subscribed 

    json['assessment_enabled'] = fact_check_request_enabled?

    if permit('update proposal', self) > 0
      json['roles'] = self.user_roles
      json['invitations'] = nil
    else
      json['roles'] = self.user_roles(filter = true)
    end

    json
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
    result = JSON.parse(roles || "{}")
    ['editor', 'writer', 'commenter', 'opiner', 'observer'].each do |role|

      # Initialize empty role to []
      result[role] = [] if !result.has_key?(role) || !result[role]

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
    return false # nothing can be requested to be fact-checked currently

    current_subdomain = Thread.current[:subdomain]

    enabled = current_subdomain.assessment_enabled
    if current_subdomain.name == 'livingvotersguide'
      # only some issues in LVG are fact-checkable
      enabled = ['I-1351_Modify_K-12_funding', 'I-591_Match_state_gun_regulation_to_national_standards', 'I-594_Increase_background_checks_on_gun_purchases'].include? slug
    end
    enabled && active
  end

  # def self.content_for_user(user)
  #   user.proposals.public_fields.to_a + Proposal.privately_shared.where("LOWER(CONVERT(access_list USING utf8)) like '%#{user.email}%' ").public_fields.to_a
  # end



  # The user is subscribed to proposal notifications _implicitly_ if:
  #   • they have an opinion (published or not)
  def following(follower)
    explicit = get_explicit_follow follower #using the Followable polymophic method
    if explicit
      return explicit.follow
    else
      return opinions.where(:user_id => follower.id, :published => true).count > 0
    end
  end
  
  def followers
    explicit = Follow.where(:followable_type => self.class.name, :followable_id => self.id, :explicit => true)
    explicit_no = explicit.all.select {|f| !f.follow}.map {|f| f.user_id}
    explicit_yes = explicit.all.select {|f| f.follow}.map {|f| f.user}

    implicit_yes = opinions.where(:published => true)
    if explicit_no.count > 0 
      implicit_yes = implicit_yes.where("user_id NOT IN (?)", explicit_no).all.map {|o| o}
    end
    implicit_yes = implicit_yes.map {|o| o.user}

    all_followers = explicit_yes + implicit_yes

    all_followers.uniq
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

  # def notable_points
  #   opposers = points.order('score_stance_group_0 + score_stance_group_1 + score_stance_group_2 DESC').limit(1).first
  #   supporters = points.order('score_stance_group_6 + score_stance_group_5 + score_stance_group_4 DESC').limit(1).first
  #   common = points.order('appeal DESC').limit(1).first

  #   if opposers && opposers.inclusions.count > 1 && \
  #      supporters && supporters.inclusions.count > 1 && \
  #      common && common.appeal > 0 && common.inclusions.count > 1
  #     {
  #       :important_for_opposers => opposers,
  #       :important_for_supporters => supporters,
  #       :common => common
  #     }
  #   else
  #     nil
  #   end
  # end

  # def update_metrics
  #   self.num_points = points.count
  #   self.num_pros = points.pros.count
  #   self.num_cons = points.cons.count
  #   self.num_comments = 0
  #   self.num_inclusions = 0
  #   points.each do |pnt|
  #     self.num_comments += pnt.comments.count
  #     self.num_inclusions += pnt.inclusions.count
  #   end
  #   self.num_perspectives = opinions.published.count
  #   self.num_unpublished_opinions = opinions.where(:published => false).count
  #   self.num_supporters = opinions.published.where("stance_segment > ?", 3).count
  #   self.num_opposers = opinions.published.where("stance_segment < ?", 3).count

  #   provocative = num_perspectives == 0 ? 0 : num_perspectives.to_f / (num_perspectives + num_unpublished_opinions)

  #   latest_opinions = opinions.published.where(:created_at => 1.week.ago.beginning_of_week.advance(:days => -1)..1.week.ago.end_of_week).order('created_at DESC')    
  #   late_perspectives = latest_opinions.count
  #   late_supporters = latest_opinions.where("stance_segment > ?", 3).count
  #   self.trending = late_perspectives == 0 ? 0 : Math.log2(late_supporters + 1) * late_supporters.to_f / late_perspectives

  #   # combining provocative and trending for now...
  #   self.trending = ( self.trending + provocative ) / 2

  #   self.activity = Math.log2(num_perspectives + 1) * Math.log2(num_comments + num_points + num_inclusions + 1)      

  #   polarization = num_perspectives == 0 ? 1 : num_supporters.to_f / num_perspectives - 0.5
  #   self.contested = -4 * polarization ** 2 + 1


  #   self.participants = opinions(:select => [:user_id]).published.map {|x| x.user_id}.uniq.compact.to_s
  #   tc = points(:select => [:id]).cons.published.order('score DESC').limit(1)[0]
  #   tp = points(:select => [:id]).pros.published.order('score DESC').limit(1)[0]
  #   self.top_con = !tc.nil? ? tc.id : nil
  #   self.top_pro = !tp.nil? ? tp.id : nil

  #   self.save if changed?

  # end


  def add_seo_keyword(keyword)
    self.seo_keywords ||= ""
    self.seo_keywords += "#{keyword}," if !self.seo_keywords.index("#{keyword},")
  end

  def self.update_scores
    # for now, order by activity; later, incorporate trending    

    # Proposal.active.each do |p|
    #   p.update_metrics
    #   p.save
    # end

    true
  end


end
