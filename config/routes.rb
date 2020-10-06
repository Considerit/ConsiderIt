class NotJSON
  # This match function returns true iff the request is not json
  def matches?(request)
    json_header = request.format.to_s.include?('application/json')
    json_query_param = (request.query_parameters.has_key?('json') \
                        or request.query_parameters.has_key?('JSON'))
    not (json_query_param or json_header)
  end
end

class IsSAMLRoute
  def matches?(request)
    request.subdomain.downcase == 'saml-auth'
  end 
end

ConsiderIt::Application.routes.draw do

  if Rails.env.development?  
    get '/rails/mailers' => "rails/mailers#index"
    get '/rails/mailers/*path'   => "rails/mailers#preview"
  end

  ######
  ## Development dashboard
  get '/change_subdomain/:id' => 'developer#change_subdomain'


  get '/proposal/:id/copy_to/:subdomain_id' => 'proposal#copy_to_subdomain'
  get '/oembed(.:format)' => 'oembed#show'
  get '/embed/proposal/:slug' => 'oembed#proposal_embed', :constraints => NotJSON.new

  get "/dashboard/export(.:format)" => 'import_data#export'

  get "/create_subdomain" => 'subdomain#create'
  post '/subdomain' => 'subdomain#create'

  get "/login_via_saml" => 'current_user#login_via_saml'

  # SAML for Development
  get 'saml/sso/:sso_idp/:subdomain' => 'saml#sso', :constraints => IsSAMLRoute.new 
  post 'saml/acs' => 'saml#acs', :constraints => IsSAMLRoute.new 
  get 'saml/metadata' => 'saml#metadata', :constraints => IsSAMLRoute.new 

  # All user-visible URLs go to the html controller, which serves an
  # html page, and then the required data will be fetched afterward in JSON
  get '(*url)' => 'html#index', :constraints => NotJSON.new

  get '/page' => 'page#show'
  get '/page/*id' => 'page#show'
  resources :user, :only => [:show]
  get '/users' => 'user#index'
  match '/user/:id' => 'user#update', :via => [:put]

  resources :proposal
  get '/proposals' => 'proposal#index'
  get '/all_comments' => 'comment#all_for_subdomain'

  resources :point, :only => [:create, :update, :destroy, :show]
  resources :opinion, :only => [:update, :show]
  resources :client_error, :only => [:create]
  match '/histogram/proposal/:id/:hash' => 'histogram#update', :via => [:put]

  resources :comment, :only => [:create, :show, :update, :destroy]
  get '/comments/:point_id' => 'comment#index'

  get '/application' => 'application#application'

  get '/subdomain' => 'subdomain#show'
  get '/subdomain/:id' => 'subdomain#show'

  
  match '/subdomain' => 'subdomain#update', :via => [:put]
  get '/subdomains' => 'subdomain#index'

  get '/translations' => 'translations#show'
  get '/translations/*subdomain' => 'translations#show'
  match '/translations' => 'translations#update', :via => [:put]
  match '/translations/*subdomain' => 'translations#update', :via => [:put]

  match '/notification/:notification_id' => 'notification#update', :via => [:put]
  get '/notifications/:proposal_id' => 'notification#index'


  match 'update_images_hack' => 'subdomain#update_images_hack', :via => [:put]

  post '/log' => 'log#create'

  # These next ones are done with "match" because "resources" was
  # being all "I need an id like "/current_user/234" and I don't know
  # how to tell it to be like "/current_user"
  get 'current_user' => 'current_user#show'
  match 'current_user' => 'current_user#update', :via => [:put]

  # This is for the special /opinion/current_user/234:
  match 'opinion/:id/:proposal_id' => 'opinion#show', :via => [:get, :put]

  # New admin functionality

  get '/moderation/:id' => 'moderation#show'

  match "/moderation/:id" => 'moderation#update', :via => :put
  post '/dashboard/message' => 'direct_message#create', :as => 'message'

  get 'user_avatar_hack' => 'current_user#user_avatar_hack'
  match 'update_user_avatar_hack' => 'current_user#update_user_avatar_hack', :via => [:put]

  post "/dashboard/data_import_export" => 'import_data#create'



end
