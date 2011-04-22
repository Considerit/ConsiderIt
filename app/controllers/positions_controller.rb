class PositionsController < ApplicationController
  respond_to :html
  
  def new 
    @option = Option.find(params[:option_id])
    
    @position = Position.new( :stance => 0.0)

    @pro_points = @option.points.pros.not_included_by(current_user).paginate(:page => 1, :per_page => 4)
    @con_points = @option.points.cons.not_included_by(current_user).paginate(:page => 1, :per_page => 4)
    
    @included_pros = @option.points.pros.included_by(current_user)
    @included_cons = @option.points.cons.included_by(current_user)
    
    @page = 1

    @user = current_user
  end

  def edit
    @option = Option.find(params[:option_id])
    
    @position = Position.find( params[:id] )

    @pro_points = @option.points.pros.not_included_by(current_user).paginate(:page => 1, :per_page => 4)
    @con_points = @option.points.cons.not_included_by(current_user).paginate(:page => 1, :per_page => 4)

    @included_pros = @option.points.pros.included_by(current_user)
    @included_cons = @option.points.cons.included_by(current_user)

    @page = 1
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
    #TODO: actually update the position...
    @option = Option.find(params[:option_id])
    redirect_to(@option)
  end
  
  def show
    
  end
end
