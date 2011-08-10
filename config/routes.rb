ConsiderIt::Application.routes.draw do
  
  root :to => "home#index"
  
  resources :options, :only => [:show] do
    resources :positions, :only => [:new, :edit, :create, :update, :show]
    resources :points, :only => [:index, :create] do 
      resources :inclusions, :only => [:create, :destroy] 
    end
    resources :point_similarities, :module => :admin
    resources :comments, :only => [:index, :create]
  end
  

  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations" 
  }

  themes_for_rails # themes_for_rails gem routes 
  
  match "/theme" => "theme#set", :via => :post
  
end
