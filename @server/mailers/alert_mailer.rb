require 'mail'

class AlertMailer < Mailer

  #### MODERATION ####
  def content_to_moderate(user, tenant)
    @user = user
    @host = tenant.host_with_port
    @url = dashboard_moderate_url(:host => @host)
    @tenant = tenant

    email_with_name = "#{@user.username} <#{@user.email}>"

    subject = "Pending content to moderate"
    from = format_email(tenant.contact_email, tenant.app_title)

    mail(:from => from, :to => email_with_name, :subject => "[#{tenant.app_title}] #{subject}")

  end

  def content_to_assess(assessment, user, tenant)
    @user = user
    @host = tenant.host_with_port
    @url = assessment_index_url(:host => @host)
    @assessment = assessment
    @tenant = tenant

    email_with_name = "#{@user.username} <#{@user.email}>"

    subject = "A new fact check request"
    from = format_email(tenant.contact_email, tenant.app_title)

    mail(:from => from, :to => email_with_name, :subject => "[#{tenant.app_title}] #{subject}")

  end


end