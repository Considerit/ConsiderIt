class ClientErrorController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    ## Store this somewhere instead of a puts
    e = ClientError.create trace: params[:stack],
                           message: params[:message],
                           line: params[:line_number],
                           ip: request.env['REMOTE_ADDR'],
                           user_agent: request.env["HTTP_USER_AGENT"],
                           user_id: current_user && current_user.id

    begin
      raise "ClientError: \"#{e.message}\" from #{e.ip} user #{e.user_id}"
    rescue => err
      ExceptionNotifier.notify_exception err, :env => request.env
    end
    
    render :json => ["Thanks for the error report!"]
  end
end


