
require 'exception_notification'

require Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do

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
        begin 

          triggered_users = subdomain.digest_triggered_for.clone
          for user_id, triggered in triggered_users
            next if !triggered

            user = User.find_by_id user_id
            next if !user || user.email.match('.ghost')
            
            prefs = user.subscription_settings(subdomain)

            begin 
              send_digest(subdomain, user, prefs)
            rescue => e
              pp "Failed to send notification to /user/#{user.id} for #{subdomain.name}", e
              ExceptionNotifier.notify_exception(e)      
              raise e
            end    
          end
        rescue => e 
          pp "Notification runner failed for subdomain #{subdomain.name}", e
          ExceptionNotifier.notify_exception(e)
          raise e

        end

      end
      
      # log when the last successful run was
      File.write Rails.root.join('tmp', 'email_notification_runner_success'), Time.new.inspect

    rescue => e
      pp 'Notification runner failure', e
      ExceptionNotifier.notify_exception(e)      
    end

    File.delete(f)
  end

end
