class OpinionController < ApplicationController

  def show
    opinion = Opinion.find(params[:id])
    authorize! 'read opinion', opinion
    dirty_key "/opinion/#{params[:id]}"
    render :json => []
  end
  
  def update
    opinion = Opinion.find key_id(params)
    authorize! 'update opinion', opinion

    fields = ['proposal', 'stance', 'point_inclusions', 'explanation']
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

      write_to_log({
        :what => 'published opinion',
        :where => proposal.slug
      })
    elsif params.has_key?('published') && !params['published'] && opinion.published
      opinion.unpublish()
      write_to_log({
        :what => 'unpublished opinion',
        :where => proposal.slug
      })

    end

    # clear the histogram cache because we got a new opinion
    if opinion.published
      proposal.histocache = nil
      proposal.save

      dirty_key "/proposal/#{proposal.id}"
    end

    #proposal.delay.update_metrics()
    
    dirty_key "/opinion/#{opinion.id}"

    render :json => []

  end

end
