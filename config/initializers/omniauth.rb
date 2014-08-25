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
  if host.length > 2
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

end



Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, :setup => OAUTH_SETUP_PROC, :scope => 'email', :client_options => {:ssl => {:ca_path => '/etc/ssl/certs'}}
  provider :twitter, :setup => OAUTH_SETUP_PROC
  provider :google_oauth2, :setup => OAUTH_SETUP_PROC, :client_options => { :access_type => "offline", :approval_prompt => "", :scope => 'userinfo.email,userinfo.profile' }
end






