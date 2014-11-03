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

  ## This is my test controller for nonactiverest
  get '/activemike' => 'home#activemike'

  ## This stuff at the top is all special cases until we make
  ## EVERYTHING client-side via the home controller's index!
  scope :module => "dashboard" do
    match "/report_client_error" => "client_errors#create", :via => :post, :as => :report_client_error
    get "/dashboard/client_errors" => "client_errors#index", :as => :client_error

    get '/dashboard/admin_template' => "admin#admin_template", :as => :admin_template
    #match '/dashboard/application' => "admin#application", :via => :get, :as => :application_settings
    get '/dashboard/analytics' => "admin#analytics", :as => :analytics
    get '/dashboard/import_data' => "admin#import_data", :as => :import_data
    match '/dashboard/import_data' => "admin#import_data_create", :via => :put, :as => :import_data_create

    #match '/dashboard/proposals' => "admin#proposals", :via => :get, :as => :manage_proposals
    # get '/dashboard/roles' => "admin#roles", :as => :manage_roles
    # match '/dashboard/roles/users/:user_id' => "admin#update_role", :via => :post, :as => :update_role
    get '/dashboard/users/:id/profile' => "users#show", :as => :profile
    get '/dashboard/users/:id/profile/edit' => "users#edit", :as => :edit_profile
    get '/dashboard/users/:id/profile/edit/account' => "users#edit_account", :as => :edit_account
    get '/dashboard/users/:id/profile/edit/notifications' => "users#edit_notifications", :as => :edit_notifications

  end

  get '/avatars' => "home#avatars", :as => :get_avatars

  concern :followable do 
    get "followable_index" => 'followable#index', :as => 'followable_index'
    match "follow" => 'followable#follow', :via => :post
    match "unfollow" => 'followable#unfollow', :via => :post
  end
  concerns :followable


  # MIKE SAYS: not sure where to put this.  Is it JSON or what?
  # TRAVIS SAYS: The only routes generated here regard third party oauth. It is important
  #              to put this before the home controller non-AJAX catch all because 
  #              OAUTH stipulates that the third party submit a non-ajax
  #              GET back to the server with the user data. This must be handled by
  #              CurrentUserController#third_party_callback.

  match "/auth/:provider",
    constraints: { provider: /google_oauth2|facebook|twitter/},
    to: "current_user#passthru",
    as: :user_omniauth_authorize,
    via: [:get, :post]

  match "/auth/:action/callback",
    constraints: { action: /google_oauth2|facebook|twitter/ },
    to: "current_user#update_via_third_party",
    as: :user_omniauth_callback,
    via: [:get, :post]

  # All user-visible URLs go to the "home" controller, which serves an
  # html page, and then the required data will be fetched afterward in JSON
  get '(*url)' => 'home#index', :constraints => NotJSON.new

  # Here's the entire JSON API:
  resources :page, :only => [:show]
  resources :user, :only => [:show]
  get '/users' => 'user#index'
  resources :proposal
  get '/proposals' => 'proposal#index'
  resources :point, :only => [:create, :update, :destroy, :show]
  resources :opinion, :only => [:update, :show]
  resources :client_error, :only => [:create]

  resources :comment, :only => [:create, :show, :update, :destroy]
  get '/comments/:point_id' => 'comment#index'

  post '/log' => 'log#create'
  get '/customer' => 'customer#show'
  match '/customer' => 'customer#update', :via => [:put]


  # These next ones are done with "match" because "resources" was
  # being all "I need an id like "/current_user/234" and I don't know
  # how to tell it to be like "/current_user"
  get 'current_user' => 'current_user#show'
  match 'current_user' => 'current_user#update', :via => [:put]

  # This is for the special /opinion/current_user/234:
  match 'opinion/:id/:proposal_id' => 'opinion#show', :via => [:get, :put]

  # New admin functionality
  get 'dashboard/assessment' => 'assessment#index'
  resources :assessment, :only => [:show, :update]
  resources :claim, :only => [:show, :create, :update, :destroy]
  resources :request, :only => [:create], :controller => "assessment"

  get "/dashboard/moderate" => 'moderation#index'
  match "/moderation/:id" => 'moderation#update', :via => :put
  post '/dashboard/message' => 'message#create', :as => 'message'

  get 'user_avatar_hack' => 'current_user#user_avatar_hack'
  match 'update_user_avatar_hack' => 'current_user#update_user_avatar_hack', :via => [:put]

end
