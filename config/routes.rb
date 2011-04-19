ConsiderIt::Application.routes.draw do
  root :to => "home#index"
  
  resources :options, :only => [:show] do
    
  end
  
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks", :sessions => "users/sessions", :registrations => "users/registrations" }


end
