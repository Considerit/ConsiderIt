# encoding: utf-8
module Moderatable
  module Routes

    def moderatable_routes
      
      match "moderate/create" => 'moderatable::moderatable#create', :via => :get
      match "moderate" => 'moderatable::moderatable#index'
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Moderatable::Routes

  end
end