# encoding: utf-8
module Followable
  module Routes

    def followable_routes
      get "followable_index" => 'followable/followable#index', :as => 'followable_index'
      get "follow" => 'followable/followable#follow'
      #match "unfollow" => 'followable::followable#unfollow'
      match "unfollow" => 'followable/followable#unfollow', :via => :post
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Followable::Routes

  end
end