module Moderatable
  extend ActiveSupport::Concern

  included do 
    has_one :moderation, :as => :moderatable, :class_name => 'Moderation', :dependent => :destroy    
  end

  def redo_moderation
    if self.moderation
      self.moderation.updated_since_last_evaluation = true
      self.moderation.save
    end
  end

end