class AccountsController < ApplicationController
  #include ActsAsFollowable::ControllerMethods

  def update
    if !current_user.is_admin?
      redirect_to root_path, :notice => 'Insufficient permissions.'
      return
    end

    # TODO: explicitly grab params
    current_tenant.update_attributes(params[:account])
    redirect_to request.referrer

  end

end