# encoding: utf-8
module Followable
  module Routes

    def followable_routes
      
      match "follow" => 'followable::followable#follow'
      match "unfollow" => 'followable::followable#unfollow'
      match "unfollow_create" => 'followable::followable#unfollow_create', :via => :post
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Followable::Routes

  end
end