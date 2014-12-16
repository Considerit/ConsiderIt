source 'http://rubygems.org'

#############
# CORE
gem 'rails', '~>4'

#############
# AUTHENTICATION
gem "bcrypt"
gem 'omniauth-oauth2'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

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

#############
# PURE PERFORMANCE
# Rails JSON encoding is super slow, oj makes it faster
gem 'oj', "2.10.2" #temp restriction on version until https://github.com/ohler55/oj/issues/190 solved
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
gem 'backup' #https://github.com/meskyanichi/backup

#############
# BUILD / DEPLOY / ASSET PIPELINE 
gem 'sprockets'
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem "therubyracer", :require => 'v8' #coffeescript dependency that gives Ruby interface to v8 javascript engine 
gem 'coffee-rails'
gem 'uglifier'
gem 'sass-rails', "~> 4.0.3"
gem "asset_sync"

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'thin'
  # gem 'newrelic_rpm'
  # gem 'guard', '>= 2.2.2',       :require => false
  # gem 'guard-livereload',        :require => false
  # gem 'rack-livereload'
  # gem 'rb-fsevent',              :require => false  #filesystem management for OSX; used by guard
end

group :production do
  gem 'exception_notification'
  gem "aws-ses", "~> 0.6.0", :require => 'aws/ses', :git => 'git://github.com/drewblas/aws-ses.git'
  gem 'aws-sdk'
  gem 'dalli' # memcaching: https://github.com/mperham/dalli/

  ##############
  # SEO
  gem 'sitemap_generator' # creates sitemaps for you. Defined in config/sitemap.rb
  gem 'prerender_rails' # takes html snapshots of pages and serves them to search bots

end
