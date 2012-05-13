class UserMailer < ActionMailer::Base
  include Devise::Mailers::Helpers

  def proposal_subscription(user, pnt, options)
    @user = user
    @point = pnt
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] new #{@point.is_pro ? 'pro' : 'con'} point for \"#{@point.proposal.title}\"")
  end

  def position_subscription(user, position, options)
    @user = user
    @position = position
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] new review #{@point.proposal.category} for \"#{@point.proposal.title}\"")
  end  

  def someone_discussed_your_point(user, pnt, comment, options)
    @user = user
    @point = pnt
    @comment = comment
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end

  def someone_discussed_your_position(user, position, comment, options)
    @user = user
    @position = position
    @comment = comment
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] new comment on your review")
  end  

  def someone_commented_on_thread(user, obj, comment, options)
    @user = user
    @comment = comment
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"

    if obj.commentable_type == 'Point'
      @point = obj
      mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{@comment.user.name} also commented on #{@point.user.name}'s #{@point.is_pro ? 'pro' : 'con'} point")
    elsif obj.commentable_type == 'Position'
      @position = obj
      mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{@comment.user.name} also commented on #{@position.user.name}'s review")
    end
  end

  def someone_commented_on_an_included_point(user, pnt, comment, options)
    @user = user
    @point = pnt
    @comment = comment
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end

  def someone_reflected_your_point(user, bullet, comment, options)
    @user = user
    @bullet = bullet
    @comment = comment
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
        
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{@bullet.user.name} summarized your comment")
  end

  def your_reflection_was_responded_to(user, response, bullet, comment, options)
    @user = user
    @bullet = bullet
    @comment = comment
    @response = response
    @host = options[:host]
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => options[:from], :to => email_with_name, :subject => "[#{options[:app_title]}] #{@comment.user.name} responded to your summary")
  end

  ######### DEVISE MAILERS
  def confirmation_instructions(record, from_email = "no-reply@#{APP_CONFIG[:host]}")
    devise_mail(record, :confirmation_instructions, from_email)
  end

  def reset_password_instructions(record, from_email = "no-reply@#{APP_CONFIG[:host]}")
    devise_mail(record, :reset_password_instructions, from_email)
  end

  private
    def current_tenant
      ApplicationController.find_current_tenant(request)
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