class ConsiderIt.ProposalsManagerView extends Backbone.View

  initialize : (options) ->
    ConsiderIt.router.on 'route:Consider', (long_id) => @do_after_proposal_data_loaded(long_id, "take_position") 
    ConsiderIt.router.on 'route:Aggregate', (long_id) => @do_after_proposal_data_loaded(long_id, "show_results_handler")
    ConsiderIt.router.on 'route:PointDetails', (long_id, point_id) => @do_after_proposal_data_loaded(long_id, "show_point_details_handler", [{point_id : point_id}])
    ConsiderIt.router.on 'route:StaticPosition', (long_id, user_id) => @do_after_proposal_data_loaded(long_id, "prepare_for_static_position", [{user_id : user_id}])

  do_after_proposal_data_loaded : (long_id, callback, callback_params = []) ->

    proposal = @proposalsview.collection.findWhere({long_id: long_id})
    proposal = @proposalsview_completed.collection.findWhere({long_id: long_id}) if !proposal?

    if proposal?
      proposallistview = if proposal.get('active') then @proposalsview else @proposalsview_completed

    proposalview = if proposal? then proposallistview.getViewByModel(proposal) else null

    if proposalview? && proposal.data_loaded
      proposalview[callback].apply(proposalview, callback_params)
    else if proposal?
      callback_params[0]['data_just_loaded'] = true if callback_params.length > 0
      $.get Routes.proposal_path(long_id), (data) => 
        if data && data['result'] == 'success'
          proposal.set_data(data)
          proposalview[callback].apply(proposalview, callback_params)
          
        # else if data && data['reason'] == 'Access denied'
        #   console.log data

    else
      callback_params[0]['data_just_loaded'] = true if callback_params.length > 0

      $.get Routes.proposal_path(long_id), (data) => 
        if data && data['result'] == 'success'
          proposal = new ConsiderIt.Proposal(data.proposal)
          proposallistview = if proposal.get('active') then @proposalsview else @proposalsview_completed

          proposallistview.collection.add proposal
          proposal = proposallistview.collection.get(proposal.id) #sometimes the collection won't keep the same proposal object
          ConsiderIt.app.proposals.add proposal

          proposal.set_data data
          proposalview = proposallistview.getViewByModel(proposal)
          proposalview[callback].apply(proposalview, callback_params)
        # else if data && data['reason'] == 'Access denied'
        #   console.log data

  render : ->

    #console.log new ConsiderIt.ProposalList(ConsiderIt.app.proposals.where({active: true}))
    #console.log proposals_collection    
    #console.log new ConsiderIt.ProposalList(ConsiderIt.app.proposals.where({active: true}))
    proposals_collection = new ConsiderIt.ProposalList()
    proposals_collection.add ConsiderIt.app.proposals.where({active: true})
    @proposalsview = new ConsiderIt.ProposalListView({collection : proposals_collection, el : '#m-proposals-container', active : true}) if !@proposalsview?
    proposals_completed_collection = new ConsiderIt.ProposalList()
    proposals_completed_collection.add ConsiderIt.app.proposals.where({active: false}) 
    @proposalsview_completed = new ConsiderIt.ProposalListView({collection : proposals_completed_collection, el : '#m-proposals-container-completed', active : false}) if !@proposalsview_completed?    

    @proposalsview.renderAllItems()
    @proposalsview_completed.renderAllItems()