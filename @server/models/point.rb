class Point < ActiveRecord::Base
  
  include Trackable, Followable, Commentable, Moderatable, Assessable
  
  has_paper_trail :only => [:hide_name, :published, :is_pro, :text, :nutshell, :user_id]  
  
  belongs_to :user
  belongs_to :proposal
  belongs_to :position
  has_many :inclusions, :dependent => :destroy
  has_many :point_listings, :dependent => :destroy
  
  validates :nutshell, :presence => true, :length => { :maximum => 141 }


  before_validation do 
    self.nutshell = Sanitize.clean(self.nutshell)
    self.text = Sanitize.clean(self.text, Sanitize::Config::RELAXED)

    if self.nutshell.length > 140 
      text << self.nutshell[139..-1]
      self.nutshell = self.nutshell[0..139]
    end

    if self.nutshell.length == 0 && !self.text.nil? && self.text.length > 0
      self.text =  self.text[139..self.text.length]
      self.nutshell = self.text[0..139]
    end

  end

  acts_as_tenant(:account)

  # cattr_reader :per_page
  # @@per_page = 4  

  self.moderatable_fields = [:nutshell, :text]
  self.moderatable_objects = lambda {
    Point.joins(:proposal).published.where(:proposals => {:active => true})
  }

  self.assessable_fields = [:nutshell, :text]
  self.assessable_objects = lambda {
    Point.joins(:proposal).published.where(:proposals => {:active => true})
  }

  class_attribute :my_public_fields
  self.my_public_fields = [:long_id, :appeal, :attention, :comment_count, :created_at, :divisiveness, :id, :includers, :is_pro, :moderation_status, :num_inclusions, :nutshell, :persuasiveness, :position_id, :proposal_id, :published, :score, :score_stance_group_0, :score_stance_group_1, :score_stance_group_2, :score_stance_group_3, :score_stance_group_4, :score_stance_group_5, :score_stance_group_6, :text, :unique_listings, :updated_at, :user_id, :hide_name]

  scope :public_fields, -> {select(self.my_public_fields)}
  scope :metrics_fields, -> {select([:id, :appeal, :attention, :comment_count, :divisiveness, :includers, :is_pro, :num_inclusions, :persuasiveness, :score, :score_stance_group_0, :score_stance_group_1, :score_stance_group_2, :score_stance_group_3, :score_stance_group_4, :score_stance_group_5, :score_stance_group_6, :unique_listings])}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  scope :viewable, -> {where( 'published=1 AND (moderation_status IS NULL OR moderation_status=1)')}
  #default_scope where( :published => true )  
  
  scope :pros, -> {where( :is_pro => true )}
  scope :cons, -> {where( :is_pro => false )}
  scope :ranked_overall, -> { published.order( "points.score DESC" ) }

  scope :ranked_popularity, -> { published.order( "points.attention DESC" ) }

  scope :ranked_unify, -> { published.order( "points.appeal DESC" ) } 

  scope :ranked_divisive, -> { published.order( "points.divisiveness DESC" ) } 
  
  scope :ranked_persuasiveness, -> { published.order( "points.persuasiveness DESC" ) }
    
  scope :ranked_for_stance_segment, proc {|stance_bucket|
      published.
      where("points.score_stance_group_#{stance_bucket} > 0").
      order("points.score_stance_group_#{stance_bucket} DESC")
  }
  
  scope :not_included_by, proc {|user, included_points, deleted_points| 
    #chain = !user.nil? ? joins(:inclusions.outer, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NULL") : nil
    additional = (deleted_points && deleted_points.length > 0) ? " OR points.id IN (?)" : ""

    chain = user.nil? ? nil : published.joins("LEFT OUTER JOIN inclusions ON points.id = inclusions.point_id AND inclusions.user_id = #{user.id}").where(
      "inclusions.user_id IS NULL" + additional, deleted_points)

    if included_points.length > 0
      chain = chain.nil? ? where("points.id NOT IN (?)", included_points) : chain.where("points.id NOT IN (?)", included_points)
    end 
    chain
  }

  def as_json(options={})
    options[:only] ||= Point.my_public_fields
    super(options)
  end

  def only_public_fields
    self.to_json :only => Point.my_public_fields
  end  
  
  def self.included_by_stored(user, proposal, deleted_points)
    if user
      additional = (deleted_points && deleted_points.length > 0) ? " AND points.id NOT IN (?)" : ""
      Point.published.
        joins(:inclusions, "AND inclusions.user_id = #{user.id} AND points.proposal_id = #{proposal.id}").
        where("inclusions.user_id IS NOT NULL" + additional, deleted_points)
    else
      proposal.points.where(:id => -1) #null set
    end
  end

  def self.included_by_unstored(included_points, proposal)
    if included_points.length > 0
      proposal.points.where("points.id IN (?)", included_points)
    else
      proposal.points.published.where(:id => -1) #null set
    end
  end

  #WARNING: do not save these points after doing this
  def self.mask_anonymous_users(points, current_user)
    points.map do |pnt|
      pnt.mask_anonymous current_user
    end
    points
  end

  def mask_anonymous(current_user)
    if hide_name && (current_user.nil? || current_user.id != user_id)
      user_id = -1
    end
    self
  end

  def short_desc(max_len = 140)
    if nutshell.length > 0
      if text && text.length > 0 
        nutshell[(0..max_len)] + '...' 
      else 
        nutshell.length > max_len ? nutshell[(0..max_len)]+ '...' : nutshell
      end
    else
      return text && text.length > 0 ? text[(0..max_len)] : ''
    end
  end

  def category
    is_pro ? 'pro' : 'con'

  end

  def update_absolute_score(in_batch = false)
    self.comment_count = comments.count
    if !in_batch
      self.num_inclusions = self.inclusions.count
      self.unique_listings = self.point_listings.count
    end

    self.includers = self.inclusions(:select => [:user_id]).map {|x| x.user_id}.compact.uniq.to_s

    define_appeal
    define_attention
    define_persuasiveness
    
    define_segment_scores
    
    save(:validate => false) if changed?
  end
  
  def define_segment_scores
    
    metrics_per_segment = {}
    (0..6).each {|stance_bucket| metrics_per_segment[stance_bucket] = [0,0]}

    inclusions_by_segment = inclusions.joins(:position).select('COUNT(*) AS cnt, positions.stance_bucket AS stance_bucket').group("positions.stance_bucket").order("positions.stance_bucket")
    inclusions_by_segment.each do |row|
      metrics_per_segment[row.stance_bucket.to_i][0] = row.cnt.to_i
    end

    listings_by_segment = point_listings.joins(:position).select('COUNT(*) AS cnt, positions.stance_bucket AS stance_bucket').group("positions.stance_bucket").order("positions.stance_bucket")        
    listings_by_segment.each do |row|
      metrics_per_segment[row.stance_bucket.to_i][1] = row.cnt.to_i
    end
    
    (0..6).each do |stance_bucket|
      bucket_score = "score_stance_group_#{stance_bucket}".intern
            
      if metrics_per_segment[stance_bucket][1] == 0
        self[bucket_score] = 0.0
      else
        self[bucket_score] = metrics_per_segment[stance_bucket][0]**2 / metrics_per_segment[stance_bucket][1].to_f        
      end
    end
  end

  def define_appeal
    e = entropy
    if e.nil? or self.num_inclusions.nil?
      self.appeal = 0
      self.divisiveness = 0
    else
      self.appeal = e * self.num_inclusions
      self.divisiveness = (1 - e) * self.num_inclusions      
    end
  end
  
  def define_attention
    self.attention = self.num_inclusions
  end
  
  def define_persuasiveness
    if self.unique_listings && self.unique_listings > 1
      self.persuasiveness = self.num_inclusions.to_f / self.unique_listings 
    else
      self.persuasiveness = 1.0 #privilige those points that haven't been shown...
    end
  end
  
  # Class method for iterating through all Points to 
  # update their relative scores. Very computationally
  # expensive, so should only be called periodically by cron job
  def self.update_relative_scores
    num_inclusions_per_point = {}

    Inclusion.select("COUNT(*) AS cnt, point_id AS pnt").group(:point_id).each do |row|
      num_inclusions_per_point[row.pnt.to_i] = row.cnt.to_i
    end

    num_listings_per_point = {}
    PointListing.select("COUNT(distinct user_id) AS cnt, point_id AS pnt").group(:point_id).each do |row|
      num_listings_per_point[row.pnt.to_i] = row.cnt.to_i
    end

    Account.find_each do |accnt|

      accnt.proposals.active.select(:id).each do |proposal|

        
        # Point ranking across the metrics is done separately for pros and cons,
        # fixed on a particular Proposal
        point_groups = [
          proposal.points.viewable.pros.select("id, appeal, attention, persuasiveness, score, num_inclusions, unique_listings").to_a,
          proposal.points.viewable.cons.select("id, appeal, attention, persuasiveness, score, num_inclusions, unique_listings").to_a
        ]

        point_groups.each do |group|        
          relative_scores = {}

          Point.transaction do
            group.each do |pnt|
              pnt.num_inclusions = num_inclusions_per_point.has_key?(pnt.id) ? num_inclusions_per_point[pnt.id] : 0
              pnt.unique_listings = num_listings_per_point.has_key?(pnt.id) ? num_listings_per_point[pnt.id] : 0
              pnt.update_absolute_score(true)
              relative_scores[pnt.id] = []
            end
          end
          
          [:appeal.to_s, :attention.to_s, :persuasiveness.to_s].each do |metric|
            
            # descending sort of points by current metric
            group.sort! {|x,y| y.attributes[metric] <=> x.attributes[metric]}
            
            # now we'll compute the relative percentile ranking for the metric for each point (1=highest, 0 lowest)
            cur_val = nil
            rank = nil
            group.each_with_index do |pnt, idx|
              if !cur_val || pnt.attributes[metric] < cur_val
                rank = idx.to_f
                cur_val = pnt.attributes[metric]
              end
              relative_scores[pnt.id].push( 1 - rank / group.length )
            end
          end
          
          Point.transaction do
            group.each do |pnt|
              pnt.score = relative_scores[pnt.id].inject(:+) / relative_scores[pnt.id].length
              pnt.save(:validate => false)
            end
          end
                              
        end
      end
    end    
  end
  

protected
  def entropy
    
    distribution = Array.new(5, 0.0001)

    qry = inclusions.joins(:position)   \
                    .where("positions.published=1" )                                      \
                    .group('positions.stance_bucket')                                            \
                    .select("COUNT(*) AS cnt, positions.stance_bucket")
                        
    # get the number of inclusions per stance group
    qry.each do |row|
      # collapse strong and moderate support/oppose to make more fair distribution
      if row.stance_bucket == '0'
        row.stance_bucket = '1'
      elsif row.stance_bucket == '6'
        row.stance_bucket = '5'
      end
      begin
        distribution[row.stance_bucket.to_i - 1] += row.cnt.to_i    
      rescue
        'error'
      end
       
    end
    
    
    # scale the number of inclusions per stance group by the number of people who saw this 
    # point in the stance group
    scaling_distribution = Array.new(5, 0)
    qry = point_listings.joins(:position)   \
                        .where("positions.published=1" )                                      \
                        .group('positions.stance_bucket')                                            \
                        .select("COUNT(distinct point_listings.user_id) AS cnt, positions.stance_bucket")
                 
    qry.each do |row|
      # collapse strong and moderate support/oppose to make more fair distribution
      if row.stance_bucket == '0'
        row.stance_bucket = '1'
      elsif row.stance_bucket == '6'
        row.stance_bucket = '5'
      end
      begin
        scaling_distribution[row.stance_bucket.to_i - 1] += row.cnt.to_i     
      rescue
      end
    end
    
    (0..4).each do |idx|
      if scaling_distribution[idx] == 0
        # no one from this group has seen this point, so don't count group in entropy calculation
        distribution[idx] = 0
      else
        distribution[idx] /= scaling_distribution[idx]
      end
    end

    e = 0
    total = distribution.inject(:+)
    if total > 0
      distribution.each do |val|
        if val > 0
          # p is the probability of seeing this stance in the distribution
          p = 1.0 * val / total
          e -= p * Math.log(p, 5)
        end
      end
    end
    e    
  end
end
