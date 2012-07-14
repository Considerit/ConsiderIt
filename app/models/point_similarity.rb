#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class PointSimilarity < ActiveRecord::Base
  belongs_to :p1, :class_name => "Point"
  belongs_to :p2, :class_name => "Point"
  belongs_to :proposal
  belongs_to :user

end
