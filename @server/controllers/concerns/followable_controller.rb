class FollowableController < ApplicationController
  def index
    if authorized(target_user, params['u'], params['t'])
      followable_objects = {
        'Proposal' => {},
        'Point' => {}
      }

      for followable_type in followable_objects.keys
        # select all the objects of followable_type that target_user follows implicitly and explicitly
        case followable_type
        when 'Point'
          following = target_user.inclusions.map {|i| i.point} + \
                   target_user.comments.where(:commentable_type => 'Point').map {|c| c.root_object() } + \
                   target_user.follows.where(:follow => true, :followable_type => 'Point').map {|f| f.root_object() }

        when 'Proposal'
          following = target_user.opinions.published.map {|o| o.proposal} + \
                   target_user.follows.where(:follow => true, :followable_type => 'Proposal').map {|f| f.root_object() }
        end

        following = following.uniq.compact #remove dupes and nils
        # store in a structure that the client can easily parse
        following.each {|root_obj| followable_objects[followable_type][root_obj.id] = root_obj }

        # remove objs that have been explicitly unfollowed already
        target_user.follows.where(:follow => false, :followable_type => followable_type).each do |f|
          followable_objects[f.followable_type].delete(f.followable_id)
        end

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
    my_params = params[:follows]

    if authorized(target_user, my_params['u'], my_params['t'])
      if my_params.has_key?(:unsubscribe_all) && my_params[:unsubscribe_all] == 'true'
        target_user.unsubscribe!
        render :json => {:success => true}
      else
        followable_type = my_params[:followable_type]
        followable_id = my_params[:followable_id]
        obj_to_follow = followable_type.constantize.find(followable_id)
        follow = obj_to_follow.follow!(target_user, :follow => false, :explicit => true)

        render :json => {:success => true, :follow => follow}.to_json
      end
    else
      render :json => {:success => false, :reason => 'Permission denied.'}
    end

  end

  private

  def target_user
    data = params.has_key?(:follows) ? params[:follows] : params
    u = data['u']
    if u && u.length > 0
      User.find_by_email(u)
    else
      User.find(data[:user_id])
    end
  end

  def authorized(target_user, u = '', t = '')
    encrypted = ApplicationController.arbitrary_token("#{u}#{target_user.unique_token}#{current_tenant.identifier}")
    valid_token = encrypted == t
    (current_user && target_user.id == current_user.id) || valid_token
  end
  
end