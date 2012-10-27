class Followable::FollowableController < ApplicationController
  def follow
    followable_type = params[:follows][:followable_type]
    followable_id = params[:follows][:followable_id]
    obj_to_follow = followable_type.constantize.find(followable_id)
    obj_to_follow.follow!(current_user, :follow => true, :explicit => true)
    render :json => {:success => true}.to_json
  end

  def unfollow
    # following an unsubscribe token link in an email
    @followable_id = params[:i]
    @followable_type = params[:m]
    @user = User.find(params[:u])
    @obj_to_follow = @followable_type.constantize.find(@followable_id)
    if params[:t] == ApplicationController.token_for_action(params[:u], @obj_to_follow, 'unfollow')
      render 'followable/unfollow'
    else 
      redirect_to root_path, :notice => "Cannot unsubscribe because that email link is expired."
    end
    
  end 

  def unfollow_create
    user = User.find(params[:follows][:user_id])

    if params[:follows].has_key?(:unsubscribe_all) && params[:follows][:unsubscribe_all] == 'true'
      user.unsubscribe!
      redirect_to root_path, :notice => "You have unsubscribed to all notifications."
    else
      followable_type = params[:follows][:followable_type]
      followable_id = params[:follows][:followable_id]
      obj_to_follow = followable_type.constantize.find(followable_id)
      obj_to_follow.follow!(user, :follow => false, :explicit => true)
      if request.xhr?
        render :json => {:success => true}.to_json
      else
        redirect_to root_path, :notice => "You have unsubscribed to the #{followable_type.downcase}."
      end
    end

  end

end