# encoding: utf-8
module Moderatable
  module Routes

    def moderatable_routes
      match "/dashboard/moderate/create" => 'dashboard::moderatable#create', :via => :post
      match "/dashboard/moderate" => 'dashboard::moderatable#index'
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Moderatable::Routes

  end
end