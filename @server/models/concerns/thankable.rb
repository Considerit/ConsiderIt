module Thankable
  extend ActiveSupport::Concern

  included do 
    has_many :thanks, :as => :thankable, :class_name => 'Thank', :dependent => :destroy
  end

  def thankable?
    true
  end

end