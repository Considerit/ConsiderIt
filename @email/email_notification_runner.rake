
require 'exception_notification'

require Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do

  if APP_CONFIG.has_key?(:disable_email_notifications) && APP_CONFIG[:disable_email_notifications]
    return
  end

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

      subdomains = Notification.where({'sent_email' => false}).distinct.pluck(:subdomain_id)

      for subdomain_id in subdomains 
        begin 

          subdomain = Subdomain.find(subdomain_id)
          notifications = Notifier.aggregate(filter: {'subdomain_id' => subdomain_id, 'sent_email' => false})
          n_for_subdomain = notifications[subdomain_id] || {}

          for user_id, notifications_for_user in n_for_subdomain

            user = User.find user_id
            prefs = user.subscription_settings(subdomain)

            begin 
              send_digest(Subdomain.find(subdomain_id), user, notifications_for_user, prefs)
            rescue => e
              pp "Failed to send notification to /user/#{user.id} for #{subdomain.name}", e
              ExceptionNotifier.notify_exception(e)      
            end    
          end
        rescue => e 
          pp "Notification runner failed for subdomain #{subdomain.name}", e
          ExceptionNotifier.notify_exception(e)      
        end

      end
    rescue => e
     pp 'Notification runner failure', e
     ExceptionNotifier.notify_exception(e)      
    end

    File.delete(f)
  end

end
