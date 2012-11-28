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
    match '/positions/:user_id' => "positions#show", :as => :user_position
    resources :points, :only => [:index, :create, :update, :destroy, :show] do 
      resources :inclusions, :only => [:create] 
    end
    #resources :point_similarities, :module => :admin
    
  end

  resource :account, :only => [:update]

  
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

  #match '/home/study/:category' => "home#study", :via => :post  
  scope :module => "dashboard" do
    match '/dashboard/application' => "admin#application", :via => :get, :as => :application_settings
    match '/dashboard/analytics' => "admin#analytics", :via => :get, :as => :analytics
    match '/dashboard/proposals' => "admin#proposals", :via => :get, :as => :manage_proposals
    match '/dashboard/roles' => "admin#roles", :via => :get, :as => :manage_roles
    match '/dashboard/roles/users/:user_id' => "admin#update_role", :via => :post, :as => :update_role
    match '/dashboard/users/:id/profile' => "users#show", :as => :profile
    match '/dashboard/users/:id/profile/edit' => "users#edit", :as => :edit_profile
    match '/dashboard/users/:id/profile/edit/account' => "users#edit_account", :as => :edit_account
    match '/dashboard/users/:id/profile/edit/notifications' => "users#edit_notifications", :as => :edit_notifications

  end

  match '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
