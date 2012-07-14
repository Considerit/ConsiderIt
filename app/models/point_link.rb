#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

require 'uri'

class PointLink < ActiveRecord::Base
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :proposal  

  acts_as_tenant(:account)

  def short_loc
    if URI.parse(url).host
      URI.parse(url).host
    else
      url
    end
  end

  def safe_url
    if url.start_with?('http://') || url.start_with?( 'https://')
      url
    else
      'http://' + url
    end
  end

end