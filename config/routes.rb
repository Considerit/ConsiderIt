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

  # Third party oauth routes. These go before 
  # the home controller non-json catch all because 
  # oauth submits an HTML GET request back to the server 
  # with the user data, which is handled by 
  # CurrentUserController#third_party_callback.
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

  get '/customer' => 'customer#show'
  post '/customer' => 'customer#create'
  match '/customer' => 'customer#update', :via => [:put]
  get '/dashboard/create_subdomain' => 'customer#new'

  post '/log' => 'log#create'

  # These next ones are done with "match" because "resources" was
  # being all "I need an id like "/current_user/234" and I don't know
  # how to tell it to be like "/current_user"
  get 'current_user' => 'current_user#show'
  match 'current_user' => 'current_user#update', :via => [:put]

  get '/avatars' => "home#avatars"

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

  get "/dashboard/email_notifications" => 'followable#index'
  post "follow" => 'followable#follow'
  post "unfollow" => 'followable#unfollow'

  post "/dashboard/import_data" => 'import_data#create'

end
