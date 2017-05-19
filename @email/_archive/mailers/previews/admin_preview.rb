class AdminPreview < ActionMailer::Preview
  def content_to_moderate
    AdminMailer.content_to_moderate(User.where('registered').last, Subdomain.first)
  end
end
