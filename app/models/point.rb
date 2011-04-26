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
  scope :not_included_by, proc {|user| joins(:inclusions.outer, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NULL") }
  scope :included_by, proc {|user| joins(:inclusions, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NOT NULL") }
  
  scope :ranked_overall, order( "points.score DESC" )
  scope :ranked_persuasiveness, order( "points.persuasiveness DESC" )
  
  def update_absolute_score
    define_appeal
    define_attention #must come before persuasiveness
    define_persuasiveness
    save
  end
    
  def define_appeal
    self.appeal = entropy
  end
  
  def define_attention
    self.num_inclusions = inclusions.count
    self.attention = self.num_inclusions
  end
  
  def define_persuasiveness
    self.unique_listings = point_listings.select('DISTINCT user_id').count
    if self.unique_listings > 0
      self.persuasiveness = self.num_inclusions.to_f / unique_listings 
    else
      self.persuasiveness = 1.0
    end
  end
  
  # Class method for iterating through all Points to 
  # update their relative scores. Very computationally
  # expensive, so should only be called periodically by cron job
  def self.update_relative_scores

    Option.all.each do |option|
      
      option.points.each do |pnt|
        pnt.update_absolute_score
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
        
        group.each do |pnt|
          pnt.score = relative_scores[pnt.id].inject(:+) / relative_scores[pnt.id].length          
          pnt.save
        end
                    
      end

    end
  end
  
  

protected
  def entropy
    
    distribution = Array.new(5, 0.0001)

    qry = inclusions.joins(:position, "AND inclusions.user_id = positions.user_id")   \
                    .where("positions.published = 1" )                                      \
                    .group(:stance_bucket)                                            \
                    .select("COUNT(*) as cnt, positions.stance_bucket")
                        
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
    qry = point_listings.joins(:position, "AND point_listings.user_id = positions.user_id")   \
                        .where("positions.published = 1" )                                      \
                        .group(:stance_bucket)                                            \
                        .select("COUNT(distinct point_listings.user_id) as cnt, positions.stance_bucket")
                 
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
