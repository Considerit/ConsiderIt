ConsiderIt::Application.routes.draw do
  root :to => "home#index"
  
  resources :options, :only => [:show] do
    resources :positions, :only => [:new, :edit, :create, :update, :show]
    
    resources :points, :only => [:index, :create] do 
      resources :inclusions, :only => [:create, :destroy] 
    end
  end
  
  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations" 
  }
  
end
