class UserController < ApplicationController
  respond_to :json
  def show
    puts("Current_user is #{current_user and current_user.id}")

    if params[:id] == '-1'
      render :json => {
               'key' => '/user/-1',
               'name' => 'anonymous',
               'avatar_file_name' => nil
             }
      return
    end
    
    id = params[:id]
    user = User.find_by_id(params[:id])
    puts("User #{params[:id]} is #{user}")
    render :json => {
             'key' => "/user/#{user.id}",
             'name' => user.name,
             'avatar_file_name' => user.avatar_file_name
           }
  end
end
