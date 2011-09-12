class InclusionsController < ApplicationController
  protect_from_forgery

  respond_to :json
  
  def create
    
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])

    if (current_user && current_user.inclusions.where( :point_id => @point.id ).first) || session[@option.id][:included_points].has_key?(params[:point_id])
      render :json => { :success => false }.to_json
      return
    end

    current_page = params[:page].to_i
    candidate_next_points = @point.is_pro ? @option.points.pros : @option.points.cons

    session[@option.id][:included_points][params[:point_id]] = 1

    candidate_next_points = candidate_next_points.not_included_by(current_user, session[@option.id][:included_points].keys)
    points = candidate_next_points.ranked_persuasiveness.paginate( :page => current_page, :per_page => 4 )
    next_point = points.last
    
    if next_point
      PointListing.create!(
        :option => @option,
        :position => @position,
        :point => next_point,
        :user => current_user,
        :context => 3 #replaced included point
      )
    end

    rendered_next_point = next_point ? render_to_string( :partial => "points/show_in_margin", :locals => { :point => next_point }) : nil
    
    pagination = render_to_string :partial => "points/column/pagination/block", :locals => { 
      :points => points,
      :column_selector => "#points_other_" + {true => "pro", false => "con"}[@point.is_pro], 
      :is_pro => @point.is_pro, 
      :page => current_page, 
      :bucket => 'other', 
      :mode => 'other'}
    
    approved_point = render_to_string :partial => "points/show_on_board_self", :locals => { :static => false, :point => @point }    
    response = { :new_point => rendered_next_point, :pagination => pagination, :approved_point => approved_point } 
    
    render :json => response.to_json
  end
  
  def destroy
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])

    session [@option.id][:included_points].delete(params[:point_id])    
    if current_user
      @inc = current_user.inclusions.where(:point_id => @point.id).first
      if @inc
        session[@option.id][:deleted_points][@point.id] = 1
      end
    end
    
    render :json => { 
       :deleted_point => render_to_string(:partial => "points/show_in_margin", :locals => { :static => false, :point => @point })   
    }.to_json
  end
end
