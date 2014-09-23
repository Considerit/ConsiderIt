# coding: utf-8
class Proposal < ActiveRecord::Base
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy

  has_many :assessments, :through => :points, :dependent => :destroy
  has_many :claims, :through => :assessments, :dependent => :destroy

  belongs_to :user

  acts_as_tenant(:account)

  include Followable, Moderatable
  
  self.moderatable_fields = [:name, :description, :long_description]
  self.moderatable_objects = lambda { Proposal.published_web }

  #before_save :extract_tags

  class_attribute :my_public_fields, :my_summary_fields
  self.my_public_fields = [:id, :long_id, :cluster, :user_id, :created_at, :updated_at, :category, :designator, :name, :description, :description_fields, :active, :publicity, :published, :slider_right, :slider_left, :slider_middle, :considerations_prompt, :slider_prompt, :tags, :seo_keywords, :seo_title, :seo_description]

  scope :active, -> {where( :active => true, :published => true )}
  scope :inactive, -> {where( :active => false, :published => true )}
  scope :open_to_public, -> {where( :publicity => 2, :published => true )}
  scope :privately_shared, -> {where( 'publicity < 2')}
  scope :public_fields, -> {select(self.my_public_fields)}
  scope :unpublished, -> {where( :published => false)}
  scope :published_web, -> {where( :published => true)}
  scope :browsable, -> {where( :hide_on_homepage => false)}



  def self.summaries
        
    # if a customer wants only specific clusters, ordered in a particular way, specify here
    manual_clusters = nil
    current_tenant = Thread.current[:tenant]
    if current_tenant.identifier == 'livingvotersguide'

      local_jurisdictions = []   
      
      user_tags = current_user.tags && user_tags = JSON.load(current_user.tags)
      if user_tags && user_tags['zip']
        # If the user has a zipcode, we'll want to include all the jurisdictions 
        # associated with that zipcode. We'll also want to insert them between the statewide
        # measures and the advisory votes, since we hate the advisory votes. 
        local_jurisdictions = ActiveRecord::Base.connection.select( "SELECT distinct(cluster) FROM proposals WHERE account_id=#{current_tenant.id} AND active=1 AND hide_on_homepage=1 AND zips like '%#{user_tags['zip']}%' ").map {|r| r['cluster']}
      end
      manual_clusters = ['Statewide measures', local_jurisdictions, 'Advisory votes'].flatten
    end

    # get all the relevant proposals
    proposals = current_tenant.proposals.active.open_to_public #.browsable
    if manual_clusters
      proposals = proposals.where('cluster IN (?)', manual_clusters)
    end

    clustered_proposals = {}

    # group all proposals into clusters

    proposals.each do |proposal|        
      clustered_proposals[proposal.cluster] = [] if !clustered_proposals.has_key? proposal.cluster
      clustered_proposals[proposal.cluster].append proposal.proposal_summary()
    end

    # now order the clusters
    if !manual_clusters
      #TODO: order the group for the general case. Probably sort groups by the most recent Opinion.
      ordered_clusters = clustered_proposals.keys()
    else 
      ordered_clusters = manual_clusters
    end
    clusters = ordered_clusters.map {|cluster| {:name => cluster, :proposals => clustered_proposals[cluster] }}

    proposals = {
      key: '/proposals',
      clusters: clusters
    }

    proposals

  end

  def proposal_summary
    response = self.as_json

    # Find an existing published opinion for this user
    your_opinion = Opinion.where(:proposal_id => self.id, :user => current_user, :published => true).first

    top_point = self.points.published.order(:score).last

    response.update({:top_point => top_point})

    if your_opinion
      response.update({
        :your_opinion => "/opinion/#{your_opinion.id}"
      })
    end

    response
  end

  def proposal_data
    # TODO: figure out how this method relates to proposal#as_json & proposal#proposal_summary

    # Compute points
    pointz = points.where("((published=1 AND (moderation_status IS NULL OR moderation_status=1)) OR user_id=#{current_user ? current_user.id : -10})")
    pointz = pointz.public_fields.map do |p|
      p.as_json
    end

    # Find an existing opinion for this user
    your_opinion = Opinion.get_or_make(self, current_user)

    # Compute opinions
    published_opinions = opinions.published
    ops = published_opinions.public_fields.map {|x| x.as_json}

    if published_opinions.where(:user_id => nil).count > 0
      throw "We have published opinions without a user: #{published_opinions.map {|o| o.id}}"
    end

    # Put them together
    response = self.as_json
    response.update({
      :points => pointz,
      :opinions => ops,
      :top_point => self.points.published.order(:score).last, # otherwise top points get rewritten on homepage
      :your_opinion => "/opinion/#{your_opinion.id}"
    })

    # if can?(:manage, proposal) && self.publicity < 2
    #   response.update({
    #     :access_list => self.access_list
    #   })
    # end

    response
  end

  def as_json(options={})
    options[:only] ||= Proposal.my_public_fields
    result = super(options)

    make_key(result, 'proposal')
    stubify_field(result, 'user')
    follows = get_explicit_follow(current_user) 
    result["is_following"] = follows ? follows.follow : true #default the user to being subscribed 

    result
  end

  # def self.content_for_user(user)
  #   user.proposals.public_fields.to_a + Proposal.privately_shared.where("LOWER(CONVERT(access_list USING utf8)) like '%#{user.email}%' ").public_fields.to_a
  # end

  # The user is subscribed to proposal notifications _implicitly_ if:
  #   • they have an opinion (published or not)
  def following(follower)
    explicit = get_explicit_follow follower #using the Followable polymophic method
    if explicit
      return explicit.follow
    else
      return opinions.where(:user_id => follower.id, :published => true).count > 0
    end
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

  def stance_fractions
    distribution = Array.new(7,0)
    opinions.published.select('COUNT(*) AS cnt, stance_segment').group(:stance_segment).each do |row|
      distribution[row.stance_segment.to_i] = row.cnt.to_i
    end      
    total = distribution.inject(:+).to_f
    if total > 0     
      distribution.collect! { |stance_count| 100 * stance_count / total }
    end
    return distribution
  end

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

  # def get_tags
  #   description.split.find_all{|word| /^#.+/.match word}
  # end

  # def extract_tags
  #   self.tags += get_tags
  # end


  def has_tag(tag)
    self.tags && self.tags.index("#{tag};")
  end

  def add_tag(tag)
    self.tags ||= ""
    self.tags += "#{tag};" if !has_tag(tag)
  end

  def add_seo_keyword(keyword)
    self.seo_keywords ||= ""
    self.seo_keywords += "#{keyword}," if !self.seo_keywords.index("#{keyword},")
  end

  def add_long_id
    self.long_id = SecureRandom.hex(5)
    self.save
  end

  def self.add_long_id
    Proposal.where(:long_id => nil).each do |p|
      p.add_long_id
    end
  end

  def self.update_scores
    # for now, order by activity; later, incorporate trending    

    # Proposal.active.each do |p|
    #   p.update_metrics
    #   p.save
    # end

    true
  end

  # def self.import_from_spreadsheet(file, attrs)
  #   require 'csv'

  #   created = updated = errors = 0

  #   proposals = []

  #   CSV.foreach(file.tempfile, :headers => true) do |row|
  #     if !row.has_key?("long_id") || row["long_id"].length != 10
  #       errors += 1
  #       pp 'LONG ID NOT PRESENT OR NOT RIGHT LENGTH', row
  #       next
  #     end

  #     proposal = find_by_long_id(row["long_id"]) || new
  #     if proposal.id
  #       updated += 1
  #     else
  #       created += 1
  #     end
  #     proposal.attributes = row.to_hash.slice(*accessible_attributes).merge!(attrs)
  #     proposals.push proposal
  #     proposal.save!
  #   end


  #   {:updated => updated, :created => created, :errors => errors, :proposals => proposals}

  # end

  # only for LVG
  def self.import_jurisdictions(proposals_file, jurisdictions_file)
    jurisdiction_to_proposals = {}
    errors = []

    CSV.foreach(proposals_file.tempfile, :headers => true) do |row|
      proposal = Proposal.find_by_long_id(row['long_id'])
      if !proposal
        errors.push "Could not find proposal #{row['long_id']}"
        next
      end
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
      if jurisdiction == 'Statewide'
        proposal.add_tag 'type:statewide'
        proposal.add_tag "jurisdiction:State of Washington"
        proposal.add_seo_keyword 'Statewide'
        proposal.save
        next
      end

      if !(jurisdiction_to_proposals.has_key?(jurisdiction))
        jurisdiction_to_proposals[jurisdiction] = []
      end

      jurisdiction_to_proposals[jurisdiction].push proposal
    end

    jurisdiction_to_zips = {}
    CSV.foreach(jurisdictions_file.tempfile, :headers => true) do |row|
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        jurisdiction_to_zips[jurisdiction] = []
      end
      jurisdiction_to_zips[jurisdiction].push row['zip']
    end

    zips_count = 0
    prop_count = 0
    jurisdiction_to_proposals.each do |jurisdiction, proposals|
      jurisdiction = jurisdiction.split.map(&:capitalize).join(' ')
      zips = jurisdiction_to_zips[jurisdiction]
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        errors.push "ERROR: jurisdiction #{jurisdiction} not found!...skipping"
        next
      end
      pp "For #{jurisdiction}, adding #{zips.length} zips to #{proposals.length} measures"
      zips_count += zips.length
      prop_count += proposals.length
      # tags = zips.map{|z|"zip:#{z}"}.join(';')

      proposals.each do |p|
        p.add_tag "type:local"
        p.add_tag "jurisdiction:#{jurisdiction}"
        p.add_seo_keyword jurisdiction

        zips.each do |zip|
          p.hide_on_homepage = true
          p.add_tag "zip:#{zip}"
        end
        p.save

      end
    end

    result = {
      :jurisdiction_errors => errors,
      :jurisdictions => "Processed #{jurisdiction_to_proposals.length} jurisdictions, adding #{zips_count} zip codes across #{prop_count} measures"
    }
    result


  end

end
