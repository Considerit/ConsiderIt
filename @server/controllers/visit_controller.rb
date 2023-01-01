class VisitController < ApplicationController

  def index
    dirty_key "/visits"
    render :json => []
  end

end
