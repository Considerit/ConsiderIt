class OpinionsController < ApplicationController

  protect_from_forgery

  respond_to :json


  def create
    opinion = Opinion.create params[:opinion].permit!
    opinion[:user_id] = current_user ? current_user.id : nil
    opinion[:account_id] = current_tenant.id
    update_or_create opinion
  end
  
  def update
    opinion = Opinion.find params[:id]
    update_or_create opinion
  end

  def update_or_create(opinion)
    raise 'Cannot update without a logged in user' if !current_user || !current_user.registration_complete
    authorize! :update, opinion

    proposal = opinion.proposal
    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    already_published = opinion.published

    stance_changed = already_published && params[:opinion].has_key?(:stance) && opinion.stance != params[:opinion][:stance] 

    update_attrs = {
      :user_id => current_user.id,
      :proposal => proposal, 
      :long_id => proposal.long_id
    }

    if params[:opinion].has_key? :explanation
      update_attrs[:explanation] = params[:opinion][:explanation]
    end
    if params[:opinion].has_key? :stance
      update_attrs[:stance] = params[:opinion][:stance]
    end

    #if an existing published opinion exists for this user, handle it
    existing_opinion = proposal.opinions.published.where("id != #{opinion.id}").find_by_user_id current_user.id

    update_attrs[:published] = true
    opinion.update_attributes ActionController::Parameters.new(update_attrs).permit!

    if existing_opinion
      opinion.subsume existing_opinion
    end

    params[:included_points] ||= []
    params[:included_points].each do |pnt|
      session[opinion.proposal_id][:included_points][pnt] = true
    end

    params[:viewed_points] ||= []
    params[:viewed_points].each do |pnt|
      session[opinion.proposal_id][:viewed_points].push([pnt,-1])
    end

    updated_points = save_actions(opinion)

    inclusions = Inclusion.where(:user_id => opinion.user_id, :proposal_id => opinion.proposal_id).select(:point_id)
    
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

    opinion.update_inclusions

    opinion.track!

    #proposal.follow!(current_user, :follow => params[:opinion][:follow_proposal] == 'true', :explicit => true)
    #opinion.follow!(current_user, :follow => true, :explicit => false)
    proposal.follow!(current_user, :follow => params[:follow_proposal], :explicit => true)

    # update metrics right away if a new point could become a top point; otherwise process in background
    if updated_points.count > 0 && (proposal.top_pro.nil? || proposal.top_pro.nil?)
      proposal.update_metrics()
    else
      proposal.delay.update_metrics()
    end

    alert_new_published_opinion(proposal, opinion) unless already_published

    results = {
      :opinion => opinion,
      :updated_points => updated_points.metrics_fields,
      :proposal => proposal,
      :subsumed_opinion => existing_opinion
    }
        
    render :json => results

  end

  def show
    if request.xhr?
      proposal = Proposal.find_by_long_id(params[:long_id])
      opinion = proposal.opinions.published.where(:user_id => params[:user_id]).first
      user = opinion.user

      if opinion.nil?
        render :json => {
          :result => 'failed', 
          :reason => 'That opinion does not exist.'
        }
      elsif cannot?(:read, opinion)
        render :json => {
          :result => 'failed', 
          :reason => 'You do not have permission to view that opinion.'
        }
      else    
        render :json => {
          :result => 'successful',
          :included_pros => Point.included_by_stored(user, proposal, nil).where(:is_pro => true).map {|pnt| pnt.id},
          :included_cons => Point.included_by_stored(user, proposal, nil).where(:is_pro => false).map {|pnt| pnt.id},
          :stance => opinion.stance_segment
        }
      end
    else
      render :nothing => true, :layout => true
    end

  end


protected

  def save_actions ( opinion )
    actions = session[opinion.proposal_id]
    updated_points = []

    Inclusion.transaction do
      actions[:included_points].each do |point_id, value|
        if Inclusion.where( :point_id => point_id, :user_id => opinion.user_id ).count == 0
          inc_attrs = { 
            :point_id => point_id,
            :user_id => opinion.user_id,
            :opinion_id => opinion.id,
            :proposal_id => opinion.proposal_id,
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

      pnt.user_id = opinion.user_id
      pnt.published = 1
      
      pnt.opinion_id = opinion.id
      update_attrs = {"score_stance_group_#{opinion.stance_segment}".intern => 0.001, :score => 0.0000001}
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
      point_listings.push("(#{opinion.proposal_id}, #{opinion.id}, #{point_id}, #{opinion.user_id}, #{current_tenant.id}, '#{now}', '#{now}')")
    end
    if point_listings.length > 0
      qry = "INSERT INTO point_listings 
              (proposal_id, opinion_id, point_id, user_id, account_id, created_at, updated_at) 
              VALUES #{point_listings.join(',')}
              ON DUPLICATE KEY UPDATE count=count+1"

      ActiveRecord::Base.connection.execute qry
    end

    actions[:viewed_points] = []


    return updated_points
  end

  def alert_new_published_opinion ( proposal, opinion )
    ActiveSupport::Notifications.instrument("published_new_opinion", 
      :opinion => opinion,
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    # send out notification of a new proposal only after first opinion is made on it
    if proposal.opinions.published.count == 1
      ActiveSupport::Notifications.instrument("proposal:created", 
        :proposal => proposal,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    # send out confirmation email if user is not yet confirmed
    if !current_user.confirmed? && current_user.opinions.published.count == 1
      ActiveSupport::Notifications.instrument("first_opinion_by_new_user", 
        :user => current_user,
        :proposal => proposal,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

  end
      
      
 
end
