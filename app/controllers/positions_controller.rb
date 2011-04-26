class PositionsController < ApplicationController
  respond_to :html
  
  def new     
    @option = Option.find(params[:option_id])
    @user = current_user
    @position = current_user ? Position.unscoped.where(:option_id => @option.id, :user_id => current_user.id).first : nil

    if @position.nil?
      @position = Position.unscoped.create!( 
        :stance => 0.0, 
        :option_id => @option.id, 
        :user_id => @user ? @user.id : nil
      )
    end
    
    @pro_points = @option.points.pros.not_included_by(current_user).ranked_persuasiveness.paginate(:page => 1, :per_page => 4)
    @con_points = @option.points.cons.not_included_by(current_user).ranked_persuasiveness.paginate(:page => 1, :per_page => 4)

    PointListing.transaction do

      (@pro_points + @con_points).each do |pnt|
        PointListing.create!(
          :option => @option,
          :position => @position,
          :point => pnt,
          :user => @user,
          :context => 1
        )
      end
    end
    
    @included_pros = @option.points.pros.included_by(current_user)
    @included_cons = @option.points.cons.included_by(current_user)
    
    @page = 1

  end

  def edit
    @option = Option.find(params[:option_id])
    @user = current_user
    @position = Position.find( params[:id] )

    @pro_points = @option.points.pros.not_included_by(current_user).ranked_persuasiveness.paginate(:page => 1, :per_page => 4)
    @con_points = @option.points.cons.not_included_by(current_user).ranked_persuasiveness.paginate(:page => 1, :per_page => 4)

    PointListing.transaction do

      (@pro_points + @con_points).each do |pnt|
        PointListing.create!(
          :option => @option,
          :position => @position,
          :point => pnt,
          :user => @user,
          :context => 1
        )
      end
    end
        
    @included_pros = @option.points.pros.included_by(current_user)
    @included_cons = @option.points.cons.included_by(current_user)

    @page = 1
  end
  
  def create
    @option = Option.find(params[:option_id])

    (stance, bucket) = get_stance_val_from_params(params)
        
    params[:position].update({
      :user_id => current_user.id,
      :stance => stance,
      :stance_bucket => bucket,
      :published => true
    })
    
    @position = Position.unscoped.find(params[:position][:position_id])
    params[:position].delete(:position_id)
    @position.update_attributes(params[:position])
    @position.save
        
    respond_with(@option, @position) do |format|
      format.html { redirect_to(@option) }
    end   
  end
  
  def update
    @option = Option.find(params[:option_id])
    @position = current_user.positions.find(params[:id])
    
    (stance, bucket) = get_stance_val_from_params(params)
    
    @position.stance = stance
    @position.stance_bucket = bucket
    @position.save
    
    respond_with(@option, @position) do |format|
      format.html { redirect_to(@option) }
    end   
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
      
      
  def get_bucket(value)
    if value == -1
      return 0
    elsif value == 1
      return 6
    elsif value <= 0.05 && value >= -0.05
      return 3
    elsif value >= 0.5
      return 5
    elsif value <= -0.5
      return 1
    elsif value >= 0.05
      return 4
    elsif value <= -0.05
      return 2
    end   
  end        
end
