require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'pp'
require './config/local_environment'
require "actionpack/action_caching"

if defined?(Bundler)
  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(:default, Rails.env)
end

module ConsiderIt
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    #config.autoload_paths += %W(#{config.root}/lib/custom)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    #config.action_controller.default_charset = 'ISO-8859-1'

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    #config.action_controller.page_cache_directory = Rails.public_path + "/cache"

    config.assets.enabled = true

    config.assets.version = '1.0'

    config.action_mailer.delivery_method = :mailhopper

    config.force_ssl = false
    
    config.assets.image_optim = false

    config.action_controller.permit_all_parameters = true #disable strong parameters
    
    ##################
    # for our custom rails directory structure
    config.paths['app'] << "@server"
    config.paths["app/controllers"] << "@server/controllers"
    config.paths["app/models"] << "@server/models"
    config.paths["app/views"] << "@server/views"


    config.paths["app/views"] << "_old@client/templates"


    config.paths["app/mailers"] << "@server/mailers"
    config.paths["app/helpers"] << "@server/helpers"

    config.paths["app/controllers/concerns"] << "@server/controllers/concerns"
    config.paths["app/models/concerns"] << "@server/models/concerns"

    config.paths["lib/tasks"] << "test"

    #suspiciously, Rails apparently already loads @server/notifications...
    #config.paths["config/initializers"] << "@server/notifications"

    asset_paths = ["@client", "@client/assets", "_old@client/assets/fonts", "_old@client", "_old@client/assets"]
    for asset_path in asset_paths
        config.paths["app/assets"] << asset_path
        config.assets.paths << Rails.root.join(asset_path)
    end
    ########################################



    # Enable FS storage for Paperclip
    Paperclip::Attachment.default_options.merge!({
      :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
      :url => "/system/:attachment/:id/:style/:filename",   
      :default_url => "#{ENV['RAILS_RELATIVE_URL_ROOT'] || ''}/system/default_avatar/:style_default-profile-pic.png",
    })    
  end
end