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
  resource :proposal, :path => '/:long_id/results', :long_id => /[a-zA-Z\d_]{10}/, :only => [:show, :edit, :update, :destroy]
  resource :proposal, :path => '/:long_id', :long_id => /[a-zA-Z\d_]{10}/, :only => [], :path_names => {:show => 'results'} do
    get '/' => "proposals#show" , :as => :new_position

    resources :positions, :path => '', :only => [:update, :create], :path_names => {:new => ''} 

    get '/positions/:user_id' => "positions#show", :as => :user_position

    resources :points, :only => [:create, :update, :destroy, :show]
  end


  # route all non-ajax requests to home controller, with a few exceptions
  get '(*url)' => 'home#index', :constraints => XHRConstraint.new

  themes_for_rails 


  ######
  ## concerns routes
  concern :moderatable do 
    match "/dashboard/moderate/create" => 'dashboard/moderatable#create', :via => :post
    get "/dashboard/moderate" => 'dashboard/moderatable#index'
  end

  concern :assessable do 
    resources :assessment, :path => "dashboard/assessment", :controller => "dashboard/assessable", :only => [:index, :create, :edit, :update] do 
      match "claims" => 'dashboard/assessable#create_claim', :via => :post, :as => 'create_claim'
      match "claim/:id" => 'dashboard/assessable#update_claim', :via => :put, :as => 'update_claim'
      match "claim/:id" => 'dashboard/assessable#destroy_claim', :via => :delete, :as => 'destroy_claim'
    end
  end

  concern :commentable do 
    resources :comment, :only => [:create, :update]
  end

  concern :followable do 
    get "followable_index" => 'followable#index', :as => 'followable_index'
    match "follow" => 'followable#follow', :via => :post
    #match "unfollow" => 'followable#unfollow'
    match "unfollow" => 'followable#unfollow', :via => :post
  end

  concern :thankable do 
    resources :thanks, :only => [:create, :destroy]
  end

  concerns :moderatable
  concerns :assessable
  concerns :commentable
  concerns :followable
  concerns :thankable
  #################

  devise_scope :user do 
    get "users/check_login_info" => "users/registrations#check_login_info"
  end

  get "/content_for_user" => "home#content_for_user", :as => :content_for_user
  match "/users/set_tag" => "home#set_tag", :via => :post, :as => :set_tag

  resource :account, :only => [:show, :update]
  
  get "/feed" => "activities#feed"

  #match "/theme" => "theme#set", :via => :post
  get '/home/avatars' => "home#avatars", :as => :get_avatars
  match "/home/domain" => "home#set_domain", :via => :post
  match "/home/theme" => "home#set_dev_options", :via => :post, :as => :set_dev_options

  match '/dashboard/message' => 'message#create', :as => 'message', :via => :post

  #match '/home/study/:category' => "home#study", :via => :post  
  scope :module => "dashboard" do
    match "/report_client_error" => "client_errors#create", :via => :post, :as => :report_client_error
    get "/dashboard/client_errors" => "client_errors#index", :as => :client_error

    get '/dashboard/admin_template' => "admin#admin_template", :as => :admin_template
    #match '/dashboard/application' => "admin#application", :via => :get, :as => :application_settings
    get '/dashboard/analytics' => "admin#analytics", :as => :analytics
    get '/dashboard/import_data' => "admin#import_data", :as => :import_data
    match '/dashboard/import_data' => "admin#import_data_create", :via => :put, :as => :import_data_create

    #match '/dashboard/proposals' => "admin#proposals", :via => :get, :as => :manage_proposals
    get '/dashboard/roles' => "admin#roles", :as => :manage_roles
    match '/dashboard/roles/users/:user_id' => "admin#update_role", :via => :post, :as => :update_role
    get '/dashboard/users/:id/profile' => "users#show", :as => :profile
    get '/dashboard/users/:id/profile/edit' => "users#edit", :as => :edit_profile
    get '/dashboard/users/:id/profile/edit/account' => "users#edit_account", :as => :edit_account
    get '/dashboard/users/:id/profile/edit/notifications' => "users#edit_notifications", :as => :edit_notifications

  end

  #get '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
