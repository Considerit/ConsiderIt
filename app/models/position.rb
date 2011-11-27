class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :option  
  has_many :inclusions
  has_many :points
  has_many :point_listings
  
  is_commentable
  
  acts_as_paranoid_versioned
  
  default_scope where( :published => true )
  scope :published, where( :published => true )

  
  def stance_name
    case stance_bucket
      when 0
        return "strongly oppose"
      when 1
        return "oppose"
      when 2
        return "weakly oppose"
      when 3
        return "undecided about"
      when 4
        return "weakly support"
      when 5
        return "support"
      when 6
        return "strongly support"
    end
  end    

end



