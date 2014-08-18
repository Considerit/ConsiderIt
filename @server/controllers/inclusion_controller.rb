class InclusionsController < ApplicationController
  protect_from_forgery

  respond_to :json
  
  def create
    authorize! :create, Inclusion

    # MIKE SAYS: It looks like this function does a lot of session
    # stuff... but I think we don't need it anymore so I'm not going
    # to fix it unless this exception gets thrown
    raise "Mike doesn't think this function gets called anymore. You've proven him wrong!"

    proposal = Proposal.find_by_long_id params[:proposal_id]

    params[:proposal_id] = proposal.id
    point = Point.published.find params[:point_id]

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    # don't include a point that has already been included ...
    # not going though CanCan because of session query requirement
    if (current_user \
        && (!session[proposal.id][:deleted_points].has_key?(point.id) \
           && current_user.inclusions.where( :point_id => point.id ).count > 0)) \
       || session[proposal.id][:included_points].has_key?(point.id)
      render :json => { :success => false }.to_json
      return
    end

    session[proposal.id][:included_points][point.id] = 1
    session[proposal.id][:viewed_points].push([point.id,-1])

    render :json => { :success => true }
  end
  

  def destroy
    point = Point.find params[:point_id] 
    proposal = point.proposal

    ApplicationController.reset_user_activities(session, point.proposal) if !session.has_key?(point.proposal.id)

    destroyed = false

    if current_user
      inc = current_user.inclusions.where(:point_id => point.id).first
      if inc
        session[proposal.id][:deleted_points][point.id] = 1
      end
    end

    authorize! :destroy, inc || Inclusion.new

    session[proposal.id][:included_points].delete point.id
    session[proposal.id][:written_points].delete(point.id) if session[point.proposal_id][:written_points].include? point.id

    if ((!point.published && point.user_id.nil?) || (current_user && current_user.id == point.user_id)) && point.inclusions.count < 2  #can?(:destroy, point) # not using the ability otherwise whenever an admin removes a point from their list, they destroy it!
      authorize! :destroy, point

      # if this point is a top pro or con, need to trigger proposal update
      update_proposal_metrics = proposal.top_pro == point.id || proposal.top_con == point.id      
      update_opinion = current_user && opinion = current_user.opinions.find_by_proposal_id(point.proposal_id)

      point.destroy

      opinion.recache if update_opinion
      proposal.update_metrics if update_proposal_metrics

      destroyed = true
    end

    render :json => { :success => true, :destroyed => destroyed }
  end
end
