# previewable at /rails/mailers

require Rails.root.join("@email", "send_digest")

class DigestPreview < ActionMailer::Preview

  def digest 
    notifications = Notifier.aggregate(
        skip_moderation_filter: true,
        #filter: {'sent_email' => false},
        #filter: {'subdomain_id' => 2354, 'user_id' => 1701}
        # filter: {'sent_email' => false, 'subdomain_id' => 2354, 'user_id' => 1701}
        filter: {'sent_email' => false, 'subdomain_id' => 2354}
        )
    
    subdomain_id = notifications.keys.sample
    subdomain = Subdomain.find(subdomain_id)


    while true 
        user_id = notifications[subdomain_id].keys.sample
        user = User.find(user_id)

        mail = send_digest(subdomain, user, notifications[subdomain_id][user_id], 
            user.subscription_settings(subdomain), false) #, user.created_at) #proposals.where(:subdomain=>subdomain_id).last.created_at)

        pp mail, user_id
        
        if mail 
            break
        end 
    end 


    mail
  end


end