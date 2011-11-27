class OptionsController < ApplicationController
  protect_from_forgery

  POINTS_PER_PAGE = 4
  
  def show
    @user = current_user
    @option = Option.find(params[:id])
    
    @title = "#{@option.category} #{@option.designator} #{@option.short_name}"
    @keywords = "#{@option.domain} #{@option.category} #{@option.designator} #{@option.name} Washington 2011"

    @position = current_user ? current_user.positions.where(:option_id => @option.id).first : nil
    
    if !@position && (!params.has_key? :redirect || params[:redirect] == 'true' )
      redirect_to(new_option_position_path(@option))
      return
    end

    @pro_points = @option.points.pros.ranked_overall.paginate(:page => 1, :per_page => POINTS_PER_PAGE)
    @con_points = @option.points.cons.ranked_overall.paginate(:page => 1, :per_page => POINTS_PER_PAGE)

    PointListing.transaction do
      (@pro_points + @con_points).each do |pnt|
        PointListing.create!(
          :option => @option,
          :position => @position,
          :point => pnt,
          :user => @user,
          :context => 4
        )
      end
    end

    @page = 1
    @bucket = 'all'
    
    @protovis = true
    
    #Point.update_relative_scores

    #@comments = @option.root_comments
    #@comment = Comment.new      
    #@reflectable = true    
    
  end

  def index
    headers['Content-Type'] = 'application/xml'

    @options = Option.all
    respond_to do |format|
      format.xml {  } # sitemap is a named scope
      format.html {  }
    end

  end

end
