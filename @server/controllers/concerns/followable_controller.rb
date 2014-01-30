class FollowableController < ApplicationController
  def index
    user_id = params[:user_id]
    followable_objects = {}
    User.find(params[:user_id]).follows.each do |follow|
      followable_objects[follow.followable_type] = {} if !(followable_objects.has_key?(follow.followable_type))
      followable_objects[follow.followable_type][follow.followable_id] = follow.root_object()
    end
    render :json => {:followable_objects => followable_objects}
  end

  def follow
    followable_type = params[:follows][:followable_type]
    followable_id = params[:follows][:followable_id]
    obj_to_follow = followable_type.constantize.find(followable_id)
    follow = obj_to_follow.follow!(current_user, :follow => true, :explicit => true)
    render :json => {:success => true, :follow => follow}.to_json
  end

  def unfollow
    user = User.find(params[:follows][:user_id])

    if (!current_user.nil? && user.id == current_user.id) || (session.has_key?(:limited_user) && session[:limited_user] == user.id)

      if params[:follows].has_key?(:unsubscribe_all) && params[:follows][:unsubscribe_all] == 'true'
        user.unsubscribe!
        render :json => {:success => true}
      else
        followable_type = params[:follows][:followable_type]
        followable_id = params[:follows][:followable_id]
        obj_to_follow = followable_type.constantize.find(followable_id)
        follow = obj_to_follow.follow!(user, :follow => params[:follows][:follow] && params[:follows][:follow] == 'true', :explicit => true)

        render :json => {:success => true, :follow => follow}.to_json
      end
    else
      render :json => {:success => false, :reason => 'Permission denied.'}
    end

  end

  # def unfollow
  #   # following an unsubscribe token link in an email
  #   @followable_id = params[:i]
  #   @followable_type = params[:m]
  #   @user = User.find(params[:u])
  #   @obj_to_follow = @followable_type.constantize.find(@followable_id)
  #   if params[:t] == ApplicationController.token_for_action(params[:u], @obj_to_follow, 'unfollow')
  #     render 'followable/unfollow'
  #   else 
  #     redirect_to root_path, :notice => "Cannot unsubscribe because that email link is expired."
  #   end
    
  # end 
  
end