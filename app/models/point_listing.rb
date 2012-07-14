#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class PointListing < ActiveRecord::Base
  belongs_to :proposal
  belongs_to :position
  belongs_to :point
  belongs_to :user
  belongs_to :inclusion

  acts_as_tenant(:account)
  
  scope :by_user_with_stance, proc {|stance_bucket| joins(:position).where("positions.stance_bucket=" + stance_bucket.to_s ) }

end
