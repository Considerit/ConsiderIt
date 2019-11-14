require Rails.root.join('@server', 'translations')

class Mailer < ActionMailer::Base
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

  def default_sender(subdomain)
    subdomain && subdomain.notifications_sender_email && subdomain.notifications_sender_email.length > 0 ? subdomain.notifications_sender_email : APP_CONFIG[:email]
  end

  def subject_line(subject, subdomain)
    title = subdomain.title

    if !title || title == ''
      #raise "huh?? #{subdomain.id} #{subdomain.name}"
      title = 'untitled'
    end

    "[#{title}] #{subject}"
  end

end