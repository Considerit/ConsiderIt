module Trackable
  def is_trackable
    has_many :activities, :as=>:action, :dependent=>:destroy
    include InstanceMethods
  end
  module InstanceMethods
    def track!
      Activity.build_from!(self)
    end

    def tracked?
      true
    end
  end
end
ActiveRecord::Base.extend Trackable
