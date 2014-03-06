require 'mail'

class UserMailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'
  include Devise::Mailers::Helpers

  ######### DEVISE MAILERS
  def confirmation_instructions(user, proposal, token, options)
    if user.nil?
      return
    end
    
    @token = token 
    #generate_reset_password_token!(user) #if (user.reset_password_token.nil? || !user.reset_password_period_valid?)

    @user = user
    @proposal = proposal
    @host = options[:host]
    @options = options
    email_with_name = "#{@user.username} <#{@user.email}>"

    subject = "please confirm your email"
    from = format_email(options[:from], options[:app_title])
    mail(:from => from, :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")

  end

  def reset_password_instructions(user, token, options)
    #generate_reset_password_token!(user) #if (user.reset_password_token.nil? || !user.reset_password_period_valid?)    

    @user = user
    @host = options[:host]
    @options = options
    @token = token 
    email_with_name = "#{@user.username} <#{@user.email}>"
    subject = "password reset instructions"
    from = format_email(options[:from], options[:app_title])
    mail(:from => from, :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")
  end

  def invitation(email, proposal, notification_type, options )
    @email = email
    user = User.find_by_lower_email email
    @unique_token = user.nil? ? '' : user.unique_token
    @user_exists = !user.nil?

    @proposal = proposal
    @host = options[:host]
    @options = options
    @notification_type = notification_type

    email_with_name = @email
    from = format_email(options[:from], options[:app_title])

    if notification_type == 'your proposal'
      subject = "Information about your new discussion"
    else
      subject = "#{proposal.user.name} invites you to participate in a discussion"
    end

    mail(:from => from, :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")

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

    # def generate_reset_password_token!(user)
    #   user.reset_password_token = User.reset_password_token
    #   user.reset_password_sent_at = Time.now.utc
    #   user.save
    # end
end

