source 'http://rubygems.org'

gem "therubyracer", :require => 'v8'
gem 'rails', '~>4'

gem "mysql2"

gem "haml"

# https://github.com/railsware/js-routes
gem "js-routes"

# https://github.com/ohler55/oj
gem "oj"

# https://github.com/plataformatec/devise
gem 'devise'

gem "omniauth"
gem 'omniauth-oauth2'
gem 'omniauth-twitter' 
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

gem 'twitter'

# https://rubygems.org/gems/remotipart
gem "remotipart"

# https://github.com/ErwinM/acts_as_tenant
gem 'acts_as_tenant'

#https://github.com/ryanb/cancan
gem 'cancan'

#http://rubydoc.info/gems/role_model/0.7.1/frames

gem 'role_model'

# https://github.com/thoughtbot/paperclip
gem 'paperclip'
gem 'paperclip-compression'

# https://github.com/javan/whenever
gem 'whenever'

# https://github.com/collectiveidea/delayed_job
gem 'delayed_job', :git => 'git://github.com/collectiveidea/delayed_job.git' #TODO: remove git location after they release new version
gem 'delayed_job_active_record', :git => 'git://github.com/collectiveidea/delayed_job_active_record.git'
gem "daemons"

# https://github.com/cerebris/mailhopper
gem 'mailhopper' 

# https://github.com/cerebris/delayed_mailhopper
gem 'delayed_mailhopper'

# https://github.com/fphilipe/premailer-rails
#gem 'hpricot'
gem 'premailer-rails'

# https://github.com/markbates/yamler
gem 'yamler'

# https://github.com/rgrove/sanitize/
gem 'sanitize'

# https://github.com/indirect/jquery-rails
gem 'jquery-rails'

# https://github.com/weppos/actionmailer_with_request
gem 'actionmailer-with-request'

#https://github.com/meskyanichi/backup
gem 'backup'

# https://github.com/mperham/dalli/
gem 'dalli'

# https://github.com/vmg/rinku
gem 'rinku' # needed anymore?

gem 'sitemap_generator'

# https://github.com/cmer/cacheable-csrf-token-rails
gem 'cacheable-csrf-token-rails', :git => 'git://github.com/ekampp/cacheable-csrf-token-rails'

# https://github.com/josh/useragent
gem 'useragent'

gem 'font-awesome-rails'

#######
# https://github.com/rails/protected_attributes
# These are primarily to make smooth upgrade from Rails 3 to 4
gem 'actionpack-action_caching'
#######


##
# These used to be the Assets group
gem 'sprockets'
gem 'sprockets-rails', :require => 'sprockets/railtie'

gem 'aws-sdk'
gem 'coffee-rails' #, "~> 3.2.2"
gem 'uglifier'
gem "asset_sync"

gem 'sass-rails'

gem 'bourbon'


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
end

