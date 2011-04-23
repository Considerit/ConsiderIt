class InclusionsController < ApplicationController
  respond_to :json
  
  def create
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])
    @user = current_user 

    #TODO: deal with session id, position id    
    params[:inclusion].update({ 
      :user_id => @user.id
    })
    
    @inclusion = Inclusion.create!( params[:inclusion] )
    #@point.inclusions -= 1
    
    new_point = @option.points        
    if ( @point.is_pro )
      new_point = new_point.pros
    else
      new_point = new_point.cons
    end
    
    new_point = render_to_string :partial => "points/show_in_margin", :locals => { :point => new_point.not_included_by(current_user).first, :user => @user }
    #TODO: also filter by LEAST LISTED point

    #TODO: return pagination    
    pagination = nil
    
    approved_point = render_to_string :partial => "points/show_on_board_self", :locals => { :static => false, :point => @point, :user => @user }    
    response = { :new_point => new_point, :pagination => pagination, :approved_point => approved_point }        
        
    respond_with(@option, @point, @inclusion) do |format|
      format.js { render :json => response.to_json }
    end    
  end
end
