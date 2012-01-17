class Inclusion < ActiveRecord::Base
  belongs_to :point
  belongs_to :user
  belongs_to :position
  belongs_to :proposal
  has_one :point_listing

  #acts_as_paranoid_versioned
  
  scope :by_user_with_stance, proc {|stance_bucket| joins(:position).where("positions.stance_bucket=" + stance_bucket.to_s) }

  
end
