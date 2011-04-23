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

    (stance, bucket) = get_stance_val_from_params(params)
        
    params[:position].update({
      :user_id => current_user.id,
      :stance => stance,
      :stance_bucket => bucket
    })
    
    @position = Position.create!(params[:position])
    
    redirect_to(@option)       
  end
  
  def update
    @option = Option.find(params[:option_id])
    @position = current_user.positions.find(params[:id])
    
    (stance, bucket) = get_stance_val_from_params(params)
    
    @position.stance = stance
    @position.stance_bucket = bucket
    @position.save
    
    redirect_to(@option)
  end
  
  def show
    
  end
  
protected
  
  def get_stance_val_from_params( params )
    stance = -1 * Float(params[:position][:stance])
    if stance > 1
      stance = 1
    elsif stance < -1
      stance = -1
    end
    bucket = get_bucket(stance)
    
    return stance, bucket
  end
      
end
