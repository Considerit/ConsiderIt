class FollowableController < ApplicationController
  def index
    target_user = User.find(params[:user_id])
    if authorized(target_user)
      followable_objects = {}
      target_user.follows.each do |follow|
        followable_objects[follow.followable_type] = {} if !(followable_objects.has_key?(follow.followable_type))
        followable_objects[follow.followable_type][follow.followable_id] = follow.root_object()
      end
      render :json => {:success => true, :followable_objects => followable_objects}
    else
      render :json => {:success => false, :reason => "Permission denied"}
    end
  end

  def follow
    if current_user
      followable_type = params[:follows][:followable_type]
      followable_id = params[:follows][:followable_id]
      obj_to_follow = followable_type.constantize.find(followable_id)
      follow = obj_to_follow.follow!(current_user, :follow => true, :explicit => true)
      render :json => {:success => true, :follow => follow}.to_json
    else
      render :json => {:success => false, :reason => "Not logged in"}.to_json
    end
  end

  def unfollow

    target_user = User.find(params[:follows][:user_id])

    if authorized(target_user)
      if params[:follows].has_key?(:unsubscribe_all) && params[:follows][:unsubscribe_all] == 'true'
        target_user.unsubscribe!
        render :json => {:success => true}
      else
        followable_type = params[:follows][:followable_type]
        followable_id = params[:follows][:followable_id]
        obj_to_follow = followable_type.constantize.find(followable_id)
        follow = obj_to_follow.follow!(target_user, :follow => params[:follows][:follow] && params[:follows][:follow] == 'true', :explicit => true)

        render :json => {:success => true, :follow => follow}.to_json
      end
    else
      render :json => {:success => false, :reason => 'Permission denied.'}
    end

  end

  private

  def authorized(target_user)
    (!current_user.id.nil? && target_user.id == current_user.id) || (session.has_key?(:limited_user) && session[:limited_user] == target_user.id)
  end
  
end