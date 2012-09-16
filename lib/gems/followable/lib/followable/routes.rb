# encoding: utf-8
module Followable
  module Routes

    def followable_routes
      
      match "follow" => 'followable::followable#follow'
      match "unfollow" => 'followable::followable#unfollow'
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Followable::Routes

  end
end