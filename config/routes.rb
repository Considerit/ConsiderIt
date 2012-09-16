#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

ConsiderIt::Application.routes.draw do
    
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  root :to => "home#index"

  match "/follow" => "accounts#follow"
  match "/unfollow" => "accounts#unfollow"

  resources :proposals, :only => [:index, :create]
  resource :proposal, :path => '/:long_id/results', :long_id => /[a-z\d]{10}/, :only => [:show, :edit, :update, :destroy] do
  end
  resource :proposal, :path => '/:long_id', :long_id => /[a-z\d]{10}/, :only => [], :path_names => {:show => 'results'} do
    member do
      get 'follow'
      get 'unfollow'
    end

    resources :positions, :path => '', :only => [:new, :edit, :create, :update, :destroy], :path_names => {:new => ''} do 
      member do
        get 'follow'
        get 'unfollow'
      end
    end
    resources :points, :only => [:index, :create, :update, :destroy, :show] do 
      member do
        get 'follow' 
        get 'unfollow'
      end
      resources :inclusions, :only => [:create] 
    end
    #resources :point_similarities, :module => :admin
    resources :comments, :only => [:index, :create] do 
      member do
        get 'follow'
        get 'unfollow'
      end
    end
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

  themes_for_rails # themes_for_rails gem routes 

  match "/feed" => "activities#feed"

  #match "/theme" => "theme#set", :via => :post
  match "/home/domain" => "home#set_domain", :via => :post
  match '/home/:page' => "home#show", :via => :get, :constraints => { :page => /terms-of-use|considerit|media|videos|help/ } 

  match '/home/study/:category' => "home#study", :via => :post  
  #match '/admin' => "admin/dashboard#index", :via => :get, :module => :admin  

  #ActiveAdmin.routes(self)
   # Feel free to change '/admin' to any namespace you need.


  match '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
