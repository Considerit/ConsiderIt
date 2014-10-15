source 'http://rubygems.org'

#############
# CORE
gem 'rails', '~>4'
gem 'actionpack-action_caching' # Required for caches_action on Avatars
gem 'redis-rails' #session storage

#############
# AUTHENTICATION
gem "bcrypt"
gem "omniauth" # this gem may no longer be necessary
gem 'omniauth-oauth2'
gem 'omniauth-twitter' 
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

#############
# AUTHORIZATION
gem 'cancan' #https://github.com/ryanb/cancan
gem 'role_model' #http://rubydoc.info/gems/role_model/0.7.1/frames

#############
# DATABASE & DATABASE MIDDLEWARE
gem "mysql2"
gem 'acts_as_tenant' # https://github.com/ErwinM/acts_as_tenant

#############
# VIEWS / FORMS / CLIENT
gem "haml"
gem 'paperclip' # https://github.com/thoughtbot/paperclip
gem 'paperclip-compression'
gem 'delayed_paperclip'
gem 'font-awesome-rails', "~> 4.2.0"
gem "js-routes" # https://github.com/railsware/js-routes

# used for parsing useragent string for logging client errors
gem 'useragent' # https://github.com/josh/useragent

#############
# PURE PERFORMANCE
# Rails JSON encoding is super slow, oj makes it faster
gem 'oj'
gem 'oj_mimic_json' # we need this for Rails 4.1.x

#############
# BACKGROUND PROCESSING / EMAIL
gem 'whenever' # https://github.com/javan/whenever
gem 'delayed_job', :git => 'git://github.com/collectiveidea/delayed_job.git' # https://github.com/collectiveidea/delayed_job
gem 'delayed_job_active_record', :git => 'git://github.com/collectiveidea/delayed_job_active_record.git'
gem "daemons"
gem 'mailhopper' # https://github.com/cerebris/mailhopper
gem 'delayed_mailhopper' # https://github.com/cerebris/delayed_mailhopper
gem 'actionmailer-with-request' # https://github.com/weppos/actionmailer_with_request
gem 'premailer-rails' # https://github.com/fphilipe/premailer-rails
gem 'backup' #https://github.com/meskyanichi/backup

#############
# BUILD / DEPLOY / ASSET PIPELINE 
gem 'sprockets'
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem "therubyracer", :require => 'v8' #coffeescript dependency that gives Ruby interface to v8 javascript engine 
gem 'coffee-rails' #, "~> 3.2.2"
gem 'uglifier'
gem 'sass-rails', "~> 4.0.3"
gem 'bourbon'
gem "asset_sync"


##############
# SEO
gem 'sitemap_generator' # creates sitemaps for you. Defined in config/sitemap.rb
gem 'prerender_rails' # takes html snapshots of pages and serves them to search bots

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'thin'
  gem 'newrelic_rpm'
  gem 'guard', '>= 2.2.2',       :require => false
  gem 'guard-livereload',        :require => false
  gem 'rack-livereload'
  gem 'rb-fsevent',              :require => false  #filesystem management for OSX; used by guard
end

group :production do
  gem 'exception_notification'
  gem "aws-ses", "~> 0.6.0", :require => 'aws/ses', :git => 'git://github.com/drewblas/aws-ses.git'
  gem 'aws-sdk'
  gem 'dalli' # memcaching: https://github.com/mperham/dalli/
end
