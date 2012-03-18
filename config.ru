# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if ENV.has_key?('RAILS_RELATIVE_URL_ROOT') && ENV['RAILS_RELATIVE_URL_ROOT'] != ''
  map '/' + ENV['RAILS_RELATIVE_URL_ROOT'] do 
    run ConsiderIt::Application
  end
else
  run ConsiderIt::Application
end