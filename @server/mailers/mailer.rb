class Mailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'

  protected

    def valid_email(user)
      return !!(user.email && !user.email.match('\.ghost'))
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