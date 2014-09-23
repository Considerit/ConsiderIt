class LogController < ApplicationController
  respond_to :json

  def create
    entry = {
      who: current_user, 
      what: params[:what],
      where: params[:where],
      when: Time.now,
      details: params[:details] ? params[:details].to_json : nil, # this is a json object. Putting this right into the database seems like it could be a security issue.
      account_id: current_tenant.id
    }

    Log.create! entry
    render :json => {result: 'success'}
  end

end