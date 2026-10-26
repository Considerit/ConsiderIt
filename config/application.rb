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
    config.load_defaults 7.0

    config.action_dispatch.cookies_same_site_protection = nil # SAML IdPs POST cross-site to /saml/acs, and acs reads session[:sso_idp]. With an explicit Lax cookie the browser won't send the session on that POST, so SAML login can break.

    config.active_record.has_many_inversing = false

    config.active_support.cache_format_version = 7.0

    Rails.application.config.action_dispatch.cookies_serializer = :hybrid

    # See https://guides.rubyonrails.org/configuring.html#config-active-support-disable-to-s-conversion for more information.
    config.active_support.disable_to_s_conversion = true

    # See upgrading guide for more information on how to build a rotator.
    # https://guides.rubyonrails.org/v7.0/upgrading_ruby_on_rails.html
    Rails.application.config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA256

    # Rotator so signed/encrypted cookies written with the old SHA1 key generator are still read
    # (from the Rails 7.0 upgrade guide). Remove once old cookies have expired.
    Rails.application.config.after_initialize do
      Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
        authenticated_encrypted_cookie_salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
        signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

        secret_key_base = Rails.application.secret_key_base

        key_generator = ActiveSupport::KeyGenerator.new(
          secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
        )
        key_len = ActiveSupport::MessageEncryptor.key_len

        old_encrypted_secret = key_generator.generate_key(authenticated_encrypted_cookie_salt, key_len)
        old_signed_secret = key_generator.generate_key(signed_cookie_salt)

        cookies.rotate :encrypted, old_encrypted_secret
        cookies.rotate :signed, old_signed_secret
      end
    end



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