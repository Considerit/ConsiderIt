class PointController < ApplicationController
  protect_from_forgery

  def show
    point = Point.find params[:id]
    authorize! :read, point

    render :json => point.as_json
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

    point.save

    #ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    # Include into the user's opinion
    opinion = Opinion.where(:user_id => current_user.id,
                            :proposal => proposal).first
    point.seen_by(current_user)
    opinion.include(point)

    original_id = key_id(params[:key])
    result = point.as_json
    result['key'] = "/point/#{point.id}?original_id=#{original_id}"
    pp(result)

    remap_key(params[:key], "/point/#{point.id}")
    # # This session stuff is broken!  Because the session gets cleared
    # # when we switch accounts.  Sucks.  Need a new way to store this.
    # session[:remapped_keys] ||= {}
    # session[:remapped_keys][params[:key]] = "/point/#{point.id}"

    # Now let's return the proposal's changes too
    proposal_json = proposal.proposal_data(can?(:manage, proposal))

    render :json => [result, proposal_json] + affected_objects()
  end

  def update
    point = Point.find params[:id]
    #authorize! :update, point

    if params.has_key?(:is_following) && params[:is_following] != point.is_following()
      # if is following has changed, that means the user has explicitly expressed 
      # whether they want to be subscribed or not
      point.follow! current_user, {:follow => params[:is_following], :explicit => true}
    end

    fields = ["nutshell", "text", "hide_name"]
    updates = params.select{|k,v| fields.include? k}

    point.update_attributes! ActionController::Parameters.new(updates).permit!

    if point.published
      ActiveSupport::Notifications.instrument("point:updated", 
        :model => point,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    render :json => point.as_json
  end

  def destroy
    point = Point.find params[:id]
    proposal = point.proposal
    
    authorize! :destroy, point

    point.destroy
    proposal.opinions.where("point_inclusions like '%#{params[:id]}%'").map do |o|
      o.recache
      dirty_key("/opinion/#{o.id}")
    end

    dirty_key("/proposal/#{proposal.id}") #because /points is changed...

    render :json => affected_objects()
  end
 
end
