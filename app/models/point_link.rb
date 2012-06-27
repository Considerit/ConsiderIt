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