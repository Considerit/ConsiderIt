class Domain < ActiveRecord::Base
  has_many :domain_maps
  has_many :users
end
