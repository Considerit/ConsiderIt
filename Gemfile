source 'http://rubygems.org'

# CORE
gem 'rails', '~>4'
gem 'actionpack-action_caching' # To make smooth upgrade from Rails 3 to 4

# CONFIGURATION
gem 'yamler' # https://github.com/markbates/yamler

# CACHING / SESSIONS
gem 'dalli' # https://github.com/mperham/dalli/

# AUTHENTICATION
gem 'devise'
gem "omniauth"
gem 'omniauth-oauth2'
gem 'omniauth-twitter' 
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'twitter'

# AUTHORIZATION
gem 'cancan' #https://github.com/ryanb/cancan
gem 'role_model' #http://rubydoc.info/gems/role_model/0.7.1/frames

# DATABASE & DATABASE MIDDLEWARE
gem "mysql2"
gem 'acts_as_tenant' # https://github.com/ErwinM/acts_as_tenant

# VIEWS / FORMS / CLIENT
gem "haml"
gem 'paperclip' # https://github.com/thoughtbot/paperclip
gem 'paperclip-compression'
gem "remotipart" # https://rubygems.org/gems/remotipart
gem 'font-awesome-rails'
gem "js-routes" # https://github.com/railsware/js-routes
gem "therubyracer", :require => 'v8'
gem 'jquery-rails' # https://github.com/indirect/jquery-rails

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

# needed anymore? 
gem "oj" # https://github.com/ohler55/oj
gem 'rinku' # https://github.com/vmg/rinku
gem 'useragent' # https://github.com/josh/useragent

# BUILD / DEPLOY / ASSET PIPELINE 
gem 'sprockets'
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem 'coffee-rails' #, "~> 3.2.2"
gem 'uglifier'
gem "asset_sync"
gem 'sass-rails', "~> 4.0.3"
gem 'bourbon'
gem 'sitemap_generator' # SEO

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'thin'
  gem 'meta_request'
  gem 'newrelic_rpm'
  gem 'guard', '>= 2.2.2',       :require => false
  gem 'guard-livereload',        :require => false
  gem 'rack-livereload'
  gem 'rb-fsevent',              :require => false  
end

group :production do
  gem 'exception_notification'
  gem "aws-ses", "~> 0.5.0", :require => 'aws/ses', :git => 'git://github.com/drewblas/aws-ses.git'
  gem 'aws-sdk'
end