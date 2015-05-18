require Rails.root.join("@email", "send_digest")

class DigestPreview < ActionMailer::Preview

  def digest 
    notifications = Notifier.aggregate(
        skip_moderation_filter: true,
        #filter: {'sent_email' => false}
        )
    
    subdomain_id = notifications.keys.sample
    subdomain = Subdomain.find(subdomain_id)

    user_id = notifications[subdomain_id].keys.sample
    user = User.find(user_id)

    notifications = notifications[subdomain_id][user_id]

    mail = send_digest(user, subdomain, notifications, 
        user.subscription_settings(subdomain), false)

    if !mail 
      mail = digest()
    end

    mail
  end


end