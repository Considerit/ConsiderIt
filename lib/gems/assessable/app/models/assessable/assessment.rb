#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Assessable::Assessment < ActiveRecord::Base

  belongs_to :assessable, :polymorphic=>true
  belongs_to :user
  
  acts_as_tenant(:account)

  def self.build_from(obj, user_id, status)
    c = self.new
    c.assessable_id = obj.id 
    c.assessable_type = obj.class.name 
    c.status = status
    c.user_id = user_id
    c
  end

  def root_object
    assessable_type.constantize.find(assessable_id)
  end

end
