# encoding: utf-8
module Commentable
  module Routes

    def commentable_routes
      resources :comment, :only => [:create, :update]
      # match 'comments' => 'commentable/comments#create', :via => :post
      # match 'comment/:id/update' => 'commentable/comments#update', :via => :put, :as => 'update_comment'
      # match 'comment/:id' => 'commentable/comments#show', :via => :get, :as => 'show_comment'

    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Commentable::Routes

  end
end