ConsiderIt::Application.routes.draw do
  
  resources :point_links

  root :to => "home#index"
  
  resources :options, :only => [:show, :index] do
    resources :positions, :only => [:new, :edit, :create, :update, :show, :destroy]
    resources :points, :only => [:index, :create, :update, :destroy] do 
      resources :inclusions, :only => [:create] 
    end
    resources :point_similarities, :module => :admin
    resources :comments, :only => [:index, :create]
  end


  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations",
    :passwords => "users/passwords",
    :confirmations => "users/confirmations"
  }

  themes_for_rails # themes_for_rails gem routes 

  match "/theme" => "theme#set", :via => :post
  match "/home/domain" => "home#set_domain", :via => :post
  match "/home/pledge" => "home#take_pledge", :via => :post
  match '/home/:page' => "home#show", :via => :get, :constraints => { :page => /terms-of-use|considerit|media|help/ } 

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
  

end
