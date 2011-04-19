class Inclusion < ActiveRecord::Base
  belongs_to :point
  belongs_to :user
  belongs_to :position
  belongs_to :option

  acts_as_paranoid_versioned
  
end
