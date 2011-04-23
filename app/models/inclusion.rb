class Inclusion < ActiveRecord::Base
  belongs_to :point
  belongs_to :user
  belongs_to :position
  belongs_to :option
  has_one :point_listing

  acts_as_paranoid_versioned
  
end
