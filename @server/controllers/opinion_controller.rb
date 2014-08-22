class OpinionController < ApplicationController

  protect_from_forgery

  respond_to :json

  def show
    opinion = Opinion.find(params[:id])

    authorize! :read, opinion
    render :json => opinion.as_json
  end

  def create
    raise "This shouldn't be called anymore"

    opinion = Opinion.create params[:opinion].permit!
    authorize! :create, opinion

    opinion[:user_id] = current_user ? current_user.id : nil
    opinion[:account_id] = current_tenant.id
    update_or_create opinion, params
  end
  
  def update
    opinion = Opinion.find key_id(params)
    authorize! :update, opinion

    update_or_create opinion, params
  end

  def update_or_create(opinion, params)

    fields = ['proposal', 'explanation', 'stance', 'published', 'point_inclusions']
    updates = params.select{|k,v| fields.include? k}

    # Convert proposal key to id
    updates['proposal_id'] = key_id(updates['proposal'])
    updates.delete('proposal')

    # Convert point_inclusions to ids
    incs = updates['point_inclusions']
    if incs == nil
      # Damn rails http://guides.rubyonrails.org/security.html#unsafe-query-generation
      incs = []
    end
    incs = incs.map! {|p| key_id(p, session)}
    include_points(opinion, incs)
    updates['point_inclusions'] = JSON.dump(incs)

    # Grab the proposal
    proposal = Proposal.find(updates['proposal_id'])
    updates['long_id'] = proposal.long_id  # Remove this soon
    
    # Record things for later
    already_published = opinion.published
    stance_changed = already_published && updates['stance'] != opinion.stance
    
    # Update this opinion
    opinion.update_attributes ActionController::Parameters.new(updates).permit!
    opinion.save

    # Follow all the points user included
    for p in opinion.inclusions.map{|i| i.point}
      p.follow!(current_user, :follow => true, :explicit => false)
    end

    # Publish all the user's newly-written points too
    if opinion.published
      Point.where(:user_id => current_user, :long_id => proposal.long_id,
                  :published => false).each do |p|
          p.published = true
          p.save

          ActiveSupport::Notifications.instrument("point:published", 
            :point => p,
            :current_tenant => current_tenant,
            :mail_options => mail_options
          )
      end
    end
    
    opinion.recache

    # Need to add following in somewhere else
    #proposal.follow!(current_user, :follow => params[:follow_proposal], :explicit => true)

    proposal.delay.update_metrics()

    alert_new_published_opinion(proposal, opinion) unless already_published

    # Enable this next line if I make sure it's properly prepared and won't clobber cache
    #proposal[:key] = "/proposal/#{proposal.id}"

    # MIKE! return the modified points (included, deleted) here
    render :json => opinion.as_json

  end


protected

  def include_points (opinion, points)
    curr_inclusions = Inclusion.where(:opinion => opinion.id)

    to_delete = curr_inclusions.select {|i| not points.include? i.point_id}
    to_add = points.select {|p| curr_inclusions.where(:point_id => p).count == 0}

    to_delete_ids = to_delete.map{|i| i.point_id}
    pp("Deleting #{to_delete}, adding #{to_add}")

    Inclusion.transaction do
      # Delete goners
      to_delete.each do |i| 
        i.delete()
        i.point.follow! current_user, :follow => false, :explicit => false
      end
    
      # Add newbies
      to_add.each do |point_id| 
        opinion.include(point_id, current_tenant)
        point = Point.find(point_id)
      end
    end
    # we need to update the point scores of these guys so that includers gets set properly
    # We have to do it after the above transaction so that the changes to inclusions are saved
    # into the database when the update score method is run. 
    Point.transaction do
      for point_id in to_delete + to_add
        point = Point.find(point_id)
        point.update_absolute_score
      end
    end
  end

  def alert_new_published_opinion ( proposal, opinion )

    ActiveSupport::Notifications.instrument("published_new_opinion", 
      :opinion => opinion,
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    # send out confirmation email if user is not yet confirmed
    # if !current_user.confirmed? && current_user.opinions.published.count == 1
    #   ActiveSupport::Notifications.instrument("first_opinion_by_new_user", 
    #     :user => current_user,
    #     :proposal => proposal,
    #     :current_tenant => current_tenant,
    #     :mail_options => mail_options
    #   )
    # end

  end
      
      
 
end
