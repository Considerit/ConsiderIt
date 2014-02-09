class Inclusion < ActiveRecord::Base
  has_paper_trail :only => [:point_id, :user_id, :included_as_pro]  
  include Trackable
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :opinion
  belongs_to :proposal

  acts_as_tenant(:account)
    
  #scope :by_user_with_stance, proc {|stance_bucket| joins(:opinion).where("opinions.stance_bucket=" + stance_bucket.to_s) }

  
end
