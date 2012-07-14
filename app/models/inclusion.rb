#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Inclusion < ActiveRecord::Base
  has_paper_trail :only => [:point_id, :user_id, :included_as_pro]  
  is_trackable
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :position
  belongs_to :proposal
  has_one :point_listing

  acts_as_tenant(:account)
    
  scope :by_user_with_stance, proc {|stance_bucket| joins(:position).where("positions.stance_bucket=" + stance_bucket.to_s) }

  
end
