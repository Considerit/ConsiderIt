require "omniauth-google-oauth2"
require "omniauth-facebook" 
# require "omniauth-twitter" 

OAUTH_SETUP_PROC = lambda do |env|
  case env['omniauth.strategy'].name()
  when 'google_oauth2'
    provider = :google
  else
    provider = env['omniauth.strategy'].name().intern
  end

  case provider
  when :twitter
    key = :consumer_key
    secret = :consumer_secret
  else
    key = :client_id
    secret = :client_secret
  end      

  conf = load_local_environment()

  request = Rack::Request.new(env)
  host = request.host.split('.')
  subdomain = nil
  if host.length == 3
    subdomain = host[0]
  end
  if host.length > 2
    host = host[host.length-2..host.length-1]
  end
  host = host.join('.').intern

  provider_key = "oauth_#{provider}_client".intern
  provider_secret = "oauth_#{provider}_secret".intern

  if !conf.has_key?(provider_key) || !conf.has_key?(provider_secret)
    raise "#{host} is not a configured host for third party authentication with #{provider}."
  end


  env['omniauth.strategy'].options[key] = conf[provider_key]
  env['omniauth.strategy'].options[secret] = conf[provider_secret]

  # In order to support wildcard subdomains without manually 
  # entering all valid subdomains into google dev console, 
  # we have a reverse proxied subdomain (oauth-callback) that simply acts as a recipient
  # of google auth requests. 

  # Note that the provider_ignores_state option below is insecure, leaving open the possibility of a CSRF attack. 
  # We use it because OmniAuth uses the state param to roundtrip a CSRF token, but we need to use the state variable for
  # roundtripping the origin subdomain.
  # Some relevant discussions:
  #   - https://github.com/intridea/omniauth-oauth2/pull/18/files; https://github.com/zquestz/omniauth-google-oauth2/issues/31#issuecomment-8922362
  #   - https://github.com/intridea/omniauth-oauth2/issues/32

  if Rails.env.production? && subdomain
    redirect_domain = APP_CONFIG[:oauth_callback_subdomain]
    if APP_CONFIG[:product_page] && APP_CONFIG[:product_page] != 'homepage'
      redirect_domain += ".#{APP_CONFIG[:product_page]}"
    end
    env['omniauth.strategy'].options['state'] = subdomain
    env['omniauth.strategy'].options['redirect_uri'] = "#{request.scheme}://#{redirect_domain}.#{host}/auth/#{env['omniauth.strategy'].name()}/callback"
  end
end

OMNIAUTH_SETUP_PROC = lambda do |env|

  request = Rack::Request.new(env)
  host = request.host.split('.')
  subdomain = nil
  if host.length == 3
    subdomain = host[0]
  end
  if host.length > 2
    host = host[host.length-2..host.length-1]
  end
  host = host.join('.').intern

  if Rails.env.production? && subdomain
    "#{request.scheme}://#{APP_CONFIG[:oauth_callback_subdomain]}.#{host}"
  else 
    "#{request.scheme}://#{request.host_with_port}"
  end

end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, :setup => OAUTH_SETUP_PROC, :scope => 'email', :display => 'popup', :image_size => 'large' #, :client_options => {:ssl => {:ca_path => '/etc/ssl/certs'}}
  # provider :twitter, :setup => OAUTH_SETUP_PROC

  provider :google_oauth2, :setup => OAUTH_SETUP_PROC, :provider_ignores_state => true, :client_options => { :access_type => "offline", :prompt => "", :scope => 'email,profile'}
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.full_host = OMNIAUTH_SETUP_PROC
