class UserPreview < ActionMailer::Preview
  
  def reset_password_instructions
    UserMailer.reset_password_instructions(User.where('registered').last, 'easfdjklsjffasdf', Subdomain.first)
  end
  
  def verification
    UserMailer.verification(User.find(1701), Subdomain.first)
  end

  def invitation_moderate
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'moderator', Subdomain.first)
  end
  def invitation_fact_check
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'evaluator', Subdomain.first, "Join us in fact checking")
  end
  def invitation_visit
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'visitor', Subdomain.first, "Come check it out")
  end
  def invitation_proposer
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'proposer', Subdomain.first, "Add your own proposals")
  end

  def invitation_opine
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'opiner', Subdomain.first, "Hey man, come check this out, I think it's a good idea!")
  end

  def invitation_editor
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'editor', Subdomain.first, "help refine this plan")
  end

  def invitation_observer
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'observer', Subdomain.first, "We're trying to be transparent here...")
  end

  def invitation_commenter
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'commenter', Subdomain.first, "leave some comments on the points!")
  end

  def invitation_writer
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'writer', Subdomain.first, "write some points!")
  end

end
