# Be sure to restart your server when you modify this file.

#ConsiderIt::Application.config.session_store :cookie_store, :key => '_ConsiderIt_session'
#ConsiderIt::Application.config.session_store :mem_cache_store, 'localhost', '127.0.0.1:11211', {:namespace => 'considerit'}

ConsiderIt::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 1.day


# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
#ConsiderIt::Application.config.session_store :active_record_store
