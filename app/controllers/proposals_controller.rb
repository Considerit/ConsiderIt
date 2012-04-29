class ProposalsController < ApplicationController
  protect_from_forgery

  POINTS_PER_PAGE = 4
  
  def show
    @user = current_user

    if params.has_key?(:id)
      @proposal = Proposal.find(params[:id])
    elsif params.has_key?(:long_id)
      @proposal = Proposal.find_by_long_id(params[:long_id])
    elsif params.has_key?(:admin_id)
      @proposal = Proposal.find_by_admin_id(params[:admin_id])
    else
      raise 'Error'
      redirect_to root_path
      return
    end

    if !@proposal
      redirect_to root_path
    end

    # TODO: this is replicated in positions_controller...DRY it up...
    @is_admin = request.session_options[:id] == @proposal.session_id || current_user && (current_user.id == @proposal.user_id || current_user.is_admin?) || params.has_key?(:admin_id)
      
    #@title = "#{@proposal.category} #{@proposal.designator} #{@proposal.short_name}"
    @title = "#{@proposal.short_name}"
    @keywords = "#{@proposal.domain} #{@proposal.category} #{@proposal.designator} #{@proposal.name}"

    @position = current_user ? current_user.positions.where(:proposal_id => @proposal.id).first : nil
    @positions = @proposal.positions.includes(:user).published

    # if !@position && (!params.has_key? :redirect || params[:redirect] == 'true' )
    #   redirect_to(new_proposal_position_path(@proposal.long_id))
    #   return
    # end

    @pro_points = @proposal.points.includes(:point_links, :user).pros.ranked_overall.page( 1 ).per( POINTS_PER_PAGE )
    @con_points = @proposal.points.includes(:point_links, :user).cons.ranked_overall.page( 1 ).per( POINTS_PER_PAGE )

    @segments = Array.new(7)
    (0..6).each do |bucket|
      qry = @proposal.points.includes(:point_links, :user).ranked_for_stance_segment(bucket)
      @segments[bucket] = [qry.pros.page( 1 ).per( POINTS_PER_PAGE ),
        qry.cons.page( 1 ).per( POINTS_PER_PAGE )]
    end


    #PointListing.transaction do
    #  (@pro_points + @con_points).each do |pnt|
    #    PointListing.create!(
    #      :proposal => @proposal,
    #      :position => @position,
    #      :point => pnt,
    #      :user => @user,
    #      :context => 4
    #    )
    #  end
    #end

    @page = 1
        
    #Point.update_relative_scores

    #@comments = @proposal.root_comments
    #@comment = Comment.new      
    #@reflectable = true    
    
  end

  # def index
  #   headers['Content-Type'] = 'application/xml'

  #   @proposals = Proposal.all
  #   respond_to do |format|
  #     format.xml {  } # sitemap is a named scope
  #     format.html {  }
  #   end

  # end

  def create

    # TODO: handle possibility of name collisions
    params[:proposal][:long_id] = SecureRandom.hex(5)
    params[:proposal][:admin_id] = SecureRandom.hex(6)

    if current_user
      params[:proposal][:user_id] = current_user.id
    end

    @proposal = Proposal.create!(params[:proposal])
    redirect_to proposal_path(@proposal.long_id)
  end

  def edit

  end

  def update

  end

end
