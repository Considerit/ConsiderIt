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

  def avatars
    
    respond_to do |format|

      if !session[:search_bot]        
        cache_key = "avatar-digest-#{current_subdomain.id}"
        avatars = Rails.cache.read(cache_key)
        if avatars.nil? || avatars == 0
          users = User.where("registered=1 AND b64_thumbnail IS NOT NULL AND INSTR(active_in, '\"#{current_subdomain.id}\"')")
          avatars = users.select([:id,:b64_thumbnail]).map {|user| "#avatar-#{user.id} { background-image: url('#{user.b64_thumbnail}');}"}.join(' ')
          Rails.cache.write(cache_key, avatars)
        end
      else
        avatars = ''
      end

      format.json { 
        render :json => {
          key: '/avatars',
          avatars: avatars
        }
      }
    end
  end

end
