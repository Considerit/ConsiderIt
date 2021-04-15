# previewable at /rails/mailers

require Rails.root.join("@email", "send_digest")

class DigestPreview < ActionMailer::Preview

  def digest 
    subdomain = Subdomain.find(1)
    user = User.find(1701)

    mail = send_digest(subdomain, user, 
      user.subscription_settings(subdomain), false, user.created_at, true)

    mail
  end


end