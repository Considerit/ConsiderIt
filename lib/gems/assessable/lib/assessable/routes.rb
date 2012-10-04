# encoding: utf-8
module Assessable
  module Routes

    def assessable_routes
      
      match "assess/create" => 'assessable::assessable#create', :via => :get
      match "assess/claim/create" => 'assessable::claims#create', :via => :get
      match "assess" => 'assessable::assessable#index'
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Assessable::Routes

  end
end