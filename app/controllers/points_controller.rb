class PointsController < ApplicationController
  protect_from_forgery
  
  def create
    proposal = Proposal.find_by_long_id(params[:long_id])

    create_params = {
        :nutshell => params[:point][:nutshell],
        :text => params[:point][:text],
        :is_pro => params[:point][:is_pro],
        :hide_name => params[:point][:hide_name],
        :comment_count => 0,
        :proposal_id => proposal.id,
        :long_id => proposal.long_id,
        :user_id => current_user ? current_user.id : nil,
        :published => false
    }

    point = Point.create! ActionController::Parameters.new(create_params).permit!
    #TODO: shouldn't this happen before?
    authorize! :create, point

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    session[proposal.id][:written_points].push(point.id)
    session[proposal.id][:included_points][point.id] = 1    
    session[proposal.id][:viewed_points].push([point.id, 7]) # own point has been seen
    
    respond_to do |format|
      format.json {render :json => point}
    end
  end

  def show

    point = Point.find params[:id]
    authorize! :read, point

    #todo: make this more efficient and natural
    comments = point.comments
    thanks = point.comments.map {|x| x.thanks.public_fields.all}.compact.flatten
    thanks.concat point.claims.map {|x| x.thanks.public_fields.all}.compact.flatten
    
    response = {
      :comments => comments.public_fields,
      :thanks => thanks
    }

    if current_tenant.assessment_enabled
      response.update({
        :assessment => point.assessment && point.assessment.complete ? point.assessment.public_fields : nil,
        :verdicts => Assessable::Verdict.all,
        :claims => point.assessment && point.assessment.complete ? point.assessment.claims.public_fields : nil,
        :already_requested_assessment => current_user && Assessable::Request.where(:assessable_id => point.id, :assessable_type => 'Point', :user_id => current_user.id).count > 0
      })
    end

    ApplicationController.reset_user_activities(session, point.proposal) if !session.has_key?(point.proposal.id)

    respond_to do |format|
      format.json {render :json => response}
      format.html { 
        proposal_data = point.proposal.full_data current_tenant, current_user, session[point.proposal_id], can?(:manage, point.proposal)
        proposal_data[:position] = ProposalsController.get_position_for_user(point.proposal, current_user, session)
        @current_proposal = proposal_data.to_json
        
        point = point.mask_anonymous current_user
        @current_point = {
          :associated => response,
          :point => point
        }.to_json
      }
    end
  end

  def update
    point = Point.find params[:id]
    authorize! :update, point

    update_params = {}

    if params[:point].has_key? :nutshell
      update_params[:nutshell] = params[:point][:nutshell]
    end
    if params[:point].has_key? :text
      update_params[:text] = params[:point][:text]
    end
    if params[:point].has_key? :hide_name
      update_params[:hide_name] = params[:point][:hide_name]
    end

    point.update_attributes! ActionController::Parameters.new(update_params).permit!
    
    if point.published
      ActiveSupport::Notifications.instrument("point:updated", 
        :model => point,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    respond_to do |format|
      format.json {render :json => point}
    end

  end

  def destroy
    return unless request.xhr?

    @point = Point.find params[:id]
    
    authorize! :destroy, @point

    ApplicationController.reset_user_activities(session, @point.proposal) if !session.has_key?(@point.proposal.id)
    
    session[@point.proposal_id][:written_points].delete(@point.id)
    session[@point.proposal_id][:included_points].delete(@point.id)  

    @point.destroy

    response = {:result => 'successful'}

    respond_to do |format|
      format.json {render :json => response}
    end


  end

  
  
end
