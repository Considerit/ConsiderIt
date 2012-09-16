#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Followable::Follow < ActiveRecord::Base

  belongs_to :followable, :polymorphic=>true
  belongs_to :user

  def notify?
    follow
  end

  def self.build_from(obj, user_id, follow = false)
    c = self.new
    c.followable_id = obj.id 
    c.followable_type = obj.class.name 
    c.follow = follow
    c.user_id = user_id
    c
  end

  def root_object
    followable_type.constantize.find(followable_id)
  end
end
