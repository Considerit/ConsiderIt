require "omniauth-google-oauth2"
require "omniauth-facebook" 
require "omniauth-twitter" 


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
  if host.length > 2
    subdomain = host[0]
    host = host[host.length-2..host.length-1]
  end
  host = host.join('.').intern

  if !conf[:domain].has_key?(host)
    raise "#{host} is not a configured host for third party authentication."
  elsif !conf[:domain][host].has_key?(provider)
    raise "#{provider} is not configured for host #{host}."
  end
  
  settings = conf[:domain][host][provider]
  env['omniauth.strategy'].options[key] = settings[:consumer_key]
  env['omniauth.strategy'].options[secret] = settings[:consumer_secret]

  # In order to support wildcard subdomains without manually 
  # entering all valid subdomains into google dev console, 
  # we have an auth tenant that simply acts as a recipient
  # of google auth requests, redirecting to the proper 
  # subdomain. 

  # Note that the provider_ignores_state option is insecure, leaving open the possibility of a CSRF attack. 
  # We use it because OmniAuth uses the state param to roundtrip a CSRF token, but we need to use the state variable for
  # roundtripping the origin subdomain
  # Some relevant discussions:
  #   - https://github.com/intridea/omniauth-oauth2/pull/18/files; https://github.com/zquestz/omniauth-google-oauth2/issues/31#issuecomment-8922362
  #   - https://github.com/intridea/omniauth-oauth2/issues/32

  if env['omniauth.strategy'].name() == 'google_oauth2' && Rails.env.production? && subdomain
    env['omniauth.strategy'].options['state'] = subdomain
    env['omniauth.strategy'].options['redirect_uri'] = "#{request.scheme}://googleoauth.#{host}/auth/google_oauth2/callback"
  end
end



Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, :setup => OAUTH_SETUP_PROC, :scope => 'email', :client_options => {:ssl => {:ca_path => '/etc/ssl/certs'}}
  provider :twitter, :setup => OAUTH_SETUP_PROC


  provider :google_oauth2, :setup => OAUTH_SETUP_PROC, :client_options => { :provider_ignores_state => true, :access_type => "offline", :approval_prompt => "", :scope => 'email,profile'}
end






