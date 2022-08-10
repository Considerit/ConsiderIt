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
  get '/change_subdomain/:name' => 'developer#change_subdomain'

  ###########
  # Third party oauth routes. These go before 
  # the html controller non-json catch all because 
  # oauth submits an HTML GET request back to the server 
  # with the user data, which is handled by 
  # CurrentUserController#update_via_third_party.
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
  ###################

  get '/oembed(.:format)' => 'oembed#show'
  get '/embed/proposal/:slug' => 'oembed#proposal_embed', :constraints => NotJSON.new

  post "/dashboard/export(.:format)" => 'import_data#export'

  get "/create_subdomain" => 'subdomain#create'
  post '/subdomain' => 'subdomain#create'

  if APP_CONFIG[:product_page_installed]
    # Stripe payments
    get "/payments/successful" => 'product_page#stripe_successful'
    get "/payments/failed" => 'product_page#stripe_failed'  
    get "/payments/payment_intent" => 'product_page#stripe_create_payment_intent'    
    get "/payments/public_key" => 'product_page#stripe_public' 

    # legal agreements
    get "/legal/:name" => "product_page#legal"   
  end 

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
  resources :opinion, :only => [:create, :update, :show]
  resources :client_error, :only => [:create]

  resources :comment, :only => [:create, :show, :update, :destroy]
  get '/comments/:point_id' => 'comment#index'

  get '/application' => 'application#application'

  get '/subdomain' => 'subdomain#show'
  get '/subdomain/:id' => 'subdomain#show'

  match '/subdomain' => 'subdomain#update', :via => [:put]
  get '/subdomains' => 'subdomain#index'



  get '/points' => 'point#index'

  get '/translations' => 'translations#show'
  get '/translations/*subdomain' => 'translations#show'
  match '/translations' => 'translations#update', :via => [:put]
  match '/translations/*subdomain' => 'translations#update', :via => [:put]

  if APP_CONFIG[:product_page_installed]
    post "/contact_us" => 'product_page#contact'
    get '/metrics' => 'product_page#metrics'
  end

  match 'rename_forum' => 'subdomain#rename_forum', :via => [:post]
  match 'nuke_everything' => 'subdomain#nuke_everything', :via => [:put]
  match 'update_images_hack' => 'subdomain#update_images_hack', :via => [:put]
  match 'update_proposal_pic_hack' => 'proposal#update_images_hack', :via => [:put]


  post '/log' => 'log#create'

  # These next ones are done with "match" because "resources" was
  # being all "I need an id like "/current_user/234" and I don't know
  # how to tell it to be like "/current_user"
  get 'current_user' => 'current_user#show'
  match 'current_user' => 'current_user#update', :via => [:put]

  match 'current_user' => 'current_user#destroy', :via => [:delete]

  # This is for the special /opinion/current_user/234:
  match 'opinion/:id/:proposal_id' => 'opinion#show', :via => [:get, :put]

  # New admin functionality

  get '/moderation/:id' => 'moderation#show'

  match "/moderation/:id" => 'moderation#update', :via => :put

  match '/dashboard/message' => 'direct_message#create', :via => [:put]

  post "/dashboard/data_import_export" => 'import_data#create'



end
