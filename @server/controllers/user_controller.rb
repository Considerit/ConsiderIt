class UserController < ApplicationController
  respond_to :json

  def index
    dirty_key "/users"
    render :json => []
  end

  def show
    if params[:id] == '-1'
      render :json => [{
               'key' => '/user/-1',
               'name' => 'anonymous',
               'avatar_file_name' => nil
             }]
      return
    end
    
    user = User.find(params[:id])
    dirty_key "/user/#{params[:id]}"
    render :json => []
  end
end
