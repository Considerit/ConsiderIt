class OptionsController < ApplicationController
  def show
    @user = current_user
    @option = Option.find(params[:id])
    
    if ( current_user )
      @position = current_user.positions.where(:option_id => @option.id).first
    end
    
    @pro_points = @option.points.pros.paginate(:page => 1, :per_page => 4)#.order "score DESC" \
    @con_points = @option.points.cons.paginate(:page => 1, :per_page => 4)#.order "score DESC" \
    
    @page = 1
    @bucket = 'all'
    
    @protovis = true
    
  end

end
