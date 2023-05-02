# previewable at /rails/mailers

require Rails.root.join("@email", "send_digest")
require 'ruby-prof'

class DigestPreview < ActionMailer::Preview

  def digest 
    subdomain = Subdomain.find(4307)
    user = User.find(7198590)
    since = user.created_at
    since = 3.days.ago



    mail = send_digest(subdomain, user, 
      user.subscription_settings(subdomain), false, since, true)


    mail
  end


end