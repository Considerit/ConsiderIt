#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

ConsiderIt::Application.routes.draw do
    
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'
  themes_for_rails 
  followable_routes
  commentable_routes
  moderatable_routes
  assessable_routes

  root :to => "home#index"

  resources :proposals, :only => [:index, :create]
  resource :proposal, :path => '/:long_id/results', :long_id => /[a-z\d_]{10}/, :only => [:show, :edit, :update, :destroy]
  resource :proposal, :path => '/:long_id', :long_id => /[a-z\d_]{10}/, :only => [], :path_names => {:show => 'results'} do

    resources :positions, :path => '', :only => [:new, :edit, :create, :update, :destroy], :path_names => {:new => ''} 
    resources :points, :only => [:index, :create, :update, :destroy, :show] do 
      resources :inclusions, :only => [:create] 
    end
    #resources :point_similarities, :module => :admin
    
  end

  
  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations",
    :passwords => "users/passwords",
    :confirmations => "users/confirmations"
  }

  devise_scope :user do 
    match "users/check_login_info" => "users/registrations#check_login_info", :via => :post
  end
  
  match "/feed" => "activities#feed"

  #match "/theme" => "theme#set", :via => :post
  match "/home/domain" => "home#set_domain", :via => :post
  match '/home/:page' => "home#show", :via => :get, :constraints => { :page => /terms-of-use|considerit|media|videos|help|fact_check|copromoters/ } 

  match '/home/study/:category' => "home#study", :via => :post  
  scope :module => "dashboard" do
    match '/dashboard/analytics' => "analytics#index", :via => :get
  end

  match '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
