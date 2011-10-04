require 'uri'

class PointLink < ActiveRecord::Base
  belongs_to :point
  belongs_to :user
  belongs_to :option  

  def short_loc
    if URI.parse(url).host
      URI.parse(url).host
    else
      url
    end
  end

  def safe_url
    if url.start_with? 'http://'
      url
    else
      'http://' + url
    end
  end

end