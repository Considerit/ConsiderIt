module Reflectable
  def is_reflectable
    has_many :reflect_bullets, :as=>:reflectable, :dependent=>:destroy
    include InstanceMethods
  end
  module InstanceMethods
    def reflectable?
      true
    end
  end
end
ActiveRecord::Base.extend Reflectable
