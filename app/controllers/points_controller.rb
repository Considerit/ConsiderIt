#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class PointsController < ApplicationController
  #include ActsAsFollowable::ControllerMethods

  protect_from_forgery

  respond_to :json, :html
  
  POINTS_PER_PAGE_MARGIN = 3
  POINTS_PER_PAGE_RESULTS = 4

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


    @proposal = Proposal.find_by_long_id(params[:long_id])
    @user = current_user

    ApplicationController.reset_user_activities(session, @proposal) if !session.has_key?(@proposal.id)
    
    if !current_user.nil?
      @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
    end
    
    qry = @proposal.points.viewable
    pros_and_cons = false
    if ( params.key?(:cons_only) && params[:cons_only] == 'true'  )
      qry = qry.cons
    elsif ( params.key?(:pros_only) && params[:pros_only] == 'true' )
      qry = qry.pros
    else
      pros_and_cons = true
    end

    @bucket = params[:bucket]
    if !@bucket
      redirect_to root_path
      return
    end

    @filter = params.key?(:filter) ? params[:filter] : nil
    @positions = @proposal.positions.published
    if @bucket == 'all' || @bucket == ''
      @filter ||= 'popularity'
      group_name = 'all'
      case @filter
      when 'popularity'
        qry = qry.ranked_overall
      when 'unify'
        qry = qry.ranked_unify
      when 'divisive'
        qry = qry.ranked_divisive
      else
        raise 'Unrecognized sort filter'
      end

    elsif @bucket[0..3] == 'user'
      group_name = 'user'
      user_points_id = @bucket[5..@bucket.length].to_i
      @user_points = User.find(user_points_id)
      qry = qry.joins(:inclusions).where(:inclusions => { :user_id => user_points_id})    
    elsif @bucket == 'margin'
      group_name = 'margin'
      qry = qry.not_included_by(current_user, session[@proposal.id][:included_points].keys, session[@proposal.id][:deleted_points].keys).ranked_persuasiveness  
    else
      ## specific voter segment...
      @bucket = @bucket.to_i
      group_name = self.stance_name(@bucket)
      qry = qry.ranked_for_stance_segment(@bucket) #.where("importance_#{@bucket} > 0").order("importance_#{@bucket} DESC")
      @positions = @proposal.positions.published.where( :stance_bucket => @bucket )    
    end
    
    if params.key?(:page)
      @page = params[:page].to_i
    else
      @page = 1
    end

    if group_name == 'user'
      @con_points = qry.cons.page( @page ).per( 50 )
      @pro_points = qry.pros.page( @page ).per( 50 )
      points = @con_points + @pro_points
    elsif pros_and_cons
      @con_points = qry.cons.page( @page ).per( POINTS_PER_PAGE_RESULTS )
      @pro_points = qry.pros.page( @page ).per( POINTS_PER_PAGE_RESULTS )
      points = @con_points + @pro_points
    else 
      points = qry.page( @page ).per( @bucket == 'margin' ? POINTS_PER_PAGE_MARGIN : POINTS_PER_PAGE_RESULTS )
    
    end
    
    if group_name == 'user'
      context = 10 # looking through someone else's included points
    elsif pros_and_cons
      context = 5  # initial load of voter segment on proposals page
    elsif group_name == 'margin'
      context = 2 # pagination requested on position page
    else
      context = 6 # pagination requested on proposals page
    end
    
    # StudyData.create!({
    #   :category => 4,
    #   :user => current_user,
    #   :session_id => request.session_options[:id],
    #   :position => @position,
    #   :proposal => @proposal,
    #   :detail1 => @bucket,
    #   :ival => context
    # })

    ApplicationController.reset_user_activities(session, @proposal) if !session.has_key?(@proposal.id)
    if context
      points.each do |pnt|
        session[@proposal.id][:viewed_points].push([pnt.id, context])
      end          
    end
        
    #TODO: refactor to make the logic behind these calls easier to follow & explicit
    if pros_and_cons
      resp = { :points => render_to_string(:partial => "points/pro_con_list", :locals => { :bucket => @bucket, :dynamic => false, :points => {:pros => @pro_points, :cons => @con_points} })   }
    else
      origin = group_name == 'margin' ? 'margin' : 'board'
      resp = { :points => render_to_string(:partial => "points/column", :locals => { :points => points, :is_pro => params.key?(:pros_only), :origin => origin, :bucket => @bucket, :enable_pagination => false, :page => @page }) }
    end
    
    render :json => resp.to_json
  end
  
  def create
    @proposal = Proposal.find_by_long_id(params[:long_id])
    if current_user
      @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
    end

    @user = current_user

    params[:point][:proposal_id] = @proposal.id   
    # if @position
    #   params[:point][:position_id] = @position.id
    # end

    if params[:point][:nutshell].length > 140 
      params[:point][:text] << params[:point][:nutshell][139..-1]
      params[:point][:nutshell] = params[:point][:nutshell][0..139]
    end

    if params[:point][:nutshell].length == 0 && !params[:point][:text].nil? && params[:point][:text].length > 0
      params[:point][:text] =  params[:point][:text][139..params[:point][:text].length]
      params[:point][:nutshell] = params[:point][:text][0..139]
    end

    if current_user
      params[:point][:user_id] = current_user.id
    else
      params[:point][:published] = false
    end

    @point = Point.create!(params[:point])

    authorize! :create, @point

    ApplicationController.reset_user_activities(session, @proposal) if !session.has_key?(@proposal.id)

    session[@proposal.id][:written_points].push(@point.id)
    session[@proposal.id][:included_points][@point.id] = 1    
    session[@proposal.id][:viewed_points].push([@point.id, 7]) # own point has been seen

    #if @point.published
    #  @point.update_absolute_score
    #  @point.notify_parties(current_tenant, mail_options)
    #end
    
    new_point = render_to_string :partial => "points/show", :locals => { :origin => 'self', :point => @point, :static => false }
    response = {
      :new_point => new_point
    }
    render :json => response.to_json

  end

  def show
    @point = Point.find(params[:id])
    @proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :read, @point

    if request.xhr?
      origin = params[:origin]
      point_details = render_to_string :partial => "points/details", :locals => { :point => @point, :origin => origin}
      render :json => { :details => point_details }        
    else
      render
    end

  end

  def update
    @proposal = Proposal.find_by_long_id(params[:long_id])
    if current_user
      @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
    end
    @user = current_user
    @point = Point.find(params[:id])
    authorize! :update, @point

    @point.update_attributes!(params[:point])

    new_point = render_to_string :partial => "points/show", :locals => { :origin => 'self', :point => @point, :static => false }
    response = {
      :new_point => new_point
    }
    render :json => response.to_json

  end

  def destroy
    @point = Point.find(params[:id])
    
    authorize! :destroy, @point

    ApplicationController.reset_user_activities(session, @point.proposal) if !session.has_key?(@point.proposal.id)
    
    session[@point.proposal_id][:written_points].delete(@point.id)
    session[@point.proposal_id][:included_points].delete(@point.id)  

    @point.destroy

    response = {:result => 'successful'}
    render :json => response.to_json
  end
  
protected 

  def stance_name(d)
    case d
      when 0
        return "strong opposers"
      when 1
        return "moderate opposers"
      when 2
        return "light opposers"
      when 3
        return "undecideds"
      when 4
        return "light supporters"
      when 5
        return "moderate supporters"
      when 6
        return "strong supporters"
    end   
  end  
  
  
end
