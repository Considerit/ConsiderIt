class NotJSON
  # This match function returns true iff the request is not json
  def matches?(request)
    json_header = request.format.to_s.include?('application/json')
    json_query_param = (request.query_parameters.has_key?('json') \
                        or request.query_parameters.has_key?('JSON'))
    not (json_query_param or json_header)
  end
end

ConsiderIt::Application.routes.draw do

  # All user-visible URLs go to the "home" controller, which serves an
  # html page, and then the required data will be fetched afterward in JSON
  get '(*url)' => 'home#index', :constraints => NotJSON.new

  # mount RailsAdmin::Engine => '/dashboard/database', :as => 'rails_admin'

  # MIKE SAYS: not sure where to put this.  Is it JSON or what?
  devise_for :users, skip: [:registrations, :sessions, :passwords], controllers: {:omniauth_callbacks => 'current_user'}
  devise_scope :user do  
    get "/content_for_user" => "current_user#content_for_user", :as => :content_for_user
    get "users/check_login_info" => "current_user#check_login_info"
    post "/users/set_tag" => "current_user#set_tag", :as => :set_tag
    post "/send_password_reset_token" => "current_user#send_password_reset_token"
    resource :current_user, controller: 'current_user', only: [:show, :create, :update, :destroy]
  end


  # Here's the entire JSON API:
  resources :proposal
  resources :point, :only => [:create, :update, :destroy, :show]
  resources :point_discussion, :only => [:create, :update, :destroy, :show]
  resources :opinion, :only => [:update, :create, :show]
  resources :inclusion, :path => 'inclusion/:point_id', :only => [:create]
  match 'inclusion/:point_id' => 'inclusion#destroy', :via => :delete

  ##### Mike doesn't know what to do with the rest of this yet #####

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
    resources :commentable, :only => [:create, :update]
  end

  concern :followable do 
    get "followable_index" => 'followable#index', :as => 'followable_index'
    match "follow" => 'followable#follow', :via => :post
    #match "unfollow" => 'followable#unfollow'
    match "unfollow" => 'followable#unfollow', :via => :post
  end

  concern :thankable do 
    resources :thankable, :only => [:create, :destroy]
  end

  concerns :moderatable
  concerns :assessable
  concerns :commentable
  concerns :followable
  concerns :thankable
  #################



  scope :module => "dashboard" do
    match "/report_client_error" => "client_errors#create", :via => :post, :as => :report_client_error
    get "/dashboard/client_errors" => "client_errors#index", :as => :client_error

    resource :account, :only => [:show, :update]

    get '/dashboard/application' => "accounts#show"
    post '/dashboard/application' => "accounts#update"

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



  # route all non-ajax requests to home controller, with a few exceptions
  get '(*url)' => 'home#index', :constraints => XHRConstraint.new 


  
  get "/feed" => "trackable#feed"

  #match "/theme" => "theme#set", :via => :post
  get '/home/avatars' => "home#avatars", :as => :get_avatars
  match "/home/domain" => "home#set_domain", :via => :post
  match "/home/theme" => "home#set_dev_options", :via => :post, :as => :set_dev_options

  match '/dashboard/message' => 'message#create', :as => 'message', :via => :post

  #match '/home/study/:category' => "home#study", :via => :post  

  #get '/:admin_id' => 'proposals#show', :admin_id => /[a-z]\d{12}/


end
