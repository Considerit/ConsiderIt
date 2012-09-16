class Followable::FollowableController < ApplicationController
  def follow
    followable_type = params[:follows][:followable_type]
    followable_id = params[:follows][:followable_id]
    obj_to_follow = followable_type.constantize.find(followable_id)
    obj_to_follow.follow!(current_user, :follow => true, :explicit => true)
    render :json => {:success => true}.to_json
  end

  def unfollow

    if params.has_key? :t
      # following an unsubscribe token link
      followable_id = params[:i]
      followable_type = params[:m]
      user = User.find(params[:u])
      obj_to_follow = followable_type.constantize.find(followable_id)
      if params[:t] == ApplicationController.token_for_action(params[:u], obj_to_follow, 'unfollow')
        obj_to_follow.follow!(user, :follow => false, :explicit => true)
      end
      #TODO: get the model's path to redirect to
      redirect_to root_path, :notice => "You have unsubscribed to the #{followable_type.downcase}"
    else
      followable_type = params[:follows][:followable_type]
      followable_id = params[:follows][:followable_id]
      obj_to_follow = followable_type.constantize.find(followable_id)
      obj_to_follow.follow!(current_user, :follow => false, :explicit => true)
      render :json => {:success => true}.to_json
    end
  end 


end