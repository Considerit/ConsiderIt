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
# Make sure to keep the dl=1
DATABASE_BACKUP_URL = "https://www.dropbox.com/s/zdr1cfodbatmvnp/xenogear.tar?dl=1"

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
#
# This method requires the following:
#   > sudo apt-get install python-pip
#   > sudo pip install awscli
#
#   and an aws configuration in ~/.aws/config in the format:
#
#      [default]
#      aws_access_key_id=<key>
#      aws_secret_access_key=<secret>
#

task :download_files_from_production => :environment do
  download_files_from_production
end

def download_files_from_production 

  puts "sync with production assets on AWS"
  `aws s3 sync s3://considerit/system/ public/system/`

  puts "Update avatar thumbnails if necessary"
  User.where("avatar_file_name IS NOT NULL").each do |user|
    path = Paperclip::Attachment.default_options[:path]
            .gsub(':rails_root/', '')
            .gsub(":attachment", 'avatars')
            .gsub(":id", user.id.to_s)
            .gsub(":style", "small")
            .gsub(":filename", user.avatar_file_name)

    begin
      f = open(path, 'r') 
    rescue
      puts "Couldn't open file #{path}"
      next
    end

    b64_encoding = Base64.encode64 f.read
    thumbnail = "data:image/jpeg;base64,#{b64_encoding.gsub(/\n/,' ')}"

    if user.b64_thumbnail != thumbnail
      begin
        user.b64_thumbnail = thumbnail
        user.save
        puts "Set thumbnail for user #{user.name}"
      rescue
        puts "Failed to set thumbnail for user #{user.name}"
      end
    end

    f.close()
  end

end