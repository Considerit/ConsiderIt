ConsiderIt::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.colorize_logging = true


  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.perform_deliveries = true 

  # config.action_mailer.delivery_method = :file
  # config.action_mailer.file_settings = { :location => Rails.root.join('tmp/mail') }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { :address => '127.0.0.1', :port => 1025 }
  config.action_mailer.raise_delivery_errors = false




  # Automatically inject JavaScript needed for LiveReload
  # config.middleware.insert_after(ActionDispatch::Static, Rack::LiveReload)
  
  #Paperclip.options[:command_path] = "/usr/local/bin/"


end  

