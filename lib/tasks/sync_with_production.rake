require 'open-uri'
require 'rubygems/package'
require 'zlib'

##################################################################
# Synchronizes staging or dev environment with production database
#
# 1) Download and import a target production database backup
# 2) Drops, recreates, and imports new considerit database
# 3) Imports file attachments into local environment
# 4) Appends .ghost to all non-super admin user email addresses
#    to prevent emails being sent to real users in a testing context
# 5) Migrates the database so it is in sync with current environment

# dumps are located in ~/Dropbox/Apps/considerit_backup/xenogear
# This script assumes a tarball created via the Backup gem. 
DATABASE_BACKUP_URL = "https://www.dropbox.com/s/penz7b89znd4t1x/xenogear.tar?dl=1"

# Where production assets are served from 
PRODUCTION_ASSET_HOST = "http://d2rtgkroh5y135.cloudfront.net"

task :sync_with_production, [:sql_url] => :environment do |t, args|
  sql_url = args[:sql_url] ? args[:sql_url] : DATABASE_BACKUP_URL

  puts "Preparing local database based on production database #{sql_url}..."
  success = prepare_production_database sql_url

  if success
    puts "Downloading file attachments from production..."
    download_files_from_production
  else
    puts "Failed"
  end
end

def prepare_production_database(sql_url)

  # Download and extract target production database backup

  open('tmp/production_db.tar', 'wb') do |file|
    file << open(URI.parse(sql_url)).read
  end

  # Backup's tarball is a directory xenogear/databases/MySQL.sql.gz
  tar_extract = Gem::Package::TarReader.new(open('tmp/production_db.tar'))
  tar_extract.rewind # The extract has to be rewinded after every iteration
  tar_extract.each do |entry|
    if entry.full_name.end_with?('.sql.gz')
      open('tmp/production_db.sql', 'wb') do |gz|
        gz << Zlib::GzipReader.new(entry).read
      end
    end
  end
  tar_extract.close

  puts "...downloaded and extracted production database backup from #{DATABASE_BACKUP_URL}"

  # Drop existing database
  
  Rake::Task["db:drop"].invoke  
  Rake::Task["db:create"].invoke
  db = Rails.configuration.database_configuration[Rails.env]
  puts "...dropped and recreated database #{db['database']}"

  # Import production database backup
  puts "...now we're importing data. Might take a few minutes."

  puts "\t\tmysql -u#{db['username']} -p#{db['password']} #{db['database']} < #{Rails.root}/tmp/production_db.sql"

  system "mysql -u#{db['username']} -p#{db['password']} #{db['database']} < #{Rails.root}/tmp/production_db.sql"

  puts "...imported production db into #{db['database']}"

  # Append .ghost to all non-super admin user email addresses
  # to prevent emails being sent to real users in a testing context
  ActiveRecord::Base.connection.execute("UPDATE users SET email=CONCAT(email,'.ghost') WHERE email IS NOT NULL AND super_admin=false")
  puts "...modified non superadmin email addresses to prevent email notifications"

  # Migrates the database so it is in sync with current environment
  system "bundle exec rake db:migrate > /dev/null 2>&1"
  puts "...migrated the database"

  cleanup = ['tmp/production_db.tar', 'tmp/production_db.sql']
  cleanup.each do |f|
    File.delete f if File.exist?(f)
  end
  puts "...cleaned up tmp files"

  return true
end



# Serving assets from AWS via Cloudfront and S3 
# helps speed up page loads by distributing the 
# requests across multiple servers that are on average
# more geographic proximate to clients. 
#
# However, AWS creates some problems when we want to pull in 
# the production database to use in a test or staging
# environment. Specifically, all the files, such as avatars, 
# that have been uploaded by users via Paperclip continue to 
# live at the production AWS S3 bucket.
#   - In staging, we use a different S3 bucket, so the 
#     staging environment can't serve the files
#   - In development, our local machines aren't
#     configured to use AWS, so we can't see the files
#
# This rake task will download all file uploads for the 
# currently loaded database to the local environment. 

# You need to configure the source asset host from which 
# the database originated. It will default to the asset host
# for consider.it.


task :download_files_from_production => :environment do
  download_files_from_production
end

def download_files_from_production
  # The attachments to synchronize.
  attachments = [ 
    {name: 'avatars', model: User},
    {name: 'logos', model: Subdomain},
    {name: 'mastheads', model: Subdomain},
    {name: 'icons', model: Assessable::Verdict}
  ]

  # find out where we store out assets...
  has_aws = Rails.env.production? && APP_CONFIG.has_key?(:aws) && APP_CONFIG[:aws].has_key?(:access_key_id) && !APP_CONFIG[:aws][:access_key_id].nil?
  if has_aws
    local_asset_host = "http://#{APP_CONFIG[:aws][:cloudfront]}.cloudfront.net"
    path_template = Paperclip::Attachment.default_options[:path]
  else
    # default_options[:url] will look like "/system/:attachment/:id/:style/:filename"
    path_template = Paperclip::Attachment.default_options[:url]  
  end

  attachments.each do |attachment|
    # for each object of model that has an attachment of this type
    field = "#{attachment[:name].singularize}_file_name"
    attachment[:model].where("#{field} IS NOT NULL").each do |obj|
      url = path_template
              .gsub(":attachment", attachment[:name])
              .gsub(":id", obj.id.to_s)
              .gsub(":style", "original")
              .gsub(":filename", obj[field])

      # check if the file is already downloaded
      if has_aws
        already_downloaded = url_exist?("#{local_asset_host}/#{url}")
        url = "#{PRODUCTION_ASSET_HOST}/#{url}"
      else
        path = "#{Rails.root.to_s}/public#{url}"
        already_downloaded = File.exist?(path)
        url = "#{PRODUCTION_ASSET_HOST}#{url}"
      end

      if !already_downloaded
        # if not, download it
        

        io = URI.parse(url)
        begin
          open(io) #trigger an error if url doesn't exist
        rescue
          pp "FAILED DOWNLOADING: #{url}"
        else
          # now save the attachment
          begin
            # for some reason, the following doesn't trigger
            # the correct paperclip saving mechanim...
            #
            # obj.send(attachment[:name].singularize, io)
            #
            # ...so we'll just do it manually
            case attachment[:name].singularize 
            when 'avatar'
              data = Base64.encode64(open(io).read)
              obj.b64_thumbnail = "data:image/jpeg;base64,#{data.gsub(/\n/,' ')}"
              obj.avatar = io
            when 'icon'
              obj.icon = io
            when 'masthead'
              obj.masthead = io
            when 'logo'
              obj.logo = io
            end
            obj.save
          rescue => e
            pp "FAILED SAVING: #{url} because of #{e.to_s}"
            ActiveRecord::Base.connection.reconnect!
          else 
            pp "Saved locally: #{url}"
          end
        end
      end
    end

  end
  # Avatar attachments are processed as background tasks
  Delayed::Worker.new.work_off(Delayed::Job.count)
end



# from http://stackoverflow.com/questions/5908017/check-if-url-exists-in-ruby
require "net/http"
def url_exist?(url_string)
  url = URI.parse(url_string)
  req = Net::HTTP.new(url.host, url.port)
  path = url.path if url.path.present?
  res = req.request_head(path || '/')
  !["404", "403"].include? res.code 
rescue Errno::ENOENT
  false # false if can't find the server
end
