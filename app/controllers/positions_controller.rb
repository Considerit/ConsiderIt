class PositionsController < ApplicationController

  protect_from_forgery

  respond_to :json
  
  def update
    raise 'Cannot update without a logged in user' if !current_user || !current_user.registration_complete

    position = Position.find params[:id]
    authorize! :update, position

    proposal = position.proposal
    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    already_published = position.published

    update_attrs = {
      :user_id => current_user.id,
      :proposal => proposal
    }

    if params[:position].has_key? :explanation
      update_attrs[:explanation] = params[:position][:explanation]
    end
    if params[:position].has_key? :stance
      update_attrs[:stance] = params[:position][:stance]
    end

    update_attrs[:published] = true
    position.update_attributes update_attrs

    params[:position][:included_points] ||= []
    params[:position][:included_points].each do |pnt|
      session[position.proposal_id][:included_points][pnt] = true
    end

    params[:position][:viewed_points] ||= []
    params[:position][:viewed_points].each do |pnt|
      session[position.proposal_id][:viewed_points].push([pnt,-1])
    end

    save_actions(position)

    position.point_inclusions = Inclusion.where(:user_id => position.user_id, :proposal_id => position.proposal_id).select(:point_id).map {|x| x.point_id}.compact.to_s
    #position.point_inclusions = position.inclusions(:select => [:point_id]).map {|x| x.point_id}.compact.to_s       
    position.save
    
    position.track!

    #proposal.follow!(current_user, :follow => params[:position][:follow_proposal] == 'true', :explicit => true)
    position.follow!(current_user, :follow => true, :explicit => false)
    proposal.follow!(current_user, :follow => params[:follow_proposal] == 'true', :explicit => true)


    proposal.delay.update_metrics()
    
    alert_new_published_position(proposal, position) unless already_published

    render :json => position

  end

  def show
    if request.xhr?
      proposal = Proposal.find_by_long_id(params[:long_id])
      position = proposal.positions.published.where(:user_id => params[:user_id]).first
      user = position.user

      if position.nil?
        render :json => {
          :result => 'failed', 
          :reason => 'That position does not exist.'
        }
      elsif cannot?(:read, position)
        render :json => {
          :result => 'failed', 
          :reason => 'You do not have permission to view that position.'
        }
      else    
        render :json => {
          :result => 'successful',
          :included_pros => Point.included_by_stored(user, proposal, nil).where(:is_pro => true).map {|pnt| pnt.id},
          :included_cons => Point.included_by_stored(user, proposal, nil).where(:is_pro => false).map {|pnt| pnt.id},
          :stance => position.stance_bucket
        }
      end
    end

  end


protected

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
      
      
 
end
