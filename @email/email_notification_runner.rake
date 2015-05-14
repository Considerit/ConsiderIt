
require 'exception_notification'

require Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do
  begin 
    notifications = Notifier.aggregate(filter: {'sent_email' => false})

    for subdomain_id, n_for_subdomain in notifications
      for user_id, n_for_user in n_for_subdomain
        user = User.find user_id
        prefs = user.subscription_settings(Subdomain.find(subdomain_id))
        

        for digest_object_type, n_for_type in n_for_user

          for digest_object_id, notifications_to_digest in n_for_type
            digest_object = digest_object_type.capitalize.constantize.find(digest_object_id) 
            send_digest(user, digest_object, notifications_to_digest, prefs)
          end
        end
      end
    end
  rescue => e
    pp 'WE FAILED', e
    ExceptionNotifier.notify_exception(e)      
    raise e
  end    
end
