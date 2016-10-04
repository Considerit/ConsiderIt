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

  def update 
    user = User.find(params[:id])
    if permit('update user', user) > 0
      fields = ["tags"]
      updates = params.select{|k,v| fields.include? k}

      fields.each do |f|
        if !updates.has_key?(f)
          updates[f] = user[f]
        end
      end

      if updates.has_key? :tags
        updates[:tags] = JSON.dump updates[:tags]
      end

      user.update_attributes! updates
    end

    dirty_key "/user/#{params[:id]}"
    render :json => []
  end


end
