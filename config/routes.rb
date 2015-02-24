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

  if Rails.env.development?

    ## Test controller for nonactiverest
    get '/activemike' => 'html#activemike'
  
    get '/rails/mailers' => "rails/mailers#index"
    get '/rails/mailers/*path'   => "rails/mailers#preview"
  end

  ## Development dashboard; right now it lets you easily switch between subdomains
  get '/change_subdomain/:id' => 'developer#change_default_subdomain', :as => 'change_subdomain'

  # All user-visible URLs go to the html controller, which serves an
  # html page, and then the required data will be fetched afterward in JSON
  get '(*url)' => 'html#index', :constraints => NotJSON.new

  # Here's the entire JSON API:
  get '/page' => 'page#show'
  get '/page/*id' => 'page#show'
  resources :user, :only => [:show]
  get '/users' => 'user#index'
  resources :proposal
  get '/proposals' => 'proposal#index'
  resources :point, :only => [:create, :update, :destroy, :show]
  resources :opinion, :only => [:update, :show]
  resources :client_error, :only => [:create]
  resources :histogram, :only => [:update, :show]

  resources :comment, :only => [:create, :show, :update, :destroy]
  get '/comments/:point_id' => 'comment#index'

  get '/subdomain' => 'subdomain#show'
  post '/subdomain' => 'subdomain#create'
  match '/subdomain' => 'subdomain#update', :via => [:put]

  match 'update_images_hack' => 'subdomain#update_images_hack', :via => [:put]

  post '/log' => 'log#create'

  # These next ones are done with "match" because "resources" was
  # being all "I need an id like "/current_user/234" and I don't know
  # how to tell it to be like "/current_user"
  get 'current_user' => 'current_user#show'
  match 'current_user' => 'current_user#update', :via => [:put]

  get '/avatars' => "user#avatars"

  # This is for the special /opinion/current_user/234:
  match 'opinion/:id/:proposal_id' => 'opinion#show', :via => [:get, :put]

  # New admin functionality
  resources :assessment, :only => [:show, :update]
  resources :claim, :only => [:show, :create, :update, :destroy]
  resources :request, :only => [:create], :controller => "assessment"

  match "/moderation/:id" => 'moderation#update', :via => :put
  post '/dashboard/message' => 'direct_message#create', :as => 'message'

  get 'user_avatar_hack' => 'current_user#user_avatar_hack'
  match 'update_user_avatar_hack' => 'current_user#update_user_avatar_hack', :via => [:put]

  post "/dashboard/import_data" => 'import_data#create'

end
