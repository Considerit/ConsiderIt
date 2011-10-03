class PointsController < ApplicationController
  protect_from_forgery

  respond_to :json
  
  POINTS_PER_PAGE = 4
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
    @option = Option.find(params[:option_id])
    @user = current_user
    @position = current_user ? current_user.positions.where(:option_id => @option.id).first : nil
    mode = params[:mode]
    
    qry = @option.points
    pros_and_cons = false
    if ( params.key?(:cons_only) )
      qry = qry.cons
    elsif ( params.key?(:pros_only) )
      qry = qry.pros
    else
      pros_and_cons = true
    end
    
    @bucket = params[:bucket]
    if @bucket == 'all' || @bucket == ''
      group_name = 'all'
      qry = qry.ranked_overall
    elsif @bucket == 'self' && @user
      group_name = 'self'
      qry = qry.joins(:inclusions).where(:inclusions => { :user_id => @user.id})    
    elsif @bucket == 'other'
      group_name = 'other'
      qry = qry.not_included_by(current_user, session[@option.id][:included_points].keys).ranked_persuasiveness  
    else
      ## specific voter segment...
      @bucket = @bucket.to_i
      group_name = self.stance_name(@bucket)
      qry = qry.ranked_for_stance_segment(@bucket) #.where("importance_#{@bucket} > 0").order("importance_#{@bucket} DESC")
    end
    
    if params.key?(:page)
      @page = params[:page].to_i
    else
      @page = 1
    end

    if pros_and_cons
      @con_points = qry.cons.paginate( :page => @page, :per_page => POINTS_PER_PAGE )
      @pro_points = qry.pros.paginate( :page => @page, :per_page => POINTS_PER_PAGE )
      points = @con_points + @pro_points
    else
      points = qry.paginate( :page => @page, :per_page => POINTS_PER_PAGE )
    end
    
    if group_name == 'self'
      context = nil # looking through their own included points
    elsif pros_and_cons
      context = 5  # initial load of voter segment on options page
    elsif mode == 'other'
      context = 2 # pagination requested on position page
    else
      context = 6 # pagination requested on options page
    end
        
    if context
      PointListing.transaction do
        points.each do |pnt|
          PointListing.create!(
            :option => @option,
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
      resp = render_to_string :partial => "options/pro_con_board", :locals => { :group_id => @bucket, :group_name => group_name}    
    else
      if mode == 'other'
        resp = render_to_string :partial => "points/column", :locals => {:points => points, :is_pro => params.key?(:pros_only), :context => 'margin'}   
      else
        resp = render_to_string :partial => "points/column", :locals => {:points => points, :is_pro => params.key?(:pros_only), :context => 'board'}          
      end
    end
    
    render :json => { :points => resp }.to_json
  end
  
  def create
    @option = Option.find(params[:option_id])
    @position = current_user ? Position.unscoped.where(:option_id => @option.id, :user_id => current_user.id).first : nil
    @user = current_user

    params[:point][:option_id] = params[:option_id]   
    if current_user
      params[:point][:user_id] = current_user.id
    else
      params[:point][:published] = false
    end

    @point = Point.create!(params[:point])

    if current_user.nil?
      session[@option.id][:written_points].push(@point.id)
    end
    session[@option.id][:included_points][@point.id] = 1    

    PointListing.create!(
      :option => @option,
      :position => @position,
      :point => @point,
      :user => @user,
      :context => 7 # own point has been seen
    )

    if @point.published
      @point.update_absolute_score
      @point.save
    end
    
    new_point = render_to_string :partial => "points/show", :locals => { :context => 'self', :point => @point, :static => false }
    response = {
      :new_point => new_point
    }
    render :json => response.to_json

  end

  # TODO: server-side permissions check for this operation
  def update
    @option = Option.find(params[:option_id])
    @position = current_user ? Position.unscoped.where(:option_id => @option.id, :user_id => current_user.id).first : nil
    @user = current_user
    @point = Point.unscoped.find(params[:id])

    @point.update_attributes!(params[:point])
    @point.save

    new_point = render_to_string :partial => "points/show", :locals => { :context => 'self', :point => @point, :static => false }
    response = {
      :new_point => new_point
    }
    render :json => response.to_json

  end

  def destroy
    # TODO: server-side permissions check for this operation
    @point = Point.unscoped.find(params[:id])
    if current_user.nil?
      session[@point.option_id][:written_points].delete(@point.id)
    end
    session[@point.option_id][:included_points].delete(@point.id)  

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
