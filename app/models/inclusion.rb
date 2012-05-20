class Inclusion < ActiveRecord::Base
  has_paper_trail
  is_trackable
  belongs_to :point
  belongs_to :user
  belongs_to :position
  belongs_to :proposal
  has_one :point_listing

  acts_as_tenant(:account)
    
  scope :by_user_with_stance, proc {|stance_bucket| joins(:position).where("positions.stance_bucket=" + stance_bucket.to_s) }

  
end
