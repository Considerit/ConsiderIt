

Rails.root.join("@email", "send_digest")

task :send_email_notifications => :environment do

  notifications = Notifier.aggregate({'sent_email' => false})

  for subdomain_id, n_for_subdomain in notifications
    for user_id, n_for_user in n_for_subdomain
      user = User.find user_id
      prefs = user.subscription_settings(Subdomain.find(subdomain_id))
      emails_sent = user.emails_received

      for digest_object_type, n_for_type in n_for_user

        for digest_object_id, notifications_to_digest in n_for_type
          digest_object = digest_object_type.constantize.find(digest_object_id) 
          send_digest(user, digest_object, notifications_to_digest, prefs, emails_sent)
        end
      end
    end
  end
end

# AdminMailer.content_to_assess(assessment, user, subdomain).deliver_now

