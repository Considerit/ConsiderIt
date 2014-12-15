class OpinionController < ApplicationController

  respond_to :json

  def show
    opinion = Opinion.find(params[:id])
    authorize! 'read opinion', opinion
    dirty_key "/opinion/#{params[:id]}"
    render :json => []
  end
  
  def update
    opinion = Opinion.find key_id(params)
    authorize! 'update opinion', opinion

    fields = ['proposal', 'stance', 'point_inclusions']
    updates = params.select{|k,v| fields.include? k}

    # Convert proposal key to id
    updates['proposal_id'] = key_id(updates['proposal'])
    updates.delete('proposal')

    # Convert point_inclusions to ids
    incs = updates['point_inclusions']
    incs = [] if incs.nil? # Damn rails http://guides.rubyonrails.org/security.html#unsafe-query-generation

    incs = incs.map! {|p| key_id(p)}
    opinion.update_inclusions incs
    updates['point_inclusions'] = JSON.dump(incs)

    # Grab the proposal
    proposal = Proposal.find(updates['proposal_id'])
    
    # Update the normal fields
    opinion.update_attributes updates
    opinion.save

    # Update published
    if params['published'] && !opinion.published
      authorize! 'publish opinion', proposal

      opinion.publish()  # This will also publish all the newly-written points
      dirty_key "/page/homepage" # you're now a recent contributor!

      write_to_log({
        :what => 'published opinion',
        :where => proposal.slug
      })
    end

    # Need to add following in somewhere else
    #proposal.follow!(current_user, :follow => params[:follow_proposal], :explicit => true)

    #proposal.delay.update_metrics()
    
    dirty_key "/opinion/#{opinion.id}"

    render :json => []

  end
end
