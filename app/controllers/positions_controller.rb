class PositionsController < ApplicationController
  protect_from_forgery

  respond_to :html

  POINTS_PER_PAGE = 3
  
  def new
    handle_new_edit(true)
  end

  def edit
    handle_new_edit(false)
  end

  def create
    @proposal = Proposal.find_by_long_id(params[:long_id])

    (stance, bucket) = get_stance_val_from_params(params)

    params[:position].update({
      :user_id => !current_user.nil? ? current_user.id : nil,
      :stance => stance,
      :stance_bucket => bucket,
      :published => !current_user.nil? 
    })

    @position = Position.unscoped.find(params[:position][:position_id])
    params[:position].delete(:position_id)
    @position.update_attributes(params[:position])
    @position.save

    if !current_user.nil?
      save_actions(@position)
    else
      # stash until after user registration
      session['position_to_be_published'] = @position.id
    end

    
    respond_with(@proposal, @position) do |format|
      format.html { redirect_to(  proposal_path(@proposal.long_id)  ) }
      format.js { render :json => { :result => 'successful' }.to_json }
    end
  end
  
  def update
    @proposal = Proposal.find_by_long_id(params[:long_id])
    @position = current_user.positions.unscoped.find(params[:id])
    
    (stance, bucket) = get_stance_val_from_params(params)

    params[:position].delete(:position_id)
    @position.update_attributes(params[:position])
    @position.stance = stance
    @position.stance_bucket = bucket
    @position.published = 1
    @position.save

    save_actions(@position)
    
    respond_with(@proposal, @position) do |format|
      format.html { redirect_to(  proposal_path(@proposal.long_id) ) }
    end
  end

  def destroy
    @proposal = Proposal.find_by_long_id(params[:long_id])
    if current_user
      @position = Position.unscoped.where(:proposal_id => @proposal.id, :user_id => current_user.id).first 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.unscoped.find(session["position-#{@proposal.id}"]) : nil
    end
    
    redirect_to(proposal_path(@position.proposal.long_id))
    session.delete('reify_activities')
    session.delete('position_to_be_published')
    session[@proposal.id] = {
        :included_points => {},
        :deleted_points => {},
        :written_points => []
      }
  end
  
protected
  def handle_new_edit(is_new)
    if params.has_key? :proposal_id
      @proposal = Proposal.find(params[:proposal_id])
    elsif params.has_key? :long_id
      @proposal = Proposal.find_by_long_id(params[:long_id])
    elsif 
      raise 'Error'
      redirect_to root_path
      return
    end

    if @proposal.session_id.nil?
      @proposal.session_id = request.session_options[:id]
      @proposal.save
    end

    @is_admin = @proposal.has_admin_privilege(current_user, request.session_options[:id], params)


    @user = current_user

    @title = "#{@proposal.name}"
    @keywords = "#{@proposal.domain} #{@proposal.category} #{@proposal.designator} #{@proposal.name}"
    @description = "Learn more and put your best arguments forward about #{@proposal.domain} #{@proposal.category} #{@proposal.designator} #{@proposal.short_name}. You'll be voting on it in the 2011 election!"

    if !session.has_key?(@proposal.id)
      session[@proposal.id] = {
        :included_points => {},
        :deleted_points => {},
        :written_points => []
      }
    end
    # When we are redirected back to the position page after a user creates their account, 
    # we should save their actions and redirect to results page
    if session.has_key?('reify_activities') && session['reify_activities']
      @position = Position.unscoped.find(session['position_to_be_published'])
      # check to see if this user already had a previous position
      prev_pos = Position.unscoped.where(:proposal_id => @proposal.id, :user_id => current_user.id).first
      if prev_pos
        #resolve by combining positions, taking stance from newly submitted...
        prev_pos.stance = @position.stance
        prev_pos.stance_bucket = @position.stance_bucket
        prev_pos.notification_author = @position.notification_author
        prev_pos.notification_demonstrated_interest = @position.notification_demonstrated_interest
        prev_pos.notification_perspective_subscriber = @position.notification_perspective_subscriber
        prev_pos.notification_point_subscriber = @position.notification_point_subscriber
        
        save_actions(prev_pos)
        prev_pos.save
        @position.point_listings.update_all({:user_id => current_user.id, :position_id => prev_pos.id})
        @position.destroy
      else
        @position.published = true
        @position.user_id = current_user.id
        @position.save
        @position.point_listings.update_all({:user_id => current_user.id})        
        save_actions(@position)
      end

      session.delete('reify_activities')
      session.delete('position_to_be_published')  
      redirect_to( proposal_path(@proposal.long_id))
      return
    end

    if is_new
      if current_user
        @position = Position.unscoped.where(:proposal_id => @proposal.id, :user_id => current_user.id).first 
      else
        @position = session.has_key?("position-#{@proposal.id}") ? Position.unscoped.find(session["position-#{@proposal.id}"]) : nil
      end
      if @position.nil?
        @position = Position.unscoped.create!( 
          :stance => 0.0, 
          :proposal_id => @proposal.id, 
          :user_id => @user ? @user.id : nil
        )
        session["position-#{@proposal.id}"] = @position.id
      end
    else
      @position = Position.find( params[:id] )
    end

    #TODO: Right now, if you write an unpublished point, then remove it from your list, you will never be able to include it because
    # the following code does not select the unpublished points by the current user or that are stored in session['written_points'].
    # This is an edge case. We should allow users to delete a point before it is published/included by others, which should further
    # relegate this issue to an insignificant edge case. 
    @pro_points = @proposal.points.includes(:point_links, :user).pros.not_included_by(current_user, session[@proposal.id][:included_points].keys, session[@proposal.id][:deleted_points].keys).
                    ranked_persuasiveness.page( 1 ).per( POINTS_PER_PAGE )    
    @con_points = @proposal.points.includes(:point_links, :user).cons.not_included_by(current_user, session[@proposal.id][:included_points].keys, session[@proposal.id][:deleted_points].keys).
                    ranked_persuasiveness.page( 1 ).per( POINTS_PER_PAGE )

    #TODO: bulk insert...
    PointListing.transaction do

      (@pro_points + @con_points).each do |pnt|
        PointListing.create!(
          :proposal => @proposal,
          :position => @position,
          :point => pnt,
          :user => @user,
          :context => 1
        )
      end
    end
    
    @included_pros = Point.included_by_stored(current_user, @proposal, session[@proposal.id][:deleted_points].keys).includes(:point_links, :user).where(:is_pro => true) + 
                     Point.included_by_unstored(session[@proposal.id][:included_points].keys, @proposal).where(:is_pro => true)
    @included_cons = Point.included_by_stored(current_user, @proposal, session[@proposal.id][:deleted_points].keys).includes(:point_links, :user).where(:is_pro => false) + 
                     Point.included_by_unstored(session[@proposal.id][:included_points].keys, @proposal).where(:is_pro => false)

    @page = 1
  end

  def save_actions ( position )
    actions = session[position.proposal_id]

    actions[:included_points].each do |point_id, value|

      if Inclusion.where( :position_id => position.id ).where( :point_id => point_id).where( :user_id => position.user_id ).count == 0
        Inclusion.create!( { 
          :point_id => point_id,
          :user_id => position.user_id,
          :position_id => position.id,
          :proposal_id => position.proposal_id
        } )      
      end
    end
    actions[:included_points] = {}

    actions[:written_points].each do |pnt_id|
      pnt = Point.unscoped.find( pnt_id )

      notify_parties = pnt.user_id.nil?
      pnt.user_id = position.user_id
      pnt.published = 1
      
      pnt.position_id = position.id
      pnt.update_attributes({"score_stance_group_#{position.stance_bucket}".intern => 0.001})
      pnt.update_absolute_score

      if notify_parties
        pnt.notify_parties(current_tenant, default_url_options)
      end

      #Inclusion.create!( { 
      #  :point_id => pnt_id,
      #  :user_id => position.user_id,
      #  :position_id => position.id,
      #  :proposal_id => position.proposal_id
      #} )      

    end
    actions[:written_points] = []

    actions[:deleted_points].each do |point_id, value|
      current_user.inclusions.where(:point_id => point_id).each do |inc|
        inc.destroy
      end
    end
    actions[:deleted_points] = {}
  end

  def get_stance_val_from_params( params )

    stance = -1 * Float(params[:position][:stance])
    if stance > 1
      stance = 1
    elsif stance < -1
      stance = -1
    end
    bucket = get_bucket(stance)
    
    return stance, bucket
  end
      
      
  def get_bucket(value)
    if value == -1
      return 0
    elsif value == 1
      return 6
    elsif value <= 0.05 && value >= -0.05
      return 3
    elsif value >= 0.5
      return 5
    elsif value <= -0.5
      return 1
    elsif value >= 0.05
      return 4
    elsif value <= -0.05
      return 2
    end   
  end        
end
