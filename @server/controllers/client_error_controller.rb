class ClientErrorController < ApplicationController
  def create
    ## Store this somewhere instead of a puts
    ClientError.create trace: params[:stack],
                       ip: request.env['REMOTE_ADDR'],
                       user_agent: request.env["HTTP_USER_AGENT"],
                       user_id: current_user && current_user.id
    render :json => ["Thanks for the error report!"]
  end
end


