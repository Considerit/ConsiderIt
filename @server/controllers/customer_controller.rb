class CustomerController < ApplicationController
  protect_from_forgery
  respond_to :json

  def show
    render :json => current_tenant
  end

  def update
    authorize! :update, Account
    
    # not available yet
    render :json => current_tenant, :status => :method_not_allowed
  end

end