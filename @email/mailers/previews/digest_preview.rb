# previewable at /rails/mailers

require Rails.root.join("@email", "send_digest")

class DigestPreview < ActionMailer::Preview

  def digest 

    notifications = Notifier.aggregate(
        skip_moderation_filter: true,
        #filter: {'sent_email' => false},
        filter: {'subdomain_id' => Subdomain.find_by_name('consider').id, 'user_id' => 1701}
        # filter: {'sent_email' => false, 'subdomain_id' => 2354, 'user_id' => 1701}
        # filter: {'sent_email' => false, 'subdomain_id' => 2604}
        )

    subdomain_id = notifications.keys.sample
    subdomain = Subdomain.find(subdomain_id)


    users = notifications[subdomain_id].keys
    
    mail = nil

    users.each do |user_id|
        
        user = User.find(user_id)

        if user 
            mail = send_digest(subdomain, user, notifications[subdomain_id][user_id], 
                user.subscription_settings(subdomain), false, user.created_at, true) #proposals.where(:subdomain=>subdomain_id).last.created_at)

            if mail
                break
            end 
        end
    end 

    pp mail
    mail
  end


end