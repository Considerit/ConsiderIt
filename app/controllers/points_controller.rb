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


    # @proposal = Proposal.find_by_long_id(params[:long_id])

    # redirect_to root_path if @proposal.nil?

    # @user = current_user

    # ApplicationController.reset_user_activities(session, @proposal) if !session.has_key?(@proposal.id)
    
    # if !current_user.nil?
    #   @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
    # else
    #   @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
    # end
    
    # qry = @proposal.points.viewable
    # pros_and_cons = false
    # if ( params.key?(:cons_only) && params[:cons_only] == 'true'  )
    #   qry = qry.cons
    # elsif ( params.key?(:pros_only) && params[:pros_only] == 'true' )
    #   qry = qry.pros
    # else
    #   pros_and_cons = true
    # end

    # @bucket = params[:bucket]
    # if !@bucket
    #   redirect_to root_path
    #   return
    # end

    # @filter = params.key?(:filter) ? params[:filter] : nil
    # @positions = @proposal.positions.published
    # if @bucket == 'all' || @bucket == ''
    #   @filter ||= 'popularity'
    #   group_name = 'all'
    #   case @filter
    #   when 'popularity'
    #     qry = qry.ranked_overall
    #   when 'unify'
    #     qry = qry.ranked_unify
    #   when 'divisive'
    #     qry = qry.ranked_divisive
    #   else
    #     raise 'Unrecognized sort filter'
    #   end

    # elsif @bucket[0..3] == 'user'
    #   group_name = 'user'
    #   user_points_id = @bucket[5..@bucket.length].to_i
    #   @user_points = User.find(user_points_id)
    #   qry = qry.joins(:inclusions).where(:inclusions => { :user_id => user_points_id})    
    # elsif @bucket == 'margin'
    #   group_name = 'margin'
    #   qry = qry.not_included_by(current_user, session[@proposal.id][:included_points].keys, session[@proposal.id][:deleted_points].keys).ranked_persuasiveness  
    # else
    #   ## specific voter segment...
    #   @bucket = @bucket.to_i
    #   group_name = self.stance_name(@bucket)
    #   qry = qry.ranked_for_stance_segment(@bucket) #.where("importance_#{@bucket} > 0").order("importance_#{@bucket} DESC")
    #   @positions = @proposal.positions.published.where( :stance_bucket => @bucket )    
    # end
    
    # if params.key?(:page)
    #   @page = params[:page].to_i
    # else
    #   @page = 1
    # end

    # if group_name == 'user'
    #   @con_points = qry.cons.page( @page ).per( 50 )
    #   @pro_points = qry.pros.page( @page ).per( 50 )
    #   points = @con_points + @pro_points
    # elsif pros_and_cons
    #   @con_points = qry.cons.page( @page ).per( POINTS_PER_PAGE_RESULTS )
    #   @pro_points = qry.pros.page( @page ).per( POINTS_PER_PAGE_RESULTS )
    #   points = @con_points + @pro_points
    # else 
    #   points = qry.page( @page ).per( @bucket == 'margin' ? POINTS_PER_PAGE_MARGIN : POINTS_PER_PAGE_RESULTS )
    
    # end
    
    # if group_name == 'user'
    #   context = 10 # looking through someone else's included points
    # elsif pros_and_cons
    #   context = 5  # initial load of voter segment on proposals page
    # elsif group_name == 'margin'
    #   context = 2 # pagination requested on position page
    # else
    #   context = 6 # pagination requested on proposals page
    # end
    
    # # StudyData.create!({
    # #   :category => 4,
    # #   :user => current_user,
    # #   :session_id => request.session_options[:id],
    # #   :position => @position,
    # #   :proposal => @proposal,
    # #   :detail1 => @bucket,
    # #   :ival => context
    # # })

    # ApplicationController.reset_user_activities(session, @proposal) if !session.has_key?(@proposal.id)
    # if context
    #   points.each do |pnt|
    #     session[@proposal.id][:viewed_points].push([pnt.id, context])
    #   end          
    # end
        
    # #TODO: refactor to make the logic behind these calls easier to follow & explicit
    # if pros_and_cons
    #   resp = { :points => render_to_string(:partial => "points/pro_con_list", :locals => { :bucket => @bucket, :dynamic => false, :points => {:pros => @pro_points, :cons => @con_points} })   }
    # else
    #   origin = group_name == 'margin' ? 'margin' : 'board'
    #   resp = { :points => render_to_string(:partial => "points/column", :locals => { :points => points, :is_pro => params.key?(:pros_only), :origin => origin, :bucket => @bucket, :enable_pagination => false, :page => @page }) }
    # end
    
    # render :json => resp.to_json
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
      render :json => {:comments => point.comments.public_fields}
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

    update_params = {
        :nutshell => params[:point][:nutshell],
        :text => params[:point][:text],
        :hide_name => params[:point][:hide_name],
    }

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
