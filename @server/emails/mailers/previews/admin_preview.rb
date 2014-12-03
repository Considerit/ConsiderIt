class AdminPreview < ActionMailer::Preview
  def content_to_moderate
    AdminMailer.content_to_moderate(User.where('registered').last, Subdomain.first)
  end
  def content_to_assess
    AdminMailer.content_to_assess(Assessment.last, User.where('registered').last, Subdomain.first)
  end

end
