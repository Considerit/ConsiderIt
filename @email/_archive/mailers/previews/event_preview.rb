class EventPreview < ActionMailer::Preview
  def new_point
    subdomain = Subdomain.first
    point = subdomain.points.published.last
    EventMailer.new_point(User.where('registered').last, point, subdomain, 'opinion submitter')
  end

  def new_comment
    subdomain = Subdomain.first
    comment = subdomain.comments.last
    EventMailer.new_comment(comment.point.user, comment.point, comment, subdomain, 'your point')
  end

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

end
