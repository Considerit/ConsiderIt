require 'mail'

class UserMailer < Mailer
  #include Devise::Mailers::Helpers

  ######### DEVISE MAILERS
  # def confirmation_instructions(user, proposal, token, options)
  #   if user.nil?
  #     return
  #   end
    
  #   @token = token 
  #   #generate_reset_password_token!(user) #if (user.reset_password_token.nil? || !user.reset_password_period_valid?)

  #   @user = user
  #   @proposal = proposal
  #   @host = options[:host]
  #   @options = options

  #   subject = "please confirm your email"

  #   to = format_email @user.email, @user.name
  #   from = format_email(options[:from], options[:app_title])

  #   mail(:from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")

  # end

  def reset_password_instructions(user, token, options)
    #generate_reset_password_token!(user) #if (user.reset_password_token.nil? || !user.reset_password_period_valid?)    

    @user = user
    @host = options[:host]
    @options = options
    @token = token 
    subject = "password reset instructions"

    to = format_email @user.email, @user.name
    from = format_email(options[:from], options[:app_title])
    mail(:from => from, :to => to, :subject => "[#{options[:app_title]}] #{subject}")
  end

  # def invitation(email, proposal, notification_type, options )
  #   @email = email
  #   user = User.find_by_lower_email email
  #   @unique_token = user.nil? ? '' : user.unique_token
  #   @user_exists = !user.nil?

  #   @proposal = proposal
  #   @host = options[:host]
  #   @options = options
  #   @notification_type = notification_type

  #   from = format_email(options[:from], options[:app_title])

  #   if notification_type == 'your proposal'
  #     subject = "Information about your new discussion"
  #   else
  #     subject = "#{proposal.user.name} invites you to participate in a discussion"
  #   end

  #   mail(:from => from, :to => @email, :subject => "[#{options[:app_title]}] #{subject}")

  # end  

  private

end

