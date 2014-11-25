class EventPreview < ActionMailer::Preview
  def new_point
    subdomain = Subdomain.first
    point = subdomain.points.published.last
    options = {app_title: 'test', from:'test@test.dev', host: 'localhost', current_subdomain: subdomain}
    EventMailer.new_point(User.where('registered').last, point, options, 'opinion submitter')
  end

  def new_assessment
    assessment = Assessable::Assessment.completed.last

    options = {app_title: 'test', from:'test@test.dev', host: 'localhost', current_subdomain: assessment.subdomain}
    EventMailer.new_assessment(assessment.point.user, assessment.point, assessment, options, 'your point')
  end

  def new_comment
    subdomain = Subdomain.first
    comment = subdomain.comments.last
    options = {app_title: 'test', from:'test@test.dev', host: 'localhost', current_subdomain: subdomain}
    EventMailer.new_comment(comment.point.user, comment.point, comment, options, 'your point')
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

    options = {app_title: 'test', from:'test@test.dev', host: 'localhost', current_subdomain: subdomain}
    EventMailer.send_message(message, User.where('registered').last, options)
  end

end
