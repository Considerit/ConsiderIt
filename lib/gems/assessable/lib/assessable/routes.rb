# encoding: utf-8
module Assessable
  module Routes

    def assessable_routes
      # user facing
      resources :assessment, :controller => "assessable::assessable", :only => [:index, :create, :edit, :update] do 
        match "claim/create" => 'assessable::assessable#create_claim', :via => :post, :as => 'create_claim'
        match "claim/:id/update" => 'assessable::assessable#update_claim', :via => :put, :as => 'update_claim'
      end

    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Assessable::Routes

  end
end