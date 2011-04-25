class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :option  
  has_many :inclusions
  has_many :points
  has_many :point_listings
  
  acts_as_paranoid_versioned
  
  default_scope where( :published => true )
  scope :published, where( :published => true )
end



