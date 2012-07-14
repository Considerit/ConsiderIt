#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class DomainMap < ActiveRecord::Base
  belongs_to :proposal
  belongs_to :domain

  acts_as_tenant(:account)  
end
