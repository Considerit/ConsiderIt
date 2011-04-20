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
    
    #TODO: fetch next point & return it!        
    #new_point, pagination = fetch_next_point_in_list( @judgement )
    new_point = nil
    pagination = nil
    
    approved_point = render_to_string :partial => "options/points/show_on_board_self", :locals => { :static => false, :point => @point, :user => @user }    
    response = { :new_point => new_point, :pagination => pagination, :approved_point => approved_point }        
        
    respond_with(@option, @point, @inclusion) do |format|
      format.js { render :json => response.to_json }
    end    
  end
end
