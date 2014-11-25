require 'mail'

class AdminMailer < Mailer

  #### MODERATION ####
  def content_to_moderate(user, subdomain)
    @user = user
    @host = subdomain.host_with_port
    @url = dashboard_moderate_url(:host => @host)
    @subdomain = subdomain

    subject = "Pending content to moderate"

    to = format_email user.email, user.name
    from = format_email(from_email(subdomain), subdomain.app_title)

    mail(:from => from, :to => to, :subject => "[#{subdomain.app_title}] #{subject}")

  end

  def content_to_assess(assessment, user, subdomain)
    @user = user
    @host = subdomain.host_with_port
    @url = dashboard_assessment_url(:host => @host)
    @assessment = assessment
    @subdomain = subdomain

    subject = "A new fact check request"

    to = format_email user.email, user.name    
    from = format_email(from_email(subdomain), subdomain.app_title)

    mail(:from => from, :to => to, :subject => "[#{subdomain.app_title}] #{subject}")

  end

  private

    def from_email(subdomain)
      subdomain.notifications_sender_email && subdomain.notifications_sender_email.length > 0 ? subdomain.notifications_sender_email : APP_CONFIG[:email]
    end


end