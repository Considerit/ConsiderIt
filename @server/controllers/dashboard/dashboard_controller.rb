class Dashboard::DashboardController < ApplicationController

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :result => 'failed',
      :reason => current_user.nil? ? 'not logged in' : 'not authorized'
    }

    if request.xhr?
      render :json => result 
    else
      if current_user && current_user.registration_complete
        render :json => result
      else
        session[:redirect_after_login] = request.path
        @not_logged_in = true
        render :template => "old/login", :layout => 'dash' 
      end
    end

  end


  def render(*args)

    # #TODO: what does this do?
    # if args && args.first.respond_to?('has_key?')
    #   args.first[:layout] = false if request.xhr? && args.first[:layout].nil?
    # elsif args && args.last.respond_to?('has_key?')
    #   args.last[:layout] = false if request.xhr? && args.last[:layout].nil?
    # else
    #   args.append({:layout => false}) if request.xhr?
    # end

    @users = ActiveSupport::JSON.encode(ActiveRecord::Base.connection.select( "SELECT id,name,email,avatar_file_name,created_at,avatar_file_name,roles_mask, metric_influence, metric_points, metric_conversations,metric_opinions,metric_comments FROM users WHERE account_id=#{current_tenant.id}"))
    @current_tenant = current_tenant
    active_proposals = Proposal.open_to_public.active.browsable
    inactive_proposals = Proposal.open_to_public.inactive.browsable

    proposals_active_count = active_proposals.count
    proposals_inactive_count = inactive_proposals.count


    proposals = current_tenant.enable_hibernation ? inactive_proposals : active_proposals


    top = []
    top_con_qry = proposals.where 'top_con IS NOT NULL'
    if top_con_qry.count > 0
      top += top_con_qry.select(:top_con).map {|x| x.top_con}.compact
    end

    top_pro_qry = proposals.where 'top_pro IS NOT NULL' 
    if top_pro_qry.count > 0
      top += top_pro_qry.select(:top_pro).map {|x| x.top_pro}.compact
    end
    
    top_points = {}
    Point.where('id in (?)', top).public_fields.each do |pnt|
      top_points[pnt.id] = pnt
    end

    @opinions = {}
    if current_user
      hidden_proposals = Proposal.content_for_user(current_user)
      hidden_proposals.each do |hidden|          
        top_points[hidden.top_pro] = Point.find(hidden.top_pro) if hidden.top_pro
        top_points[hidden.top_con] = Point.find(hidden.top_con) if hidden.top_con
      end
      proposals += hidden_proposals
      @opinions = current_user.opinions.published
    end


    @proposals = {
      :proposals => proposals,
      :points => top_points.values,
      :proposals_active_count => proposals_active_count,
      :proposals_inactive_count => proposals_inactive_count,
    }

    
    super
  end

  def process_admin_template
    render_to_string :partial => './admin'
  end
end