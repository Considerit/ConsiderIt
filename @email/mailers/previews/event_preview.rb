# previewable at /rails/mailers

class EventPreview < ActionMailer::Preview

  def send_message
    subdomain = Subdomain.first

    attrs = {
      'recipient' => "/user/1701",
      'body' => "This is a test message",
      'subject' => "You should see this",
      'sender_mask' => 'moderator'
    }

    EventMailer.send_message(attrs, User.where('registered').last, subdomain)
  end

  def translations_proposed

    subdomain = Subdomain.first
    EventMailer.translations_proposed(subdomain)

  end

end
