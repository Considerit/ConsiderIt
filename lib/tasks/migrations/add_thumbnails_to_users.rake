
task :add_thumbnails_to_user => :environment do 
  beginning_time = Time.now
  ttime = 0


  size = 'small'
  #TODO: do not automatically replace each file ... check hash at end for equality
  begin
    Account.all.each do |accnt|
      internal = Rails.application.config.action_controller.asset_host.nil?
      File.open("public/system/cache/#{accnt.identifier}.css", 'w') do |f|

        accnt.users.where('avatar_file_name IS NOT NULL').each do |user|
          #data = [File.read("public/system/avatars/#{user.id}/small/#{user.avatar_file_name}")].pack('m')
          begin

            img_path = "/system/avatars/#{user.id}/#{size}/#{user.avatar_file_name}".gsub(' ', '_')

            if internal
              i_time = Time.now
              img_data = File.read("public#{img_path}")
              ttime += (Time.now - i_time)*1000
            else
              i_time = Time.now
              img_data = open(URI.parse("http:#{Rails.application.config.action_controller.asset_host}#{img_path}")).read
              ttime += (Time.now - i_time)*1000
            end

            data = Base64.encode64(img_data)
            thumbnail = "data:image/jpeg;base64,#{data.gsub(/\n/,' ')}"
            user.update_attribute('b64_thumbnail', thumbnail)
          rescue
            Rails.logger.info "Could not generate avatar #{user.id}"
          end
          #avatars[:small][user.id] = "data:image/jpg;base64,#{data}"
        end
      end
      # TODO: upload resulting cached avatar file if assethost is s3 (can we add digest to it and serve through asset pipeline?)
    end
  rescue
    Rails.logger.info "Could not regenerate avatars"
  end

  end_time = Time.now
  puts "Time elapsed #{(end_time - beginning_time)*1000} milliseconds"
  puts "In big block #{ttime} milliseconds"


end
