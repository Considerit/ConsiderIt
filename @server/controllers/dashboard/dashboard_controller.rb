class Dashboard::DashboardController < ApplicationController

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :result => 'failed',
      :reason => current_user.nil? ? 'not logged in' : 'not authorized'
    }

    respond_to do |format|

      format.json do
        render :json => result 
      end
      format.html do
        if current_user && current_user.registration_complete
          render :json => result
        else
          session[:redirect_after_login] = request.path
          @not_logged_in = true
          render :template => "old/login", :layout => 'dash' 
        end
      end


    end

  end


  def render(*args)

    # #TODO: what does this do?
    if args && args.first.respond_to?('has_key?')
      args.first[:layout] = false if request.xhr? && args.first[:layout].nil?
    elsif args && args.last.respond_to?('has_key?')
      args.last[:layout] = false if request.xhr? && args.last[:layout].nil?
    else
      args.append({:layout => false}) if request.xhr?
    end

    @users = ActiveSupport::JSON.encode(ActiveRecord::Base.connection.select( "SELECT id,name,email,avatar_file_name,created_at,avatar_file_name,roles_mask, metric_influence, metric_points, metric_conversations,metric_opinions,metric_comments FROM users WHERE account_id=#{current_tenant.id}"))
    @current_tenant = current_tenant

    @public_root = Rails.application.config.action_controller.asset_host.nil? ? "" : Rails.application.config.action_controller.asset_host

    super
  end

  def process_admin_template
    render_to_string :partial => './admin'
  end
end