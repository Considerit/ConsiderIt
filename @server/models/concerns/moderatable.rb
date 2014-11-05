module Moderatable
  extend ActiveSupport::Concern

  included do 
    has_one :moderation, :as => :moderatable, :class_name => 'Moderation', :dependent => :destroy
    
    class_attribute :moderatable_fields
    class_attribute :moderatable_objects
  end

  def moderatable?
    true
  end

end