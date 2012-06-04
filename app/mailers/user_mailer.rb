class UserMailer < ActionMailer::Base
  ActionMailer::Base.delivery_method = :mailhopper  
  layout 'email'
  include Devise::Mailers::Helpers

  ######### DEVISE MAILERS
  def confirmation_instructions(record, from_email = "no-reply@#{APP_CONFIG[:host]}")
    devise_mail(record, :confirmation_instructions, from_email)
  end

  def reset_password_instructions(record, from_email = "no-reply@#{APP_CONFIG[:host]}")
    devise_mail(record, :reset_password_instructions, from_email)
  end

end

#taken from https://github.com/plataformatec/devise/blob/master/lib/devise/mailers/helpers.rb
module Devise
  module Mailers
    module Helpers
      extend ActiveSupport::Concern

      included do
        include Devise::Controllers::ScopedViews
        attr_reader :scope_name, :resource
      end

      protected

      # Configure default email options
      def devise_mail(record, action, from_email = "no-reply@#{APP_CONFIG[:host]}")
        @scope_name = Devise::Mapping.find_scope!(record)
        @resource   = instance_variable_set("@#{devise_mapping.name}", record)
        mail headers_for(action, from_email)
      end

      def devise_mapping
        @devise_mapping ||= Devise.mappings[scope_name]
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


      def template_paths
        template_path = [self.class.mailer_name]
        template_path.unshift "#{@devise_mapping.scoped_path}/mailer" if self.class.scoped_views?
        template_path
      end

      # Setup a subject doing an I18n lookup. At first, it attemps to set a subject
      # based on the current mapping:
      #
      #   en:
      #     devise:
      #       mailer:
      #         confirmation_instructions:
      #           user_subject: '...'
      #
      # If one does not exist, it fallbacks to ActionMailer default:
      #
      #   en:
      #     devise:
      #       mailer:
      #         confirmation_instructions:
      #           subject: '...'
      #
      def translate(mapping, key)
        I18n.t(:"#{mapping.name}_subject", :scope => [:devise, :mailer, key],
          :default => [:subject, key.to_s.humanize])
      end
    end
  end
end