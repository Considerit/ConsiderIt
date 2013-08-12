class XHRConstraint
  def matches?(request)
    request.format == 'text/html' && !(request.xhr? || request.url =~ /\/users\/auth/)
  end
end

ConsiderIt::Application.routes.draw do

  root :to => "home#index"

  mount RailsAdmin::Engine => '/dashboard/database', :as => 'rails_admin'
  #mount Assessable::Engine => '/dashboard/assessable', :as => 'assessable'

  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations",
    :passwords => "users/passwords",
    :confirmations => "users/confirmations"
  }

  resources :inclusions, :only => [:create] 

  resources :proposals, :only => [:index, :create]
  resource :proposal, :path => '/:long_id/results', :long_id => /[a-z\d_]{10}/, :only => [:show, :edit, :update, :destroy]
  resource :proposal, :path => '/:long_id', :long_id => /[a-z\d_]{10}/, :only => [], :path_names => {:show => 'results'} do
    match '/' => "proposals#show" , :via => :get, :as => :new_position

    resources :positions, :path => '', :only => [:update], :path_names => {:new => ''} 

    match '/positions/:user_id' => "positions#show", :as => :user_position

    resources :points, :only => [:index, :create, :update, :destroy, :show]
  end


  
  # route all non-ajax requests to home controller, with a few exceptions
  match '(*url)' => 'home#index', :constraints => XHRConstraint.new

  themes_for_rails 
  followable_routes
  commentable_routes
  moderatable_routes
  assessable_routes

  devise_scope :user do 
    match "users/check_login_info" => "users/registrations#check_login_info", :via => :post
  end
  


  match "/content_for_user" => "home#content_for_user", :as => :content_for_user

  resource :account, :only => [:show, :update]
  
  match "/feed" => "activities#feed"

  #match "/theme" => "theme#set", :via => :post
  match '/home/avatars' => "home#avatars", :via => :get, :as => :get_avatars
  match "/home/domain" => "home#set_domain", :via => :post
  match "/home/theme" => "home#set_dev_options", :via => :post, :as => :set_dev_options


  match '/home/:page' => "home#show", :via => :get, :constraints => { :page => /terms-of-use|considerit|media|videos|help|fact_check|copromoters/ } 

  match '/dashboard/message' => 'message#create', :as => 'message', :via => :post

  #match '/home/study/:category' => "home#study", :via => :post  
  scope :module => "dashboard" do
    match '/dashboard/admin_template' => "admin#admin_template", :via => :get, :as => :admin_template
    #match '/dashboard/application' => "admin#application", :via => :get, :as => :application_settings
    match '/dashboard/analytics' => "admin#analytics", :via => :get, :as => :analytics
    #match '/dashboard/proposals' => "admin#proposals", :via => :get, :as => :manage_proposals
    match '/dashboard/roles' => "admin#roles", :via => :get, :as => :manage_roles
    match '/dashboard/roles/users/:user_id' => "admin#update_role", :via => :post, :as => :update_role
    match '/dashboard/users/:id/profile' => "users#show", :as => :profile
    match '/dashboard/users/:id/profile/edit' => "users#edit", :as => :edit_profile
    match '/dashboard/users/:id/profile/edit/account' => "users#edit_account", :as => :edit_account
    match '/dashboard/users/:id/profile/edit/notifications' => "users#edit_notifications", :as => :edit_notifications

  end

  match '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
