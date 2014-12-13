class UserPreview < ActionMailer::Preview
  
  def reset_password_instructions
    UserMailer.reset_password_instructions(User.where('registered').last, 'easfdjklsjffasdf', Subdomain.first)
  end
  
  def verification
    UserMailer.verification(User.find(1701), Subdomain.first)
  end

  def invitation_moderate
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'moderate', Subdomain.first)
  end

  def invitation_participate
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'consider', Subdomain.first, "Hey man, come check this out, I think it's a good idea!")
  end

end
