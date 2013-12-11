class AccountsController < Dashboard::DashboardController
  respond_to :json

  def show
    authorize! :show, Account

    rendered_admin_template = params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil

    render :json => {:account => current_tenant, :admin_template => rendered_admin_template}
  end

  def update
    authorize! :update, Account

    if !current_user.is_admin?
      redirect_to root_path, :notice => 'Insufficient permissions.'
      return
    end

    # TODO: explicitly grab params
    current_tenant.update_attributes(params[:account])

    if current_tenant.enable_hibernation && params[:account].has_key?('enable_hibernation')
      current_tenant.proposals.open_to_public.active.update_all(active: false)      
    end
    render :json => current_tenant

  end

end