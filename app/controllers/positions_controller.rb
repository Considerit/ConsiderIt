class PositionsController < ApplicationController
  respond_to :html
  
  def new 
    @option = Option.find(params[:option_id])
    
    #TODO: store @position in cache, and also check if it exists b/f creating new
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
    @option = Option.find(params[:option_id])

    stance = -1 * Float(params[:position][:stance])
    if stance > 1
      stance = 1
    elsif stance < -1
      stance = -1
    end
        
    params[:position].update({
      :user_id => current_user.id,
      :stance => stance,
      :stance_bucket => get_bucket(stance)
    })
    
    @position = Position.create!(params[:position])
    
    respond_with(@option, @position) do |format|
      format.html { redirect_to(@option) }
    end   
    
  end
  
  def update
    
  end
  
  def show
    
  end
end
