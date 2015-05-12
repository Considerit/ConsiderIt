require Rails.root.join("@email", "send_digest")

class DigestPreview < ActionMailer::Preview
  def proposal

    notifications = Notifier.aggregate({'sent_email' => false, 'digest_object_type' => 'Proposal'})
    subdomain_id = notifications.keys.sample   
    user_id = notifications[subdomain_id].keys.sample
    digest_objects = notifications[subdomain_id][user_id]['proposal']
    digest_object_id = digest_objects.keys.sample

    proposal = Proposal.find(digest_object_id)
    user = User.find(user_id)
    notifications = digest_objects[digest_object_id]

    mail = send_digest(user, proposal, notifications, 
        user.subscription_settings(Subdomain.find(subdomain_id)), 
        user.emails_received
        )

    if !mail 
      mail = proposal()
    end

    mail
  end


  def subdomain

    notifications = Notifier.aggregate(
        {'sent_email' => false, 'digest_object_type' => 'Subdomain'})
    
    subdomain_id = notifications.keys.sample
    user_id = notifications[subdomain_id].keys.sample
    digest_objects = notifications[subdomain_id][user_id]['subdomain']
    digest_object_id = digest_objects.keys.sample
    subdomain = Subdomain.find(digest_object_id)
    user = User.find(user_id)
    notifications = digest_objects[digest_object_id]
    mail = send_digest(user, subdomain, notifications, 
        user.subscription_settings(Subdomain.find(subdomain_id)), 
        user.emails_received
        )

    if !mail 
      mail = subdomain()
    end

    mail
  end

end