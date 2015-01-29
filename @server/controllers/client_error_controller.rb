class ClientErrorController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    ## Store this somewhere instead of a puts
    ClientError.create trace: params[:stack],
                       message: params[:message],
                       line: params[:line_number],
                       ip: request.env['REMOTE_ADDR'],
                       user_agent: request.env["HTTP_USER_AGENT"],
                       user_id: current_user && current_user.id
    render :json => ["Thanks for the error report!"]
  end
end


