# previewable at /rails/mailers

class Previews::UserPreview < ActionMailer::Preview
   def welcome_new_customer
    UserMailer.welcome_new_customer(User.where('registered').last, Subdomain.last)
  end

  def reset_password_instructions
    UserMailer.reset_password_instructions(User.where('registered').last, 'easfdjklsjffasdf', Subdomain.first)
  end
  
  def verification
    UserMailer.verification(User.find(1701), Subdomain.first)
  end

  def invitation_moderate
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'moderator', Subdomain.first)
  end

  def invitation_visit
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'visitor', Subdomain.first, "Come check it out")
  end
  def invitation_proposer
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Subdomain.first, 'proposer', Subdomain.first, "Add your own proposals")
  end

  def invitation_participant
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'participant', Subdomain.first, "Hey man, come check this out, I think it's a good idea!")
  end

  def invitation_editor
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'editor', Subdomain.first, "help refine this plan")
  end

  def invitation_observer
    UserMailer.invitation(User.where('registered').first, User.where('registered').last, Proposal.active.first, 'observer', Subdomain.first, "We're trying to be transparent here...")
  end

end
