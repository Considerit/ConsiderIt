class UserController < ApplicationController
  respond_to :json
  def show
    if params[:id] == '-1'
      render :json => {
               'key' => '/user/-1',
               'name' => 'anonymous',
               'avatar_file_name' => nil
             }
      return
    end
    
    pp(params)
    id = params[:id]
    pp(id)
    user = User.find_by_id(params[:id])
    render :json => {
             'key' => "/user/#{user.id}",
             'name' => user.name,
             'avatar_file_name' => user.avatar_file_name
           }
  end  
end
