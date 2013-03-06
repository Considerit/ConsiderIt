class PointsController < ApplicationController
  #include ActsAsFollowable::ControllerMethods

  protect_from_forgery

  respond_to :json #, :html
  
  # POINTS_PER_PAGE_MARGIN = 3
  # POINTS_PER_PAGE_RESULTS = 4

  ########
  ##
  # handles calls from:
  #     paginate OTHER's pros OR cons; 
  #     initial load of voter segment's pros AND cons; 
  #     paginate voter segment's pros OR cons;   
  #     initial load of self's pros AND cons
  #     paginate self's pros OR cons
  #     
  #########
  def index


  end
  
  def create
    proposal = Proposal.find_by_long_id(params[:long_id])

    create_params = {
        :nutshell => params[:point][:nutshell],
        :text => params[:point][:text],
        :is_pro => params[:point][:is_pro],
        :hide_name => params[:point][:hide_name],
        :comment_count => 0,
        :proposal_id => proposal.id,
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
    # begin
    #   @point = Point.find(params[:id])
    # rescue
    #   redirect_to root_path, :notice => 'Cannot find that point. The author may have deleted it.'
    #   return
    # end

    # @proposal = Proposal.find_by_long_id(params[:long_id])
    # redirect_to root_path if @proposal.nil? || @proposal.id != @point.proposal_id

    # authorize! :read, @point

    # if request.xhr?
    #   origin = params[:origin]
    #   point_details = render_to_string :partial => "points/details", :locals => { :point => @point, :origin => origin}
    #   render :json => { :details => point_details }        
    # else
    #   render
    # end

    if request.xhr?
      point = Point.find params[:id]
      authorize! :read, point
      render :json => {
        :comments => point.comments.public_fields,
        :assessment => point.assessment && point.assessment.complete ? point.assessment.public_fields : nil,
        :claims => point.assessment && point.assessment.complete ? point.assessment.claims.public_fields : nil,
        :num_assessment_requests => point.assessment ? point.assessment.requests.count : nil,
        :already_requested_assessment => point.assessment ? !current_user.nil? && point.assessment.requests.where(:user_id => current_user.id).count > 0 : nil
      }
    end
  end

  def update
    #@proposal = Proposal.find_by_long_id(params[:long_id])
    # if current_user
    #   @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
    # else
    #   @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
    # end
    #@user = current_user
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

  def points_for_user
    render :json => current_user.points.published.where(:hide_name => true).joins(:proposal).select('proposals.long_id, points.id, points.is_pro')
  end
  
  
end
