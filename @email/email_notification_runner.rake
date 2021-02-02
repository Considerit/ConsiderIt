
require 'exception_notification'

require Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do

  # if APP_CONFIG.has_key?(:disable_email_notifications) && APP_CONFIG[:disable_email_notifications]
  #   return
  # end

  # make sure that an email notification task isn't already running   
  f = Rails.root.join('tmp', 'email_notification_runner')
  if File.exist?(f)
    begin
      raise 'aborting: send_email_notifications already running'
    rescue => err
      ExceptionNotifier.notify_exception err
    end
  else 

    open_f = File.new(f, "w+")

    begin
      subdomains = Subdomain.where('digest_triggered_for is not null').to_a
      subdomains.each do |subdomain|
        pp subdomain.digest_triggered_for

        begin 

          triggered_users = subdomain.digest_triggered_for.clone
          for user_id, triggered in triggered_users
            next if !triggered

            user = User.find user_id
            prefs = user.subscription_settings(subdomain)

            begin 
              send_digest(subdomain, user, prefs)
            rescue => e
              raise e
              pp "Failed to send notification to /user/#{user.id} for #{subdomain.name}", e
              ExceptionNotifier.notify_exception(e)      
            end    
          end
        rescue => e 
          raise e
          pp "Notification runner failed for subdomain #{subdomain.name}", e
          ExceptionNotifier.notify_exception(e)      
        end

      end
    rescue => e
      raise e
      pp 'Notification runner failure', e
      ExceptionNotifier.notify_exception(e)      
    end

    File.delete(f)
  end

end
