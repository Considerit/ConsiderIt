require 'mail'

class AdminMailer < Mailer

  #### MODERATION ####
  def content_to_moderate(user, subdomain)
    @user = user
    @subdomain = subdomain

    subject = "Pending content to moderate"

    to = format_email user.email, user.name
    from = format_email(default_sender(subdomain), (subdomain.title))

    mail(:from => from, :to => to, :subject => subject_line(subject, subdomain))

  end


end