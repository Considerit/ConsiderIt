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
    email_with_name = "#{@user.name} <#{@user.email}>"

    subject = "please confirm your email"
    
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{subject}")

  end

  def reset_password_instructions(record)
    from_email = record.account.contact_email
    devise_mail(record, :reset_password_instructions, from_email)
  end

end

#taken from https://github.com/plataformatec/devise/blob/master/lib/devise/mailers/helpers.rb
module Devise
  module Mailers
    module Helpers
      protected

      # Configure default email options
      def devise_mail(record, action, from_email = "no-reply@#{APP_CONFIG[:host]}")
        @scope_name = Devise::Mapping.find_scope!(record)
        @resource   = instance_variable_set("@#{devise_mapping.name}", record)
        mail headers_for(action, from_email)
      end

      def headers_for(action, from_email)

        headers = {
          :subject       => translate(devise_mapping, action),
          :from          => from_email,
          :to            => resource.email,
          :template_path => template_paths
        }

        if resource.respond_to?(:headers_for)
          headers.merge!(resource.headers_for(action))
        end

        unless headers.key?(:reply_to)
          headers[:reply_to] = headers[:from]
        end

        headers
      end
    end
  end
end