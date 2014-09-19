class CustomerController < ApplicationController
  protect_from_forgery
  respond_to :json

  def show
    dirty_key '/customer'
    render :json => []
  end

  def update
    # not available yet

    authorize! :update, Account
    dirty_key '/customer'
    render :json => [], :status => :method_not_allowed
  end

end