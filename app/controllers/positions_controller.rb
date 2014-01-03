class PositionsController < ApplicationController

  protect_from_forgery

  respond_to :json


  def create
    position = Position.create params[:position].permit!
    position[:user_id] = current_user ? current_user.id : nil
    position[:account_id] = current_tenant.id
    update_or_create position
  end
  
  def update
    position = Position.find params[:id]
    update_or_create position
  end

  def update_or_create(position)
    raise 'Cannot update without a logged in user' if !current_user || !current_user.registration_complete
    authorize! :update, position

    proposal = position.proposal
    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    already_published = position.published

    stance_changed = already_published && params[:position].has_key?(:stance) && position.stance != params[:position][:stance] 

    update_attrs = {
      :user_id => current_user.id,
      :proposal => proposal, 
      :long_id => proposal.long_id
    }

    if params[:position].has_key? :explanation
      update_attrs[:explanation] = params[:position][:explanation]
    end
    if params[:position].has_key? :stance
      update_attrs[:stance] = params[:position][:stance]
    end

    #if an existing published position exists for this user, handle it
    existing_position = proposal.positions.published.where("id != #{position.id}").find_by_user_id current_user.id

    update_attrs[:published] = true
    position.update_attributes ActionController::Parameters.new(update_attrs).permit!

    if existing_position
      position.subsume existing_position
    end

    params[:included_points] ||= []
    params[:included_points].each do |pnt|
      session[position.proposal_id][:included_points][pnt] = true
    end

    params[:viewed_points] ||= []
    params[:viewed_points].each do |pnt|
      session[position.proposal_id][:viewed_points].push([pnt,-1])
    end

    updated_points = save_actions(position)

    inclusions = Inclusion.where(:user_id => position.user_id, :proposal_id => position.proposal_id).select(:point_id)
    
    inclusions.each do |inc|
      if stance_changed && !updated_points.include?(inc)
        inc.point.update_absolute_score
        updated_points.push inc.point_id
      end
    end

    updated_points = Point.where('id in (?)', updated_points)
    updated_points.each do |pnt|
      pnt.update_absolute_score
    end

    position.update_inclusions

    position.track!

    #proposal.follow!(current_user, :follow => params[:position][:follow_proposal] == 'true', :explicit => true)
    #position.follow!(current_user, :follow => true, :explicit => false)
    proposal.follow!(current_user, :follow => params[:follow_proposal], :explicit => true)

    proposal.update_metrics()

    alert_new_published_position(proposal, position) unless already_published

    results = {
      :position => position,
      :updated_points => updated_points.metrics_fields,
      :proposal => proposal,
      :subsumed_position => existing_position
    }
        
    render :json => results

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
    updated_points = []

    Inclusion.transaction do
      actions[:included_points].each do |point_id, value|
        if Inclusion.where( :position_id => position.id, :point_id => point_id, :user_id => position.user_id ).count == 0
          inc_attrs = { 
            :point_id => point_id,
            :user_id => position.user_id,
            :position_id => position.id,
            :proposal_id => position.proposal_id,
            :account_id => current_tenant.id
          }
          
          inc = Inclusion.create! ActionController::Parameters.new(inc_attrs).permit!
          if !actions[:written_points].include?(point_id) 
            pnt = Point.find(point_id)
            inc.track!
            pnt.follow!(current_user, :follow => true, :explicit => false)
            updated_points.push(point_id)
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
      update_attrs = {"score_stance_group_#{position.stance_bucket}".intern => 0.001, :score => 0.0000001}
      pnt.update_attributes ActionController::Parameters.new(update_attrs).permit!

      updated_points.push(pnt_id)


      pnt.track!
      pnt.follow!(current_user, :follow => true, :explicit => false)

      #TODO: aggregate these into one email
      ActiveSupport::Notifications.instrument("point:published", 
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
      updated_points.push(point_id)
    end

    actions[:deleted_points] = {}

    point_listings = []
    now = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    actions[:viewed_points].to_set.each do |point_id, context|
      point_listings.push("(#{position.proposal_id}, #{position.id}, #{point_id}, #{position.user_id}, #{current_tenant.id}, '#{now}', '#{now}')")
    end
    if point_listings.length > 0
      qry = "INSERT INTO point_listings 
              (proposal_id, position_id, point_id, user_id, account_id, created_at, updated_at) 
              VALUES #{point_listings.join(',')}
              ON DUPLICATE KEY UPDATE count=count+1"

      ActiveRecord::Base.connection.execute qry
    end

    actions[:viewed_points] = []


    return updated_points
  end

  def alert_new_published_position ( proposal, position )
    ActiveSupport::Notifications.instrument("published_new_position", 
      :position => position,
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    # send out notification of a new proposal only after first position is made on it
    if proposal.positions.published.count == 1
      ActiveSupport::Notifications.instrument("proposal:created", 
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
