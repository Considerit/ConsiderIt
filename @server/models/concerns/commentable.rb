module Commentable
  extend ActiveSupport::Concern

  included do 
    has_many :comments, :as=>:commentable, :class_name => 'Comment', :dependent=>:destroy
  end

  def commentable?
    true
  end

end