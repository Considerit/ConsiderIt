#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class PositionsController < ApplicationController
  #include ActsAsFollowable::ControllerMethods

  protect_from_forgery

  respond_to :html

  POINTS_PER_PAGE = 3
  
  def create
    @proposal = Proposal.find_by_long_id(params[:long_id])

    (stance, bucket) = get_stance_val_from_params(params)

    params[:position].update({
      :user_id => !current_user.nil? ? current_user.id : nil,
      :stance => stance,
      :stance_bucket => bucket,
      :published => !current_user.nil? 
    })

    @position = Position.find(params[:position][:position_id])
    params[:position].delete(:position_id)
    @position.update_attributes(params[:position])
    authorize! :create, @position
    @position.save

    if !current_user.nil?
      # I don't think this is ever reached
      save_actions(@position)      
      @position.follow!(current_user, :follow => true, :explicit => false)
      @proposal.follow!(current_user, :follow => params[:follow_proposal] == 'true', :explicit => true)
    else
      # stash until after user registration
      session['position_to_be_published'] = @position.id
      session['position_to_be_published_extras'] = { :follow_proposal => params[:follow_proposal] }
    end

    respond_with(@proposal, @position) do |format|
      format.html { redirect_to(  proposal_path(@proposal.long_id, :anchor => 'explore_proposal')  ) }
      format.js { render :json => { :result => 'successful' }.to_json }
    end
  end
  
  def update
    @proposal = Proposal.find_by_long_id(params[:long_id])

    if current_user.nil? 
      redirect_to(  proposal_path(@proposal.long_id, :anchor => 'explore_proposal')
      return
    end

    @position = current_user.positions.find(params[:id])
    already_published = @position.published

    (stance, bucket) = get_stance_val_from_params(params)

    params[:position].delete(:position_id)
    @position.update_attributes(params[:position])
    @position.stance = stance
    @position.stance_bucket = bucket
    @position.published = 1

    authorize! :update, @position

    @position.save
    @position.track!

    alert_new_published_position(@proposal, @position) unless already_published

    @proposal.follow!(current_user, :follow => params[:follow_proposal] == 'true', :explicit => true)

    save_actions(@position)
    
    respond_with(@proposal, @position) do |format|
      format.html { redirect_to(  proposal_path(@proposal.long_id, :anchor => 'explore_proposal') ) }
    end
  end

  #the destroy method here only discards the current changes to the position
  def destroy
    @proposal = Proposal.find_by_long_id(params[:long_id])
    if current_user
      @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
    else
      @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
    end

    authorize! :destroy, @position
    
    redirect_to(proposal_path(@position.proposal.long_id, :anchor => 'explore_proposal'))
    session.delete('reify_activities')
    session.delete('position_to_be_published')
    session.delete('position_to_be_published_extras')

    ApplicationController.reset_user_activities(session, @proposal)

  end

  def new
    handle_new_edit(true)
  end

  def edit
    handle_new_edit(false)
  end

protected
  def handle_new_edit(is_new)
    @proposal = nil

    if params.has_key? :proposal_id
      @proposal = Proposal.find(params[:proposal_id])
    elsif params.has_key? :long_id
      @proposal = Proposal.find_by_long_id(params[:long_id])
    end

    if @proposal.nil?
      redirect_to root_path
      return
    end

    if @proposal.session_id.nil?
      @proposal.session_id = request.session_options[:id]
      @proposal.save
    end

    @can_update = can? :update, @proposal
    @can_destroy = can? :destroy, @proposal
    
    @user = current_user

    @title = "#{@proposal.name}"
    if current_tenant.app_title == 'Living Voters Guide'
      @keywords = "#{current_tenant.app_title} #{@proposal.category} #{@proposal.designator} #{@proposal.name} 2012 election"
      @description = "Hear and engage fellow citizens about #{current_tenant.identifier} #{@proposal.category} #{@proposal.designator} #{@proposal.short_name}. You'll be voting on it in the November 2012 election!"
    elsif current_tenant.app_title == 'Office of Hawaiian Affairs'
      @keywords = "discuss, deliberate, vote, hawaii, #{@proposal.name}"
      @description = "Hear and engage the Office of Hawaiian Affairs about #{@proposal.name}."
    else
      @keywords = "discuss, deliberate, vote, #{@proposal.name}"
      @description = "Hear and engage about #{@proposal.name}."
    end



    ApplicationController.reset_user_activities(session, @proposal) if !session.has_key?(@proposal.id)
    # When we are redirected back to the position page after a user creates their account, 
    # we should save their actions and redirect to results page
    if session.has_key?('reify_activities') && session['reify_activities']
      @position = Position.find(session['position_to_be_published'])
      # check to see if this user already had a previous position
      prev_pos = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last
      if prev_pos
        #resolve by combining positions, taking stance from newly submitted...
        prev_pos.stance = @position.stance
        prev_pos.stance_bucket = @position.stance_bucket
        prev_pos.explanation = @position.explanation
        prev_pos.published = true
        prev_pos.save
        save_actions(prev_pos)
        
        prev_pos.subsume(@position)
        @position.destroy
      else
        @position.published = true
        @position.user_id = current_user.id
        @position.save
        @position.point_listings.update_all({:user_id => current_user.id})
        @position.follow!(current_user, :follow => session['position_to_be_published_extras'][:follow_proposal] == 'true', :explicit => false)        
        save_actions(@position)
        alert_new_published_position(@proposal, @position) 
      end

      session.delete('reify_activities')
      session.delete('position_to_be_published')  
      redirect_to( proposal_path(@proposal.long_id, :anchor => 'explore_proposal'))
      return
    end

    if is_new
      if current_user
        @position = Position.where(:proposal_id => @proposal.id, :user_id => current_user.id).last 
      else
        @position = session.has_key?("position-#{@proposal.id}") ? Position.find(session["position-#{@proposal.id}"]) : nil
      end
      if @position.nil?
        @position = Position.create!( 
          :stance => 0.0, 
          :proposal_id => @proposal.id, 
          :user_id => @user ? @user.id : nil,
          :account_id => current_tenant.id
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
    @pro_points = @proposal.points.viewable.includes(:user).pros.not_included_by(current_user, session[@proposal.id][:included_points].keys, session[@proposal.id][:deleted_points].keys).
                    ranked_persuasiveness.page( 1 ).per( POINTS_PER_PAGE )    
    @con_points = @proposal.points.viewable.includes(:user).cons.not_included_by(current_user, session[@proposal.id][:included_points].keys, session[@proposal.id][:deleted_points].keys).
                    ranked_persuasiveness.page( 1 ).per( POINTS_PER_PAGE )

    (@pro_points + @con_points).each do |pnt|
      session[@proposal.id][:viewed_points].push( [pnt.id, 1] )
    end
        
    @included_pros = Point.included_by_stored(current_user, @proposal, session[@proposal.id][:deleted_points].keys).includes(:user).where(:is_pro => true) + 
                     Point.included_by_unstored(session[@proposal.id][:included_points].keys, @proposal).where(:is_pro => true)
    @included_cons = Point.included_by_stored(current_user, @proposal, session[@proposal.id][:deleted_points].keys).includes(:user).where(:is_pro => false) + 
                     Point.included_by_unstored(session[@proposal.id][:included_points].keys, @proposal).where(:is_pro => false)

    @page = 1
  end

  def save_actions ( position )
    actions = session[position.proposal_id]

    Inclusion.transaction do
      actions[:included_points].each do |point_id, value|
        if Inclusion.where( :position_id => position.id, :point_id => point_id, :user_id => position.user_id ).count == 0
          inc = Inclusion.create!( { 
            :point_id => point_id,
            :user_id => position.user_id,
            :position_id => position.id,
            :proposal_id => position.proposal_id
          } )
          if !actions[:written_points].include?(point_id) 
            pnt = Point.find(point_id)
            pnt.update_absolute_score
            inc.track!
            pnt.follow!(current_user, :follow => true, :explicit => false)
          end
        end
      end
    end
    actions[:included_points] = {}

    actions[:written_points].each do |pnt_id|
      pnt = Point.find( pnt_id )

      pnt.user_id = position.user_id
      pnt.published = 1
      
      pnt.position_id = position.id
      pnt.update_attributes({"score_stance_group_#{position.stance_bucket}".intern => 0.001})
      pnt.update_absolute_score

      pnt.track!
      pnt.follow!(current_user, :follow => true, :explicit => false)

      #TODO: aggregate these into one email
      ActiveSupport::Notifications.instrument("new_published_Point", 
        :point => pnt,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )

    end
    actions[:written_points] = []

    actions[:deleted_points].each do |point_id, value|
      current_user.inclusions.where(:point_id => point_id).each do |inc|
        inc.destroy
        inc.point.update_absolute_score
      end
    end
    actions[:deleted_points] = {}

    point_listings = []
    actions[:viewed_points].to_set.each do |point_id, context|
      point_listings.push("(#{position.proposal_id}, #{position.id}, #{point_id}, #{position.user_id}, #{context})")
    end
    if point_listings.length > 0
      qry = "INSERT INTO point_listings 
              (proposal_id, position_id, point_id, user_id, context) 
              VALUES #{point_listings.join(',')}"

      ActiveRecord::Base.connection.execute qry
    end

    actions[:viewed_points] = []
  end

  def alert_new_published_position ( proposal, position )
    ActiveSupport::Notifications.instrument("published_new_position", 
      :position => position,
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    # send out notification of a new proposal only after first position is made on it
    if proposal.positions.published.count == 1
      ActiveSupport::Notifications.instrument("new_published_proposal", 
        :proposal => proposal,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    # send out confirmation email if user is not yet confirmed
    if !current_user.confirmed? && current_user.positions.published.count == 1
      ActiveSupport::Notifications.instrument("first_position_by_new_user", 
        :user => current_user,
        :proposal => proposal,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

  end

  def get_stance_val_from_params( params )

    stance = -1 * Float(params[:position][:stance])
    if stance > 1
      stance = 1
    elsif stance < -1
      stance = -1
    end
    bucket = Position.get_bucket(stance)
    
    return stance, bucket
  end
      
      
 
end
