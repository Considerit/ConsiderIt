class OpinionController < ApplicationController

  protect_from_forgery

  respond_to :json

  def show
    opinion = Opinion.find(params[:id])

    authorize! :read, opinion
    render :json => opinion.as_json
  end
  
  def update
    opinion = Opinion.find key_id(params)
    authorize! :update, opinion

    fields = ['proposal', 'explanation', 'stance', 'point_inclusions']
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
    opinion.update_inclusions incs
    updates['point_inclusions'] = JSON.dump(incs)

    # Grab the proposal
    proposal = Proposal.find(updates['proposal_id'])
    updates['long_id'] = proposal.long_id  # Remove this soon
    
    # Update the normal fields
    opinion.update_attributes ActionController::Parameters.new(updates).permit!
    opinion.save

    # Update published
    if params['published'] && !opinion.published
      opinion.publish()  # This will also publish all the newly-written points
    end

    # Need to add following in somewhere else
    #proposal.follow!(current_user, :follow => params[:follow_proposal], :explicit => true)

    #proposal.delay.update_metrics()

    # Enable this next line if I make sure it's properly prepared and won't clobber cache
    #proposal[:key] = "/proposal/#{proposal.id}"
    
    dirty_key("/opinion/#{opinion.id}")
    render :json => affected_objects()

  end
end
