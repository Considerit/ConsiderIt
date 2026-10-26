require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
#require "action_cable/engine"
#require "rails/test_unit/railtie"


require 'pp'
require './config/local_environment'


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
module ConsiderIt
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.action_dispatch.cookies_same_site_protection = nil # SAML IdPs POST cross-site to /saml/acs, and acs reads session[:sso_idp]. With an explicit Lax cookie the browser won't send the session on that POST, so SAML login can break.

    config.active_record.has_many_inversing = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    
    # Don't generate system test files.
    config.generators.system_tests = nil

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

    config.paths["lib/tasks"] << "@email"
    config.paths["app/views"] << "@email/email_templates"    
    config.paths["app/mailers"] << "@email/mailers"
    config.paths["app/helpers"] << "@email/email_templates/helpers"

    config.action_mailer.preview_path = "#{Rails.root}/@email/mailers/previews"

    config.eager_load_paths << config.action_mailer.preview_path

    ########################################



    # Enable FS storage for Paperclip
    Paperclip::Attachment.default_options.merge!({
      :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
      :url => "/system/:attachment/:id/:style/:filename"   
    })    
  end


end