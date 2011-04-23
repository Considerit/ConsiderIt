class PointListing < ActiveRecord::Base
  belongs_to :option
  belongs_to :position
  belongs_to :point
  belongs_to :user
  belongs_to :inclusion
end
