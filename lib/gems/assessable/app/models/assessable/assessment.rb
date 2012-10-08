#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Assessable::Assessment < ActiveRecord::Base
  belongs_to :user

  has_many :claims, :class_name => 'Assessable::Claim'
  has_many :requests, :class_name => 'Assessable::Request'
  
  acts_as_tenant(:account)

  def self.build_from(obj, user_id, status)
    c = self.new
    c.assessable_id = obj.id 
    c.assessable_type = obj.class.name 
    c.user_id = user_id
    c
  end

  def root_object
    assessable_type.constantize.find(assessable_id)
  end

  def update_overall_verdict
    if self.claims.count == 0
      self.overall_verdict = -1
    else
      self.overall_verdict = self.claims.map{|x| x.verdict}.compact.min
    end

  end

end
