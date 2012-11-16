source 'http://rubygems.org'

gem "therubyracer", :require => 'v8'
gem 'rails', '~>3.2'

gem "mysql2"

gem 'thin'

gem "haml"
gem 'sass-rails',   "~> 3.2.3"

# https://github.com/plataformatec/devise
gem 'devise'

gem "omniauth"
gem 'omniauth-openid'
gem 'omniauth-oauth'
gem 'omniauth-twitter' 
gem 'omniauth-facebook'

gem 'twitter'

# https://github.com/ErwinM/acts_as_tenant
gem 'acts_as_tenant'

# https://github.com/sferik/rails_admin
gem 'rails_admin'

#https://github.com/ryanb/cancan
gem 'cancan'

#http://rubydoc.info/gems/role_model/0.7.1/frames
gem 'role_model'

# https://github.com/thoughtbot/paperclip
gem 'rmagick'
gem 'aws-sdk'
gem 'paperclip'

# https://github.com/amatsuda/kaminari
gem 'kaminari'

# https://github.com/javan/whenever
gem 'whenever'

# https://github.com/collectiveidea/delayed_job
gem 'delayed_job_active_record'
gem "daemons"

# https://github.com/cerebris/mailhopper
gem 'mailhopper'

# https://github.com/cerebris/delayed_mailhopper
gem 'delayed_mailhopper'

# https://github.com/markbates/yamler
gem 'yamler'

# https://github.com/indirect/jquery-rails
gem 'jquery-rails'

gem 'paper_trail'

# https://github.com/lucasefe/themes_for_rails
gem "themes_for_rails", "0.5.0.2", :git => 'git://github.com/tkriplean/themes_for_rails.git'

# https://github.com/weppos/actionmailer_with_request
gem 'actionmailer-with-request'

#https://github.com/meskyanichi/backup
gem 'backup', "~>3.0.24"

# https://github.com/fphilipe/premailer-rails3
gem 'hpricot'
gem 'premailer-rails3'

# https://github.com/bradphelan/rocket_tag
# gem 'acts-as-taggable-on'

gem "squeel", "1.0.9"
gem "rocket_tag", "~> 0.5.6"

# https://github.com/philnash/bitly
gem 'bitly'

# https://github.com/mperham/dalli/
gem 'dalli'

# https://github.com/vmg/rinku
gem 'rinku'

#custom gems
gem "reflect", :path => "lib/gems/reflect"
gem "followable", :path => "lib/gems/followable"
gem "trackable", :path => "lib/gems/trackable"
gem "commentable", :path => "lib/gems/commentable"
gem "moderatable", :path => "lib/gems/moderatable"
gem "assessable", :path => "lib/gems/assessable"

gem 'sitemap_generator'

#gem 'spatial_adapter',   :git => 'git://github.com/AdamFerguson/spatial_adapter.git'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  # gem 'ruby-debug19', :require => 'ruby-debug'
  # gem 'heroku'
end

group :production do
  gem 'exception_notification'
end

gem 'newrelic_rpm'

group :assets do
  gem 'sass-rails',   "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier'
  gem "asset_sync"
  gem 'turbo-sprockets-rails3'
  #gem "themes_for_rails", :git => 'git://github.com/jasherai/themes_for_rails.git'
end
