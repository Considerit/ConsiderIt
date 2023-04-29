class ListController < ApplicationController
  def index
    authorize!("read proposal", current_subdomain)    

    dirty_key '/lists'
    render :json => []    
  end

  def show
    authorize!("read proposal", current_subdomain)    
    dirty_key "/list/#{params[:list_name]}"
    render :json => []
  end



end
