require 'uri'

class PointLink < ActiveRecord::Base
  belongs_to :point
  belongs_to :user
  belongs_to :option  

  def short_loc
    URI.parse(url).host
  end

end