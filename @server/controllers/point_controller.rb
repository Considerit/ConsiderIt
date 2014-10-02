class PointController < ApplicationController
  protect_from_forgery

  def show
    point = Point.find params[:id]
    authorize! :read, point

    dirty_key "/point/#{params[:id]}"
    render :json => []
  end


  def create
    # Validate by filtering out unwanted fields
    # todo: validate data types too
    fields = ['nutshell', 'text', 'is_pro', 'hide_name', 'proposal']
    point = params.select{|k,v| fields.include? k}

    # Set private values
    point['proposal'] = proposal = Proposal.find(key_id(point['proposal']))
    point['comment_count'] = 0
    point['long_id'] = point['proposal'].long_id
    point['published'] = false
    point['user_id'] = current_user && current_user.id || nil

    point = Point.new ActionController::Parameters.new(point).permit!

    #TODO: look into cancan to figure out how we can move this earlier in the method
    authorize! :create, point

    opinion = Opinion.where(:user_id => current_user.id,
                            :proposal => proposal).first

    if !proposal
      raise "Error! No proposal matching '#{point['proposal']}'"
    end
    if !opinion
      raise "Error! No opinion for user #{current_user.id} and proposal #{proposal.id}"
    end

    if opinion.published
      point.publish
    else
      point.save
    end

    # Include into the user's opinion
    opinion.include(point)

    original_id = key_id(params[:key])
    result = point.as_json
    result['key'] = "/point/#{point.id}?original_id=#{original_id}"

    remap_key(params[:key], "/point/#{point.id}")

    dirty_key "/proposal/#{proposal.id}"

    # # This session stuff is broken!  Because the session gets cleared
    # # when we switch accounts.  Sucks.  Need a new way to store this.
    # session[:remapped_keys] ||= {}
    # session[:remapped_keys][params[:key]] = "/point/#{point.id}"

    write_to_log({
      :what => 'wrote new point',
      :where => request.fullpath,
      :details => {:point => "/point/#{point.id}"}
    })

    #TODO: don't know how to dirty and handle the point key in compile_dirty_objects
    render :json => [result]
  end

  def update
    point = Point.find params[:id]
    #authorize! :update, point

    # if params.has_key?(:is_following) && params[:is_following] != point.following(current_user)
    #   # if is following has changed, that means the user has explicitly expressed 
    #   # whether they want to be subscribed or not
    #   point.follow! current_user, {:follow => params[:is_following], :explicit => true}
    # end

    fields = ["nutshell", "text", "hide_name"]
    updates = params.select{|k,v| fields.include? k}

    point.update_attributes! ActionController::Parameters.new(updates).permit!

    if point.published
      write_to_log({
        :what => 'edited a point',
        :where => request.fullpath,
        :details => {:point => "/point/#{point.id}"}
      })

      ActiveSupport::Notifications.instrument("point:updated", 
        :model => point,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    dirty_key "/point/#{params[:id]}"
    render :json => []
  end

  def destroy
    point = Point.find params[:id]
    proposal = point.proposal
    
    authorize! :destroy, point

    point.destroy
    proposal.opinions.where("point_inclusions like '%#{params[:id]}%'").map do |o|
      o.recache
      dirty_key "/opinion/#{o.id}"
    end

    dirty_key("/proposal/#{proposal.id}") #because /points is changed...

    render :json => []
  end
 
end
