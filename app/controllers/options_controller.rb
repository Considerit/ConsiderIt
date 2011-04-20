class OptionsController < ApplicationController
  def show
    @user = current_user
    @option = Option.find(params[:id])
    
    if ( current_user )
      @position = Position.where(:user_id => current_user.id, :option_id => @option.id).first
    end
    
    @pro_points = Point.where(:option_id => @option.id, :is_pro => true).paginate(:page => 1, :per_page => 4)#.order "score DESC" \
    @con_points = Point.where(:option_id => @option.id, :is_pro => false).paginate(:page => 1, :per_page => 4)#.order "score DESC" \
    
    @page = 1
    @bucket = 'all'
    
    @protovis = true
    
  end

end
