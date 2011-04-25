class OptionsController < ApplicationController
  def show
    @user = current_user
    @option = Option.find(params[:id])
    
    @position = current_user ? current_user.positions.where(:option_id => @option.id).first : nil
    
    @pro_points = @option.points.pros.paginate(:page => 1, :per_page => 4)#.order "score DESC" \
    @con_points = @option.points.cons.paginate(:page => 1, :per_page => 4)#.order "score DESC" \
    
    (@pro_points + @con_points).each do |pnt|
      PointListing.create!(
        :option => @option,
        :position => @position,
        :point => pnt,
        :user => @user,
        :context => 4
      )
    end
    
    @page = 1
    @bucket = 'all'
    
    @protovis = true
    
    #TODO: replace this with chron job
    @option.points.each do |pnt|
      pnt.update_absolute_score
      pnt.save
    end
    
  end

end
