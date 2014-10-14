require 'mail'

class AlertMailer < Mailer

  #### MODERATION ####
  def content_to_moderate(user, tenant)
    @user = user
    @host = tenant.host_with_port
    @url = dashboard_moderate_url(:host => @host)
    @tenant = tenant

    return unless valid_email(user)

    subject = "Pending content to moderate"



    to = format_email user.email, user.name
    from = format_email(from_email(tenant), tenant.app_title)

    mail(:from => from, :to => to, :subject => "[#{tenant.app_title}] #{subject}")

  end

  def content_to_assess(assessment, user, tenant)
    @user = user
    @host = tenant.host_with_port
    @url = dashboard_assessment_url(:host => @host)
    @assessment = assessment
    @tenant = tenant

    return unless valid_email(user)

    subject = "A new fact check request"

    to = format_email user.email, user.name    
    from = format_email(from_email(tenant), tenant.app_title)

    mail(:from => from, :to => to, :subject => "[#{tenant.app_title}] #{subject}")

  end

  private

    def from_email(tenant)
      tenant.contact_email && tenant.contact_email.length > 0 ? tenant.contact_email : APP_CONFIG[:email]
    end


end