ConsiderIt::Application.routes.draw do
    
  resources :point_links

  root :to => "home#index"

  resources :proposals, :only => [:index, :create]
  resource :proposal, :path => '/:long_id/results', :long_id => /[a-z\d]{10}/, :only => [:show, :edit, :update, :destroy]
  resource :proposal, :path => '/:long_id', :long_id => /[a-z\d]{10}/, :only => [], :path_names => {:show => 'results'} do
    resources :positions, :path => '', :only => [:new, :edit, :create, :update, :destroy], :path_names => {:new => ''}
    resources :points, :only => [:index, :create, :update, :destroy, :show] do 
      resources :inclusions, :only => [:create] 
    end
    #resources :point_similarities, :module => :admin
    resources :comments, :only => [:index, :create]
  end

  
  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations",
    :passwords => "users/passwords",
    :confirmations => "users/confirmations"
  } do 
    match "users/check_login_info" => "users/registrations#check_login_info", :via => :post
  end

  themes_for_rails # themes_for_rails gem routes 

  match "/feed" => "activities#feed"

  #match "/theme" => "theme#set", :via => :post
  match "/home/domain" => "home#set_domain", :via => :post
  match '/home/:page' => "home#show", :via => :get, :constraints => { :page => /terms-of-use|considerit|media|videos|help/ } 

  match '/home/study/:category' => "home#study", :via => :post  
  match '/admin/dashboard' => "admin/dashboard#index", :via => :get, :module => :admin  

  namespace :reflect do
    match "/data" => "reflect_bullet#index", :via => :get
    match "/bullet_new" => 'reflect_bullet#create', :via => :post
    match "/bullet_update" => 'reflect_bullet#update', :via => :post
    match "/bullet_delete" => 'reflect_bullet#destroy', :via => :post
    match "/response_new" => 'reflect_response#create', :via => :post
    match "/response_update" => 'reflect_response#update', :via => :post
    match "/response_delete" => 'reflect_response#destroy', :via => :post              
  end

  ActiveAdmin.routes(self)



  match '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
