#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class AccountsController < ApplicationController
  #include ActsAsFollowable::ControllerMethods

  def update
    if !current_user.is_admin?
      redirect_to root_path, :notice => 'Insufficient permissions.'
      return
    end

    current_tenant.update_attributes(params[:account])
    redirect_to request.referrer

  end

end