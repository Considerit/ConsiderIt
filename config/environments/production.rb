ConsiderIt::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Compress JavaScripts and CSS
  #config.assets.compress = true
  config.assets.js_compressor = :uglifier

  config.eager_load = true
  
  # Choose the compressors to use
  # config.assets.js_compressor  = :uglifier
  # config.assets.css_compressor = :yui
   
  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false
   
  # Generate digests for assets URLs.
  config.assets.digest = true
   
  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH
   
  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  
  config.assets.precompile += %w( javascripts/load_everything browser/ie.css browser/ie9.css mailer/email.css admin.js admin/admin.css *.svg *.eot *.woff *.ttf *.jpg *.png *.jpeg *.gif)

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :dalli_store, { :expires_in => 1.day, :compress => true }

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "//#{APP_CONFIG[:aws][:cloudfront]}.cloudfront.net"

  # Enable S3/Cloudfront storage for Paperclip
  #Paperclip::Attachment.default_options.merge!({
  #  :path => "system/:attachment/:id/:style/:filename",
  #  :url => ":s3_alias_url",   
  #  :default_url => "system/default_avatar/:style_default-profile-pic.png",
  #  :storage => :s3,
  #  :bucket => APP_CONFIG[:aws][:fog_directory],
  #  :s3_host_alias => "#{APP_CONFIG[:aws][:cloudfront]}.cloudfront.net",
  #  :s3_protocol => "https",
  #  :s3_headers => {'Expires' => 1.year.from_now.httpdate},
  #  :s3_credentials => {
  #    :access_key_id => APP_CONFIG[:aws][:access_key_id],
  #    :secret_access_key => APP_CONFIG[:aws][:secret_access_key]
  #  }
  #})

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { :address => 'localhost' }
  config.action_mailer.perform_deliveries = true 
  #config.action_mailer.delivery_method = :mailhopper  

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Exception Notification
  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[ConsiderIt Error] ",
      :sender_address => '"Notifier" ',
      :exception_recipients => ['you@yourdomain.com']
    }

end
