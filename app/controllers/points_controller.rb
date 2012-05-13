class PointsController < ApplicationController
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

    if current_user
      @position = Position.unscoped.where(:proposal_id => @proposal.id, :user_id => current_user.id).first 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.unscoped.find(session["position-#{@proposal.id}"]) : nil
    end
    
    qry = @proposal.points
    pros_and_cons = false
    if ( params.key?(:cons_only) && params[:cons_only] == 'true'  )
      qry = qry.cons
    elsif ( params.key?(:pros_only) && params[:pros_only] == 'true' )
      qry = qry.pros
    else
      pros_and_cons = true
    end

    @bucket = params[:bucket]
    @positions = @proposal.positions.published
    if @bucket == 'all' || @bucket == ''
      group_name = 'all'
      qry = qry.ranked_overall
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
    
    StudyData.create!({
      :category => 4,
      :user => current_user,
      :session_id => request.session_options[:id],
      :position => @position,
      :proposal => @proposal,
      :detail1 => @bucket,
      :ival => context
    })

    if context
      PointListing.transaction do
        points.each do |pnt|
          PointListing.create!(
            :proposal => @proposal,
            :position => @position,
            :point => pnt,
            :user => @user,
            :context => context
          )
        end          
      end
    end
        
    #TODO: refactor to make the logic behind these calls easier to follow & explicit
    if pros_and_cons
      resp = { :points => render_to_string(:partial => "points/pro_con_list", :locals => { :bucket => @bucket, :dynamic => false, :pro_points => @pro_points, :con_points => @con_points}),
               :participants => render_to_string(:partial => "proposals/participants")   }
    
    else
      origin = group_name == 'margin' ? 'margin' : 'board'
      resp = { :points => render_to_string(:partial => "points/column", :locals => { :points => points, :is_pro => params.key?(:pros_only), :origin => origin, :bucket => @bucket, :enable_pagination => false, :page => @page }) }
    end
    
    render :json => resp.to_json
  end
  
  def create
    @proposal = Proposal.find_by_long_id(params[:long_id])
    if current_user
      @position = Position.unscoped.where(:proposal_id => @proposal.id, :user_id => current_user.id).first 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.unscoped.find(session["position-#{@proposal.id}"]) : nil
    end

    @user = current_user

    params[:point][:proposal_id] = @proposal.id   

    if params[:point][:nutshell].length > 140
      params[:point][:text] << params[:point][:nutshell][140..-1]
      params[:point][:nutshell] = params[:point][:nutshell][0..140]
    end

    if current_user
      params[:point][:user_id] = current_user.id
    else
      params[:point][:published] = false
    end

    @point = Point.create!(params[:point])

    session[@proposal.id][:written_points].push(@point.id)
    session[@proposal.id][:included_points][@point.id] = 1    

    PointListing.create!(
      :proposal => @proposal,
      :position => @position,
      :point => @point,
      :user => @user,
      :context => 7 # own point has been seen
    )

    if @point.published
      @point.update_absolute_score
      @point.notify_parties(current_tenant, default_url_options)
    end
    
    new_point = render_to_string :partial => "points/show", :locals => { :origin => 'self', :point => @point, :static => false }
    response = {
      :new_point => new_point
    }
    render :json => response.to_json

  end

  # TODO: server-side permissions check for this operation
  def update
    @proposal = Proposal.find_by_long_id(params[:long_id])
    if current_user
      @position = Position.unscoped.where(:proposal_id => @proposal.id, :user_id => current_user.id).first 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.unscoped.find(session["position-#{@proposal.id}"]) : nil
    end
    @user = current_user
    @point = Point.unscoped.find(params[:id])

    @point.update_attributes!(params[:point])
    @point.save

    new_point = render_to_string :partial => "points/show", :locals => { :origin => 'self', :point => @point, :static => false }
    response = {
      :new_point => new_point
    }
    render :json => response.to_json

  end

  def show
    @point = Point.find(params[:id])
    @proposal = Proposal.find_by_long_id(params[:long_id])

    if request.xhr?
      origin = params[:origin]
      point_details = render_to_string :partial => "points/details", :locals => { :point => @point, :light_background => origin == 'margin' }
      render :json => { :details => point_details }        
    else
      render
    end

  end

  def destroy
    # TODO: server-side permissions check for this operation
    @point = Point.unscoped.find(params[:id])
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
