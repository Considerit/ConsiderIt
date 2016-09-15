source 'http://rubygems.org'

#############
# CORE
gem 'rails', '~>4'
gem 'responders', '~> 2.0' #for respond_to, removed from core Rails 4.2
gem 'activerecord-session_store'  # Because CookieStore has race conditions w/ concurrent ajax requests

#############
# AUTHENTICATION
gem "bcrypt"
gem 'ruby-saml', '~> 1.3.1'

#############
# DATABASE & DATABASE MIDDLEWARE
gem "mysql2"
gem 'acts_as_tenant', :git => 'https://github.com/ErwinM/acts_as_tenant'
gem 'deep_cloneable'
gem 'activerecord-import' # bulk imports for performance

#############
# VIEWS / FORMS / CLIENT
gem "haml"
gem 'paperclip' # https://github.com/thoughtbot/paperclip
gem 'paperclip-compression'
gem 'delayed_paperclip'
gem 'font-awesome-rails'

#############
# BACKGROUND PROCESSING / EMAIL
gem 'whenever' # https://github.com/javan/whenever
gem 'delayed_job', :git => 'git://github.com/collectiveidea/delayed_job.git' 
gem 'delayed_job_active_record', :git => 'git://github.com/collectiveidea/delayed_job_active_record.git'
gem "daemons"
gem 'backup' #https://github.com/meskyanichi/backup
gem 'rubyzip'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'thin'
  gem 'ruby-prof'
  # gem 'rack-mini-profiler'

  gem 'oj'
  gem 'oj_mimic_json' # we need this for Rails 4.1.x

end

group :production do
  ############
  # PURE PERFORMANCE
  # Rails JSON encoding is super slow, oj makes it faster
  gem 'oj'
  gem 'oj_mimic_json' # we need this for Rails 4.1.x

  gem 'exception_notification'
  gem "aws-ses", "~> 0.6.0", :require => 'aws/ses', :git => 'git://github.com/drewblas/aws-ses.git'
  gem 'aws-sdk', "~> 1.60"
  gem 'dalli' # memcaching: https://github.com/mperham/dalli/

  ##############
  # SEO
  gem 'sitemap_generator' # creates sitemaps for you. Defined in config/sitemap.rb
  gem 'prerender_rails' # takes html snapshots of pages and serves them to search bots

end
