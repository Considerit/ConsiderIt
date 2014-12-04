module Moderatable
  extend ActiveSupport::Concern

  included do 
    has_one :moderation, :as => :moderatable, :class_name => 'Moderation', :dependent => :destroy    
  end

end