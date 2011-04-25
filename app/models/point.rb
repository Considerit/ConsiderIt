class Point < ActiveRecord::Base
  belongs_to :user
  belongs_to :option
  belongs_to :position
  has_many :inclusions
  has_many :point_listings
  
  acts_as_paranoid_versioned
  
  cattr_reader :per_page
  @@per_page = 4  
  
  scope :pros, where( :is_pro => true )
  scope :cons, where( :is_pro => false )
  scope :not_included_by, proc {|user| joins(:inclusions.outer, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NULL") }
  scope :included_by, proc {|user| joins(:inclusions, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NOT NULL") }
  
  def update_absolute_score
    define_appeal
    define_attention #must come before persuasiveness
    define_persuasiveness
  end
  
  def update_relative_score
    
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
      elsif row.stance_bucket == '7'
        row.stance_bucket = '6'
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
      elsif row.stance_bucket == '7'
        row.stance_bucket = '6'
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
          e -= p * Math.log(p, 7)
        end
      end
    end
    pp e
    e
    
  end
end
