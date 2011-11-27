module Commentable
  def is_commentable
    has_many :comments, :as=>:commentable, :dependent=>:destroy
    include InstanceMethods
  end
  module InstanceMethods
    def commentable?
      true
    end
  end
end
ActiveRecord::Base.extend Commentable
