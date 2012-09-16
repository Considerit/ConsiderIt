#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal, :touch => true 
  has_many :inclusions
  has_many :points
  has_many :point_listings
  has_many :comments, :as => :commentable, :dependent => :destroy

  has_paper_trail
  is_commentable
  is_trackable
  is_followable

  acts_as_tenant(:account)
  
  #default_scope where( :published => true )
  scope :published, where( :published => true )
    

  def subsume( subsumed_position )
    subsumed_position.point_listings.update_all({:user_id => user_id, :position_id => id})
    subsumed_position.points.update_all({:user_id => user_id, :position_id => id})
    subsumed_position.inclusions.update_all({:user_id => user_id, :position_id => id})
    subsumed_position.comments.update_all({:commentable_id => id})
  end

  def self.get_bucket(value)
    if value == -1
      return 0
    elsif value == 1
      return 6
    elsif value <= 0.05 && value >= -0.05
      return 3
    elsif value >= 0.5
      return 5
    elsif value <= -0.5
      return 1
    elsif value >= 0.05
      return 4
    elsif value <= -0.05
      return 2
    end   
  end       

  def stance_name
    case stance_bucket
      when 0
        return "strong oppose"
      when 1
        return "oppose"
      when 2
        return "weak oppose"
      when 3
        return "undecided"
      when 4
        return "weak support"
      when 5
        return "support"
      when 6
        return "strong support"
    end
  end    

  def stance_name_adverb
    case stance_bucket
      when 0
        return "strongly oppose"
      when 1
        return "oppose"
      when 2
        return "weakly oppose"
      when 3
        return "are undecided"
      when 4
        return "weakly support"
      when 5
        return "support"
      when 6
        return "strongly support"
    end
  end    


  def stance_name_singular
    case stance_bucket
      when 0
        return "strongly opposes"
      when 1
        return "opposes"
      when 2
        return "weakly opposes"
      when 3
        return "is neutral about"
      when 4
        return "weakly supports"
      when 5
        return "supports"
      when 6
        return "strongly supports"
    end
  end   

end



