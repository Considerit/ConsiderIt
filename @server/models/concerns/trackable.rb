module Trackable
  extend ActiveSupport::Concern

  included do 
    has_many :activities, :as=>:action, :dependent=>:destroy
  end

  def track!
    Activity.build_from!(self)
  end

  def tracked?
    true
  end

end