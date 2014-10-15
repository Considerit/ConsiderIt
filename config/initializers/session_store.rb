# Be sure to restart your server when you modify this file.


# Use a redis cache store for sessions, a different store than our other memcached data.
# This allows us to maintain user sessions across code deployments.
ConsiderIt::Application.config.session_store :redis_store, :expire_after => 1.month


#ConsiderIt::Application.config.session_store :cookie_store, :key => '_ConsiderIt_session'
#ConsiderIt::Application.config.session_store :mem_cache_store, 'localhost', '127.0.0.1:11211', {:namespace => 'considerit'}

#ConsiderIt::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 1.day

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
#ConsiderIt::Application.config.session_store :active_record_store
