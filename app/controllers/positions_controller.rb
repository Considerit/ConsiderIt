class PositionsController < ApplicationController
  respond_to :html
  
  def new 
    @option = Option.find(params[:option_id])
    
    @position = Position.new( :stance => 0.0)

    #TODO: exclude points already included by users...    
    @pro_points = Point.where(:is_pro => true, :option_id => @option.id).paginate(:page => 1, :per_page => 4)
    @con_points = Point.where(:is_pro => false, :option_id => @option.id).paginate(:page => 1, :per_page => 4)

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
  
  def edit
    @option = Option.find(params[:option_id])
    
    @position = Position.find( params[:id] )

    #TODO: exclude points already included by users...    
    @pro_points = Point.where(:is_pro => true, :option_id => @option.id).paginate(:page => 1, :per_page => 4)
    @con_points = Point.where(:is_pro => false, :option_id => @option.id).paginate(:page => 1, :per_page => 4)

    @user = current_user    
  end
  
  def update
    #TODO: actually update the position...
    @option = Option.find(params[:option_id])
    redirect_to(@option)
  end
  
  def show
    
  end
end
