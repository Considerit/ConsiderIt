class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :option  
  has_many :inclusions
  has_many :points
  
  acts_as_paranoid_versioned
  
end
