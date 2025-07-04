source 'http://rubygems.org'

#############
# CORE
gem 'rails', '~> 6.1'
gem 'activerecord-session_store'  # Because CookieStore has race conditions w/ concurrent ajax requests

# #############
# # AUTHENTICATION
gem "bcrypt"
gem 'ruby-saml', '~> 1.11'
gem 'omniauth-oauth2'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'


#############
# DATABASE & DATABASE MIDDLEWARE
gem "mysql2" 
gem 'acts_as_tenant'
gem 'activerecord-import' # bulk imports for performance
                          # Used for Opinion.import. Remove after eliminating the 
                          # need to create an unpublished opinion per proposal per user 

#############
# VIEWS / FORMS / CLIENT
gem "haml"
gem 'kt-paperclip'

#############
# BACKGROUND PROCESSING / EMAIL
gem 'whenever' # https://github.com/javan/whenever
gem 'delayed_job', :git => 'https://github.com/collectiveidea/delayed_job' 
gem 'delayed_job_active_record', :git => 'https://github.com/collectiveidea/delayed_job_active_record'
gem "daemons" # for the daemonize method used in bin/delayed_job
gem 'rubyzip'


# #####################
# # For topic modeling
# gem "lemmatizer"

#############
# API calls
gem 'excon'

#############
# Generative AI
# gem "ruby-openai"
gem 'ruby_llm'
gem 'json-schema'


#############
# i18n
gem 'message_format'

############
# PURE PERFORMANCE
# Rails JSON encoding is super slow, oj makes it faster
gem 'oj'
gem 'oj_mimic_json' # we need this for Rails 4.1.x
gem 'bootsnap', require: false

# # for importing from google sheets
gem 'google-api-client'

# # for visitation metrics (and other analytics data)
gem "ahoy_matey", '~>4.2.1'


require 'yaml'

local_config = YAML.load_file "./config/local_environment.yml"

if local_config["default"]["product_page"]
  # for payments
  gem 'stripe', "~>12.5.0"

  # for contact
  gem 'mailgun-ruby'

  # for markdown parsing
  gem 'commonmarker',  "~>1.0.0.pre7"
end 

# # Bundle gems for the local environment. Make sure to
# # put test-only gems in this group so their generators
# # and rake tasks are available in development mode:
group :development, :test do
  gem 'thin'
  gem 'ruby-prof' #, '~> 1.0.0'
  # gem 'mailcatcher'
  gem 'listen'
  # gem 'rack-mini-profiler'

  gem 'css_parser' # for aeroparticpa
end

group :production do
  # gem 'backup' #https://github.com/meskyanichi/backup
  gem 'exception_notification'
  gem 'aws-sdk-rails'
  gem 'aws-sdk-ses'
  gem 'aws-sdk-s3'
  gem 'dalli' # memcaching: https://github.com/mperham/dalli/

  ##############
  # SEO
  gem 'sitemap_generator' # creates sitemaps for you. Defined in config/sitemap.rb
  gem 'prerender_rails' # takes html snapshots of pages and serves them to search bots

end
