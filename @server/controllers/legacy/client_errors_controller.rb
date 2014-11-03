class Dashboard::ClientErrorsController < Dashboard::DashboardController
  respond_to :json

  def index
    authorize! :show, ClientError

    rendered_admin_template = params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil

    errors = ClientError.all.order(:created_at).reverse_order.limit(500)

    result = {:account => current_tenant, :admin_template => rendered_admin_template, :errors => errors}

    if request.xhr?
      render :json => result 
    else
      render "layouts/dash", :layout => false 
    end

  end

  def create
    authorize! :create, ClientError

    error_params = params['error']

    ua = UserAgent.parse(request.user_agent)
    more_params = {
      :session_id => request.session_options[:id],
      :ip => request.remote_ip,
      :user_agent => request.user_agent,
      :browser => ua.browser,
      :version => ua.version.to_s,
      :platform => ua.platform, 
      :user_id => current_user ? current_user.id : nil
    }

    error_params.update more_params

    error = ClientError.create! error_params.permit(:error_type, :trace, :line, :message, :user_id, :session_id, :user_agent, :location, :ip, :browser, :version, :platform)
    
    respond_to do |format|
      format.json {render :json => error}
    end

  end

end
