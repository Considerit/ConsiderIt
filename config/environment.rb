# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ConsiderIt::Application.initialize! do |config|
  config.serve_static_assets = true    
end

if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
end
