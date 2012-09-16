# encoding: utf-8
module Commentable
  module Routes

    def commentable_routes
      match '/comments' => 'commentable/comments#create', :via => :post
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Commentable::Routes

  end
end