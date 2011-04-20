class PointsController < ApplicationController
  respond_to :json
  
  def index
    
  end
  
  def show
    
  end
  
  def new
    
  end
  
  def create
    
    #TODO: handle point scores
    #params[:point][:listings] = 1
    #params[:point][:inclusions] = 1
    @point = Point.create!(params[:point])
    
    @user = current_user
    @option = Option.find(params[:option_id])
    
    #TODO: save session ids properly
    inclusion = Inclusion.create!(
      :option_id => @option.id,
      :user_id => @user.id,
      :point_id => @point.id,
      :included_as_pro => @point.is_pro #TODO: update to allow user to switch polarity
      #:session_id => ...
      #:position_id => params[:point][:position_id], #TODO: deal with positions not being saved at this time
    )

    #TODO: handle point listings
    #point_listing = PointListing.create!(
    #  :initiative_id => params[:point][:initiative_id],
    #  :user_id => current_user.id,
    #  :point_id => @point.id,
    #  :judgement_id => judgement.id
    #)


    #@point.update_score
    
    respond_with(@option, @point) do |format|
      format.js {render :partial => "options/points/show_on_board_self", :locals => { :point => @point, :static => false }}
    end
  end
  
  def update
    
  end
  
  def destroy
    
  end
  
end
