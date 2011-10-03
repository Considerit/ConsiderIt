class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :option  
  has_many :inclusions
  has_many :points
  has_many :point_listings
  
  acts_as_paranoid_versioned
  
  default_scope where( :published => true )
  scope :published, where( :published => true )

  def stance_name
    case stance_bucket
      when 0
        return "strongly opposed"
      when 1
        return "moderately opposed"
      when 2
        return "slightly opposed"
      when 3
        return "undecided"
      when 4
        return "slight support"
      when 5
        return "moderate support"
      when 6
        return "strong support"
    end
  end    

end



