class InclusionsController < ApplicationController
  respond_to :json
  
  def create
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])
    @user = current_user 
    
    @inclusion = current_user.inclusions.where( :point_id => @point.id ).first
    if !@inclusion
      @position = current_user ? current_user.positions.unscoped.where(:option_id => @option.id).first : nil      
      #TODO: deal with session id, position id    
      params[:inclusion].update({ 
        :user_id => @user.id,
        :position_id => @position.id
      })

      @inclusion = Inclusion.create!( params[:inclusion] )
      #@point.inclusions -= 1
      
      new_point = @option.points        
      if @point.is_pro
        new_point = new_point.pros
      else
        new_point = new_point.cons
      end
      
      next_point = new_point.not_included_by(current_user).first
      
      if next_point
        PointListing.create!(
          :option => @option,
          :position => @position,
          :point => next_point,
          :user => @user,
          :context => 3 #replaced included point
        )
      end
            
      new_point = next_point ? render_to_string( :partial => "points/show_in_margin", :locals => { :point => next_point, :user => @user }) : nil
            
      #TODO: also filter by LEAST LISTED point
  
      #TODO: return pagination    
      pagination = nil
      
      approved_point = render_to_string :partial => "points/show_on_board_self", :locals => { :static => false, :point => @point, :user => @user }    
      response = { :new_point => new_point, :pagination => pagination, :approved_point => approved_point } 
    else
      response = { :success => false }       
    end
    
    render :json => response.to_json
  end
  
  def destroy
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])
    @user = current_user
    
    @inc = current_user.inclusions.where(:point_id => @point.id).first
    @inc.destroy
    
    render :partial => "points/show_in_margin", :locals => { :static => false, :point => @point, :user => @user }    
  end
end
