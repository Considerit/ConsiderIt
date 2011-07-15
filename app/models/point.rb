class Point < ActiveRecord::Base
  belongs_to :user
  belongs_to :option
  belongs_to :position
  has_many :inclusions
  has_many :point_listings
  
  acts_as_paranoid_versioned :if_changed => [:nutshell, :text, :user_id, :is_pro, :position_id]

  cattr_reader :per_page
  @@per_page = 4  
  
  scope :pros, where( :is_pro => true )
  scope :cons, where( :is_pro => false )
  
  scope :not_included_by, proc {|user| 
    if !user.nil?
      joins(:inclusions.outer, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NULL")
    end }
    
  scope :included_by, proc {|user| 
    if !user.nil?
      joins(:inclusions, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NOT NULL") 
    end }
  
  scope :ranked_overall, 
    # where( "points.score > 0" ).
    order( "points.score DESC" )
  
  scope :ranked_persuasiveness, 
    # where( "points.persuasiveness > 0"). 
    order( "points.persuasiveness DESC" )
    
  scope :ranked_for_stance_segment, proc {|stance_bucket|
      where("points.score_stance_group_#{stance_bucket} > 0").
      order("points.score_stance_group_#{stance_bucket} DESC")
  }
  
  def update_absolute_score
    define_appeal
    define_attention
    define_persuasiveness
    
    define_segment_scores
    
    save
  end
  
  def define_segment_scores
    
    metrics_per_segment = {}
    (0..6).each {|stance_bucket| metrics_per_segment[stance_bucket] = [0,0]}

    inclusions_by_segment = inclusions.joins(:position).select('COUNT(*) AS cnt, positions.stance_bucket AS stance_bucket').group("positions.stance_bucket").order("positions.stance_bucket")
    inclusions_by_segment.each do |row|
      metrics_per_segment[row.stance_bucket.to_i][0] = row.cnt.to_i
    end

    listings_by_segment = point_listings.joins(:position).select('COUNT(distinct point_listings.user_id) AS cnt, positions.stance_bucket AS stance_bucket').group("positions.stance_bucket").order("positions.stance_bucket")        
    listings_by_segment.each do |row|
      metrics_per_segment[row.stance_bucket.to_i][1] = row.cnt.to_i
    end
    
    (0..6).each do |stance_bucket|
      attr = "score_stance_group_#{stance_bucket}".intern
            
      if metrics_per_segment[stance_bucket][1] == 0
        self.attributes[attr] = 0.0
      else
        self[attr] = metrics_per_segment[stance_bucket][0]**2 / metrics_per_segment[stance_bucket][1].to_f        
      end
    end
  end

  def define_appeal
    self.appeal = entropy
  end
  
  def define_attention
    self.attention = self.num_inclusions
  end
  
  def define_persuasiveness
    if self.unique_listings && self.unique_listings > 0
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

    Option.all.each do |option|
      Point.transaction do        
        option.points.each do |pnt|
          pnt.num_inclusions = num_inclusions_per_point.has_key?(pnt.id) ? num_inclusions_per_point[pnt.id] : 0
          pnt.unique_listings = num_listings_per_point.has_key?(pnt.id) ? num_listings_per_point[pnt.id] : 0
          pnt.update_absolute_score
        end
      end
      
      # Point ranking across the metrics is done separately for pros and cons,
      # fixed on a particular Option
      point_groups = [
        option.points.pros.select([:id, :appeal, :attention, :persuasiveness]).all,
        option.points.cons.select([:id, :appeal, :attention, :persuasiveness]).all
      ]

      point_groups.each do |group|        
        relative_scores = {}
        
        group.each {|pnt| relative_scores[pnt.id] = []}

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
            pnt.save
          end
        end
                            
      end

    end
  end
  
  

protected
  def entropy
    
    distribution = Array.new(5, 0.0001)

    qry = inclusions.joins(:position)   \
                    .where("positions.published" )                                      \
                    .group(:stance_bucket)                                            \
                    .select("COUNT(*) AS cnt, positions.stance_bucket")
                        
    # get the number of inclusions per stance group
    qry.each do |row|
      # collapse strong and moderate support/oppose to make more fair distribution
      if row.stance_bucket == '0'
        row.stance_bucket = '1'
      elsif row.stance_bucket == '6'
        row.stance_bucket = '5'
      end
      distribution[row.stance_bucket.to_i - 1] += row.cnt.to_i     
    end
    
    
    # scale the number of inclusions per stance group by the number of people who saw this 
    # point in the stance group
    scaling_distribution = Array.new(5, 0)
    qry = point_listings.joins(:position)   \
                        .where("positions.published" )                                      \
                        .group(:stance_bucket)                                            \
                        .select("COUNT(distinct point_listings.user_id) AS cnt, positions.stance_bucket")
                 
    qry.each do |row|
      # collapse strong and moderate support/oppose to make more fair distribution
      if row.stance_bucket == '0'
        row.stance_bucket = '1'
      elsif row.stance_bucket == '6'
        row.stance_bucket = '5'
      end
      scaling_distribution[row.stance_bucket.to_i - 1] += row.cnt.to_i     
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
