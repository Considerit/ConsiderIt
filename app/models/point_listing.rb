class PointListing < ActiveRecord::Base
  belongs_to :proposal
  belongs_to :position
  belongs_to :point
  belongs_to :user
  belongs_to :inclusion
  
  scope :by_user_with_stance, proc {|stance_bucket| joins(:position).where("positions.stance_bucket=" + stance_bucket.to_s ) }

end
