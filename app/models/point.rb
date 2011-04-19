class Point < ActiveRecord::Base
  belongs_to :user
  belongs_to :option
    
  acts_as_paranoid_versioned

end
