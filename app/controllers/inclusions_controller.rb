class InclusionsController < ApplicationController
  protect_from_forgery

  respond_to :json

  POINTS_PER_PAGE = 4
  
  def create
    
    if params.has_key?(:delete) && params[:delete]
      destroy(params)
      return
    end

    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])

    if (current_user && current_user.inclusions.where( :point_id => @point.id ).first) || session[@option.id][:included_points].has_key?(params[:point_id])
      render :json => { :success => false }.to_json
      return
    end

    @page = params[:page].to_i
    candidate_next_points = @point.is_pro ? @option.points.pros : @option.points.cons

    session[@option.id][:included_points][params[:point_id]] = 1

    candidate_next_points = candidate_next_points.not_included_by(current_user, session[@option.id][:included_points].keys)
    points = candidate_next_points.ranked_persuasiveness.paginate( :page => @page, :per_page => POINTS_PER_PAGE )
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

    rendered_next_point = next_point ? render_to_string( :partial => "points/show", :locals => { :context => 'margin', :point => next_point }) : nil
        
    response = { :new_point => rendered_next_point, :total_remaining => points.total_entries } 
    
    render :json => response.to_json
  end
  
  protected

  #cannot just route here in normal REST fashion because for unregistered users, 
  # we do not save the inclusion and hence do not have an ID for the inclusion
  def destroy(params)
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])

    session[@option.id][:included_points].delete(params[:point_id])    
    if current_user
      @inc = current_user.inclusions.where(:point_id => @point.id).first
      if @inc
        session[@option.id][:deleted_points][@point.id] = 1
      end
    end

    @page = params[:page].to_i
    candidate_next_points = @point.is_pro ? @option.points.pros : @option.points.cons
    points = candidate_next_points.not_included_by(current_user, session[@option.id][:included_points].keys).ranked_persuasiveness.paginate( :page => @page, :per_page => POINTS_PER_PAGE )

    render :json => { 
      :total_remaining => points.total_entries 
    }.to_json
  end
end
