class PointsController < ApplicationController
  respond_to :json
  
  
  ########
  ##
  # handles calls from:
  #     paginate OTHER's pros OR cons; 
  #     initial load of voter segment's pros AND cons; 
  #     paginate voter segment's pros OR cons;   
  #     initial load of self's pros AND cons
  #     paginate self's pros OR cons
  #     
  #########
  def index
    @option = Option.find(params[:option_id])
    @user = current_user
    
    #TODO: use scopes on Point; http://edgerails.info/articles/what-s-new-in-edge-rails/2010/02/23/the-skinny-on-scopes-formerly-named-scope/index.html
    
    qry = @option.points
    pros_and_cons = false
    if ( params.key?(:cons_only) )
      qry = qry.cons
    elsif ( params.key?(:pros_only) )
      qry = qry.pros
    else
      pros_and_cons = true
    end
    
    @bucket = params[:bucket]
    if @bucket == 'all' || @bucket == ''
      group_name = 'all'
      qry = qry#.order('score DESC')
    elsif @bucket == 'self' && @user
      group_name = 'self'
      qry = qry.joins(:inclusions).where(:inclusions => { :user_id => @user.id})      
    else
      ## specific voter segment...
      group_name = stance_name(@bucket)
      @bucket = @bucket.to_i
      qry = qry#.where("importance_#{@bucket} > 0").order("importance_#{@bucket} DESC")
    end
    
    if params.key?(:page)
      @page = params[:page].to_i
    else
      @page = 1
    end

    if ( pros_and_cons )
      @con_points = qry.cons.paginate( :page => @page, :per_page => 4 )
      @pro_points = qry.pros.paginate( :page => @page, :per_page => 4 )
    else
      points = qry.paginate( :page => @page, :per_page => 4 )
    end
        
    respond_to do |format|
      format.js  {
        if pros_and_cons
          render :partial => "options/pro_con_board", :locals => { :group_id => @bucket, :group_name => group_name}    
        else
          if (params[:mode] == 'other')
            render :partial => "points/column/margin", :locals => {:points => points, :is_pro => params.key?(:pros_only)}   
          else
            render :partial => "points/column/all", :locals => {:points => points, :is_pro => params.key?(:pros_only)}          
          end
        end
      }
    end    
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
      format.js {render :partial => "points/show_on_board_self", :locals => { :point => @point, :static => false }}
    end
  end
  
  def update
    
  end
  
  def destroy
    
  end
  
end
