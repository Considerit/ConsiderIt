ConsiderIt::Application.routes.draw do
  root :to => "home#index"
  
  resources :options, :only => [:show] do
    resources :positions
    
    resources :points do 
      resources :inclusions 
    end
  end
  
  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations" 
  }
  
end
