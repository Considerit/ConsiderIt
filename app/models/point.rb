class Point < ActiveRecord::Base
  belongs_to :user
  belongs_to :option
  belongs_to :position
  has_many :inclusions
  
  acts_as_paranoid_versioned

end
