# encoding: utf-8
module Thankable
  module Routes

    def thankable_routes
      resources :thanks, :only => [:create, :destroy]
    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Thankable::Routes

  end
end