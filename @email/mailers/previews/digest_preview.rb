# previewable at /rails/mailers

require Rails.root.join("@email", "send_digest")
require 'ruby-prof'

class DigestPreview < ActionMailer::Preview

  def digest 
    subdomain = Subdomain.find(2079)
    user = User.find(1701)
    since = user.created_at
    since = 20.days.ago



    mail = send_digest(subdomain, user, 
      user.subscription_settings(subdomain), false, since, true)


    mail
  end


end