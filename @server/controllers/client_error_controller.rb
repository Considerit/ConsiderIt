class ErrorController < ApplicationController
  def create
    ## Store this somewhere instead of a puts
    puts("Client error: #{params.to_json}")
    render :json => ["Thanks for the error report!"]
  end
end
