class ThanksController < ApplicationController
  protect_from_forgery
  respond_to :json


  def create
    #   - need to be logged in
    #   - can't be author 
    #   - can only do it once  #solved via uniqueness constraint on model
    
    params[:thank][:user_id] = current_user.id
    params[:thank][:account_id] = current_tenant.id

    if params[:thank][:thankable_id] == 'Claim'
      params[:thank][:thankable_id] = "Assessable::Claim"
    end
    
    thank = Thank.new params[:thank]
    authorize! :create, thank

    thank.save

    # root_obj = thank.root_object
    # root_obj.thanks_count = root_obj.thanks.count
    # root_obj.save

    render :json => thank
  end

  def destroy

    thank = Thank.find params[:id]
    authorize! :destroy, thank

    # root_obj = thank.root_object
    # root_obj.thanks_count = root_obj.thanks.count
    # root_obj.save

    thank.destroy

    render :json => {:success => true}
  end

end
