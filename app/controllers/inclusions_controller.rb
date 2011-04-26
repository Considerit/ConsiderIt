class InclusionsController < ApplicationController
  respond_to :json
  
  def create
    @option = Option.find(params[:option_id])
    @point = Point.find(params[:point_id])
    @user = current_user 
    
    current_page = params[:page]
    
    @inclusion = current_user.inclusions.where( :point_id => @point.id ).first
    if !@inclusion
      @position = Position.unscoped.where(:option_id => @option.id, :user_id => current_user.id).first
      #TODO: deal with session id
      params[:inclusion].update({ 
        :user_id => @user.id,
        :position_id => @position.id
      })

      @inclusion = Inclusion.create!( params[:inclusion] )
      
      new_point = @option.points        
      if @point.is_pro
        new_point = new_point.pros
      else
        new_point = new_point.cons
      end
      
      next_point = new_point.not_included_by(current_user).ranked_persuasiveness.paginate( :page => current_page, :per_page => 4 ).last
      
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
    
    render :json => { 
       :deleted_point => render_to_string(:partial => "points/show_in_margin", :locals => { :static => false, :point => @point, :user => @user })   
    }.to_json
  end
end
