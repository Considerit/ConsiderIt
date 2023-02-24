# previewable at /rails/mailers

require Rails.root.join("@email", "send_digest")

class DigestPreview < ActionMailer::Preview

  def digest 
    subdomain = Subdomain.find(4053)
    user = User.find(1701)
    since = user.created_at
    since = 25.years.ago
    mail = send_digest(subdomain, user, 
      user.subscription_settings(subdomain), false, since, true)

    mail
  end


end