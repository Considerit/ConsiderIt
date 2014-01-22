class Dashboard::ClientErrorsController < Dashboard::DashboardController
  respond_to :json

  def index
    authorize! :show, ClientError

    rendered_admin_template = params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil

    render :json => {:account => current_tenant, :admin_template => rendered_admin_template}
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

    pp error_params
    error = ClientError.create! error_params.permit :type, :trace, :line, :message, :user_id, :session_id, :user_agent, :location, :ip, :browser, :version, :platform
    
    throw 'dsf'
    respond_to do |format|
      format.json {render :json => error}
    end

  end

end
