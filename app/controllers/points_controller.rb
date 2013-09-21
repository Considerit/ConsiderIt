class PointsController < ApplicationController

  protect_from_forgery
  respond_to :json
  
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

    point = Point.create!(create_params)
    #TODO: shouldn't this happen before?
    authorize! :create, point

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    session[proposal.id][:written_points].push(point.id)
    session[proposal.id][:included_points][point.id] = 1    
    session[proposal.id][:viewed_points].push([point.id, 7]) # own point has been seen
    
    render :json => point

  end

  def show

    if request.xhr?
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
          :already_requested_assessment => Assessable::Request.where(:assessable_id => point.id, :assessable_type => 'Point', :user_id => current_user.id).count > 0
        })
      end

      render :json => response
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

    point.update_attributes! update_params
    
    if point.published
      ActiveSupport::Notifications.instrument("point:updated", 
        :model => point,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    render :json => point

  end

  def destroy

    @point = Point.find params[:id]
    
    authorize! :destroy, @point

    ApplicationController.reset_user_activities(session, @point.proposal) if !session.has_key?(@point.proposal.id)
    
    session[@point.proposal_id][:written_points].delete(@point.id)
    session[@point.proposal_id][:included_points].delete(@point.id)  

    @point.destroy

    response = {:result => 'successful'}
    render :json => response
  end

  
  
end
