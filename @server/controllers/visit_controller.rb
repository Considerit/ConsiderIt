class VisitController < ApplicationController

  def index
    authorize! 'update subdomain'

    dirty_key "/visits"
    render :json => []
  end

end
