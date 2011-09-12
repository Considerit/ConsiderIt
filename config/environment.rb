# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ConsiderIt::Application.initialize! do |config|
  
  config.gem "jammit"
  config.serve_static_assets = true  
end
