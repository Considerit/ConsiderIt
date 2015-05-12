require 'mail'

class DigestMailer < Mailer


  def proposal(proposal, user, notifications, relation)
    @notifications = notifications
    @proposal = proposal
    @subdomain = proposal.subdomain
    @user = user

    subject = relation == 'authored' \
                         ? "New activity on your" \
                         : "New activity on"

    subject = subject_line "#{subject} \"#{proposal.title(50)}\"", @subdomain

    mail from: from_field(@subdomain), to: to_field(user), subject: subject
  end

  def subdomain(subdomain, user, notifications, relation)
    @notifications = notifications
    @subdomain = subdomain
    @user = user

    case relation
    when 'admin', 'moderator', 'evaluator', 'subdomain_interested'
      subject = "New activity at \"#{subdomain.title}\""
    end

    subject = subject_line subject, @subdomain

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