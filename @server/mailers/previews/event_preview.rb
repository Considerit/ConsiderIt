class EventPreview < ActionMailer::Preview
  def new_point
    subdomain = Subdomain.first
    point = subdomain.points.published.last
    EventMailer.new_point(User.where('registered').last, point, subdomain, 'opinion submitter')
  end

  def new_assessment
    assessment = Assessable::Assessment.completed.last

    EventMailer.new_assessment(assessment.point.user, assessment.point, assessment, assessment.subdomain, 'your point')
  end

  def new_comment
    subdomain = Subdomain.first
    comment = subdomain.comments.last
    EventMailer.new_comment(comment.point.user, comment.point, comment, subdomain, 'your point')
  end

  def send_message
    subdomain = Subdomain.first

    attrs = {
      'recipient' => 1701,
      'body' => "This is a test message",
      'subject' => "You should see this",
      'sender' => User.where('registered').last.name
    }
    message = DirectMessage.new(attrs)

    EventMailer.send_message(message, User.where('registered').last, subdomain)
  end

end
