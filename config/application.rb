require File.expand_path('../boot', __FILE__)

# require 'rails/all'
require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"


require 'pp'
require './config/local_environment'

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

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    has_aws = Rails.env.production? && APP_CONFIG.has_key?(:aws) && APP_CONFIG[:aws].has_key?(:access_key_id) && !APP_CONFIG[:aws][:access_key_id].nil?
    config.action_mailer.delivery_method = has_aws ? :ses : :smtp

    config.force_ssl = false
    
    config.action_controller.permit_all_parameters = true #disable strong parameters

    Rails.application.config.active_job.queue_adapter = :delayed_job
    
    ##################
    # for our custom rails directory structure
    config.paths['app'] << "@server"
    config.paths["app/controllers"] << "@server/controllers"
    config.paths["app/models"] << "@server/models"
    config.paths["app/views"] << "@server/views"

    config.paths["lib/tasks"] << "test"
    config.paths["lib/tasks"] << "lib/screencasts"

    config.paths["lib/tasks"] << "@email"
    config.paths["app/views"] << "@email/email_templates"    
    config.paths["app/mailers"] << "@email/mailers"
    config.paths["app/helpers"] << "@email/email_templates/helpers"

    config.action_mailer.preview_path = "#{Rails.root}/@email/mailers/previews"

    asset_paths = ["@client"]
    for asset_path in asset_paths
        config.paths["app/assets"] << asset_path
        # config.assets.paths << Rails.root.join(asset_path)
    end

    ########################################



    # Enable FS storage for Paperclip
    Paperclip::Attachment.default_options.merge!({
      :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
      :url => "/system/:attachment/:id/:style/:filename"   
    })    
  end
end