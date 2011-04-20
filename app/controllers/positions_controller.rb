class PositionsController < ApplicationController
  def new 
    @option = Option.find(params[:option_id])
    @position = Position.new( :stance => 0.0)
    
    # TODO: clean this out on log in
    #key = "init-#{@initiative.id}".intern
    #unless session.has_key?( key )
    #  session[key] = {}
    #  PointList.new( :initiative => @initiative, :user => current_user, :position => 1, :new => true, :session => session )
    #  PointList.new( :initiative => @initiative, :user => current_user, :position => 0, :new => true, :session => session )                
    #end
    #@pro_points = PointList.new(session[key][:pro_list]).next_page!( POINT_LIST_SIZE, session )
    #@con_points = PointList.new(session[key][:con_list]).next_page!( POINT_LIST_SIZE, session )    
    @pro_points = Point.where(:is_pro => true, :option_id => @option.id)
    @con_points = Point.where(:is_pro => false, :option_id => @option.id)

    @user = current_user
  end
  
  def create
    
  end
  
  def update
    
  end
  
  def show
    
  end
end
