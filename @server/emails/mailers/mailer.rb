class Mailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'
  add_template_helper MailerHelper

private

  def format_email(addr, name = nil)
    address = Mail::Address.new addr # ex: "john@example.com"
    if name
      address.display_name = name # ex: "John Doe"
    end
    # Set the From or Reply-To header to the following:
    address.format # returns "John Doe <john@example.com>"
  end  

  def default_sender(current_subdomain)
    current_subdomain && current_subdomain.notifications_sender_email && current_subdomain.notifications_sender_email.length > 0 ? current_subdomain.notifications_sender_email : APP_CONFIG[:email]
  end

end