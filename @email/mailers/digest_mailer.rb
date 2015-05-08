require 'mail'

class DigestMailer < Mailer


  def proposal(proposal, user, notifications, channel)
    @notifications = notifications
    @proposal = proposal
    @subdomain = proposal.subdomain
    @user = user

    subject = channel == 'proposal_in_watchlist' \
                         ? "New activity on your" \
                         : "New activity on"

    subject = subject_line "#{subject} \"#{proposal.title(50)}\"", @subdomain

    mail from: from_field(@subdomain), to: to_field(user), subject: subject
  end


  def to_field(user)
    format_email user.email, user.name
  end

  def from_field(subdomain)
    format_email default_sender(subdomain), \
                (subdomain.app_title or subdomain.name)
  end

end