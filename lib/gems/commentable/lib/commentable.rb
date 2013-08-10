module Commentable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class CommentableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
  end

  module Commentable
    def is_commentable
      has_many :comments, :as=>:commentable, :class_name => 'Comment', :dependent=>:destroy
      include InstanceMethods
    end
    module InstanceMethods
      def commentable?
        true
      end
    end
  end

end

ActiveRecord::Base.extend Commentable::Commentable
require 'commentable/routes'