

module Assessable
  module Routes

    def assessable_routes
      # user facing
      
      resources :assessment, :path => "dashboard/assessment", :controller => "dashboard::assessable", :only => [:index, :create, :edit, :update] do 
        match "claims" => 'dashboard::assessable#create_claim', :via => :post, :as => 'create_claim'
        match "claim/:id" => 'dashboard::assessable#update_claim', :via => :put, :as => 'update_claim'
        match "claim/:id" => 'dashboard::assessable#destroy_claim', :via => :delete, :as => 'destroy_claim'
      end

    end

  end
end

module ActionDispatch::Routing
  class Mapper #:nodoc:

    include Assessable::Routes

  end
end