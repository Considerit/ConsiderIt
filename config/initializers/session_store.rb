# Be sure to restart your server when you modify this file.


# Use a redis cache store for sessions, a different store than our other memcached data.
# This allows us to maintain user sessions across code deployments.
#ConsiderIt::Application.config.session_store :redis_store, :expire_after => 1.month


#ConsiderIt::Application.config.session_store :cookie_store, :key => '_ConsiderIt_session', :domain => :all
#ConsiderIt::Application.config.session_store :mem_cache_store, 'localhost', '127.0.0.1:11211', {:namespace => 'considerit'}

#ConsiderIt::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 1.day

# Use the database for sessions instead of the cookie-based default
# (create the session table with "rails generate active_record:session_migration")
ConsiderIt::Application.config.session_store :active_record_store, secure: Rails.env.production?


# REMOVE THIS once active_record_store v.11 is released.  Should be soon!
# Info: https://github.com/rails/activerecord-session_store/issues/36
module Kernel
  def quietly_with_deprecation_silenced(&block)
    ActiveSupport::Deprecation.silence do
      quietly_without_deprecation_silenced(&block)
    end
  end
  alias_method_chain :quietly, :deprecation_silenced
end
