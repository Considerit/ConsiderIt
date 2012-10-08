#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

require 'mail'

class AlertMailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'

  #### MODERATION ####
  def content_to_moderate(user, tenant)
    @user = user
    @host = tenant.host_with_port
    @url = moderate_url(:host => @host)
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

    subject = "A new fact-check request"
    from = format_email(tenant.contact_email, tenant.app_title)

    mail(:from => from, :to => email_with_name, :subject => "[#{tenant.app_title}] #{subject}")

  end

  private

    def format_email(addr, name = nil)
      address = Mail::Address.new addr # ex: "john@example.com"
      if name
        address.display_name = name # ex: "John Doe"
      end
      # Set the From or Reply-To header to the following:
      address.format # returns "John Doe <john@example.com>"

    end  
end