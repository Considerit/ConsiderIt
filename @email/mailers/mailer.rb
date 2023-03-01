
class Mailer < ActionMailer::Base
  layout 'email'
  helper MailerHelper

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
    APP_CONFIG[:email]
  end

  def subject_line(subject, subdomain)
    title = subdomain.title

    if !title || title == ''
      #raise "huh?? #{subdomain.id} #{subdomain.name}"
      title = 'untitled'
    elsif title == APP_CONFIG[:product_page]
      title = 'Consider.it'
    end

    "[#{title}] #{subject}"
  end

end