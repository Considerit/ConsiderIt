# Load the rails application
require File.expand_path('../application', __FILE__)
require File.join(File.dirname(__FILE__), 'environment_custom')

# Initialize the rails application
ConsiderIt::Application.initialize!
