class OpinionController < ApplicationController

  protect_from_forgery

  respond_to :json

  def show
    opinion = Opinion.find(params[:id])

    authorize! :read, opinion
    render :json => opinion.as_json
  end

  def create
    opinion = Opinion.create params[:opinion].permit!
    authorize! :create, opinion

    opinion[:user_id] = current_user ? current_user.id : nil
    opinion[:account_id] = current_tenant.id
    update_or_create opinion, params
  end
  
  def update
    opinion = Opinion.find key_id(params[:key])
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
    incs = incs.map! {|p| key_id(p)}
    include_points(opinion, incs)
    updates['point_inclusions'] = JSON.dump(incs)

    # Grab the proposal
    proposal = Proposal.find(updates['proposal_id'])
    updates['long_id'] = proposal.long_id  # Remove this soon
    
    # Record things for later
    already_published = opinion.published
    stance_changed = already_published && updates['stance'] != opinion.stance
    existing_opinion = current_user && \
            proposal.opinions.published.where("id != #{opinion.id}").find_by_user_id(current_user.id)

    # Update this opinion
    opinion.update_attributes ActionController::Parameters.new(updates).permit!

    if existing_opinion
      opinion.subsume existing_opinion
    end

    # Mike, you might want to check if this is a good place for this. 
    # Basically we need a way of updating this Opinion's owner after
    # they've logged in and seek to publish the opinion. It is possible
    # that we might actually want to set the user_id of all the user's opinions,
    # points, etc in the current_user methods upon authorization. 
    if opinion.published && !opinion.user_id
      opinion.user_id = current_user.id
    end

    opinion.save

    # Need to add back in this tracking of viewed points
    # params[:viewed_points] ||= []
    # params[:viewed_points].each do |pnt|
    #   session[opinion.proposal_id][:viewed_points].push([pnt,-1])
    # end

    # Add this back in when I know how to make it work
    #updated_points = save_actions(opinion)
    updated_points = []
    
    if stance_changed
      # if the user has updated their stance, we need to update the scores of all the points that 
      # they included so that the segment metrics are correct
      Inclusion.where(:user_id => opinion.user_id, :proposal_id => opinion.proposal_id).select(:point_id).each do |inc|
        updated_points[inc.point_id] = 1
      end
    end

    updated_points = Point.where('id in (?)', updated_points)
    updated_points.each do |pnt|
      pnt.update_absolute_score
    end

    opinion.update_inclusions

    opinion.track!

    # Need to add following in somewhere else
    #proposal.follow!(current_user, :follow => params[:follow_proposal], :explicit => true)

    # update proposal metrics right away if a new point could become a
    # top point; otherwise schedule an update to be processed offline
    if updated_points.count > 0 && (proposal.top_pro.nil? || proposal.top_pro.nil?)
      proposal.update_metrics()
    else
      proposal.delay.update_metrics()
    end

    # This isn't working... undefined method confirmed? ... need to fix
    #alert_new_published_opinion(proposal, opinion) unless already_published

    # Enable this next line if I make sure it's properly prepared and won't clobber cache
    #proposal[:key] = "/proposal/#{proposal.id}"

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
      to_delete.each {|i| i.delete()}
    
      # Add newbies
      to_add.each {|point_id| opinion.include(point_id, current_tenant)}
    end
  end

  def save_actions ( opinion )
    actions = session[opinion.proposal_id]
    updated_points = {}

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
            updated_points[point_id] = 1
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

      updated_points[pnt_id] = 1


      pnt.track!
      pnt.follow!(current_user, :follow => true, :explicit => false)


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
      end
      updated_points[point_id] = 1
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
