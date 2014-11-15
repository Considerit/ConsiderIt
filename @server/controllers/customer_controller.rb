class CustomerController < ApplicationController
  respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :errors => [current_user.nil? ? 'not logged in' : 'not authorized']
    }
    render :json => result 
    return
  end

  def new
    render :json => []
  end

  def create
    authorize! :create, Account

    errors = []

    # TODO: sanitize / make sure has url-able characters
    subdomain = params[:subdomain]

    existing = Account.find_by_identifier(subdomain)
    if existing
      errors.push "The #{subdomain} subdomain already exists. Contact us for more information."
    else
      new_customer = Account.new :identifier => subdomain
      roles = new_customer.user_roles
      roles['admin'].push "/user/#{current_user.id}"
      new_customer.roles = JSON.dump roles
      new_customer.save
    end

    if errors.length > 0
      render :json => [{errors: errors}]
    else
      render :json => [{identifier: new_customer.identifier}]
    end
  end

  def show
    dirty_key '/customer'
    render :json => []
  end

  def update
    account = Account.find(params[:id])
    authorize! :update, Account
    if account.id != current_tenant.id #&& !current_user.super_admin
      # for now, don't allow modifying non-current tenant
      raise new CanCan::AccessDenied
    end

    fields = ['moderate_points_mode', 'moderate_comments_mode', 'moderate_proposals_mode', 'about_page_url', 'contact_email', 'app_title', 'project_url', 'requires_civility_pledge_on_registration']
    attrs = params.select{|k,v| fields.include? k}

    if params.has_key? 'roles'
      attrs['roles'] = JSON.dump params['roles']
    end

    current_tenant.update_attributes! attrs

    # if current_tenant.enable_hibernation && params[:account].has_key?('enable_hibernation')
    #   current_tenant.proposals.open_to_public.active.update_all(active: false)      
    # end

    dirty_key '/customer'
    render :json => []

  end

end