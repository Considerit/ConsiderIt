require 'mail'

class UserMailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'
  include Devise::Mailers::Helpers

  ######### DEVISE MAILERS
  def confirmation_instructions(user, proposal, options)
    @user = user
    @proposal = proposal
    @host = options[:host]
    @options = options
    email_with_name = "#{@user.username} <#{@user.email}>"

    subject = "please confirm your email"
    from = format_email(options[:from], options[:app_title])
    mail(:from => from, :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")

  end

  def reset_password_instructions(user)
    @user = user
    @host = options[:host]
    @options = options
    email_with_name = "#{@user.username} <#{@user.email}>"
    subject = "password reset instructions"
    from = format_email(options[:from], options[:app_title])
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

end

