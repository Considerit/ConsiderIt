
require 'exception_notification'

require Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do

  # make sure that an email notification task isn't already running   
  f = Rails.root.join('tmp', 'email_notification_runner')
  if File.exist?(f)
    pp 'aborting: send_email_notifications already running'
  else 
    open_f = File.new(f, "w+")

    begin

      notifications = Notifier.aggregate(filter: {'sent_email' => false})

      for subdomain_id, n_for_subdomain in notifications

        for user_id, notifications_for_user in n_for_subdomain

          user = User.find user_id
          prefs = user.subscription_settings(Subdomain.find(subdomain_id))

          begin 
            send_digest(Subdomain.find(subdomain_id), user, notifications_for_user, prefs)
          rescue => e
            pp 'WE FAILED', e
            ExceptionNotifier.notify_exception(e)      
          end    
        end
      end
    rescue => e
     pp 'WE FAILED', e
     ExceptionNotifier.notify_exception(e)      
    end

    File.delete(f)
  end

end
