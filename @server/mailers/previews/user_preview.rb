class UserPreview < ActionMailer::Preview
  def reset_password_instructions
    UserMailer.reset_password_instructions(User.where('registered').last, 'easfdjklsjffasdf', Subdomain.first)
  end
end
