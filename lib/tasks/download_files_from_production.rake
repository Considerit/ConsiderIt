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

asset_host = "http://d2rtgkroh5y135.cloudfront.net"

task :download_files_from_production => :environment do
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
    my_asset_host = "http://#{APP_CONFIG[:aws][:cloudfront]}.cloudfront.net"  
  end

  attachments.each do |attachment|
    # for each object of model that has an attachment of this type
    field = "#{attachment[:name].singularize}_file_name"
    attachment[:model].where("#{field} IS NOT NULL").each do |obj|
      # default_options[:url] will look like "/system/:attachment/:id/:style/:filename"
      url = Paperclip::Attachment.default_options[:url]
              .gsub(":attachment", attachment[:name])
              .gsub(":id", obj.id.to_s)
              .gsub(":style", "original")
              .gsub(":filename", obj[field])
      
      path = "#{Rails.root.to_s}/public#{url}"

      # check if the file is already downloaded
      if has_aws
        already_downloaded = url_exist?("#{my_asset_host}#{url}")
      else
        already_downloaded = File.exist?(path)
      end

      if !already_downloaded
        # if not, download it
        url = "#{asset_host}#{url}"

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
