class UserController < ApplicationController

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

    if permit('update user', user) > 0 && params.has_key?("tags")

      new_tags = params["tags"]
      old_tags = user.tags || {}

      tags_config = current_subdomain.customization_json.fetch('user_tags', {})

      tags_config.each do |tag, vals|
        if new_tags.has_key?(tag)
          old_tags[tag] = new_tags[tag]
        elsif old_tags.has_key?(tag)
          old_tags.delete(tag)
        end
      end

      user.save 
    end

    dirty_key "/user/#{params[:id]}"
    render :json => []
  end


end
