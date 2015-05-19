
require 'exception_notification'

require Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do
  notifications = Notifier.aggregate(filter: {'sent_email' => false})

  begin
    for subdomain_id, n_for_subdomain in notifications
      for user_id, n_for_user in n_for_subdomain
        user = User.find user_id
        prefs = user.subscription_settings(Subdomain.find(subdomain_id))

        begin 
          send_digest(Subdomain.find(subdomain_id), user, notifications_to_digest, prefs)
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
end
