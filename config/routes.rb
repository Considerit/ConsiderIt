ConsiderIt::Application.routes.draw do
  root :to => "home#index"
  
  resources :options, :only => [:show] do
    resources :points do
      
    end
  end
  
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks", :sessions => "users/sessions", :registrations => "users/registrations" }
end
