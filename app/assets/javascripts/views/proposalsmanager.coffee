class ConsiderIt.ProposalsManagerView extends Backbone.View
  proposal_list_template : _.template($('#tpl_proposal_list').html())

  initialize : (options) ->
    ConsiderIt.router.on 'route:Consider', (long_id) => @do_after_proposal_data_loaded(long_id, "take_position") 
    ConsiderIt.router.on 'route:Aggregate', (long_id) => @do_after_proposal_data_loaded(long_id, "show_results_handler")
    ConsiderIt.router.on 'route:PointDetails', (long_id, point_id) => @do_after_proposal_data_loaded(long_id, "show_point_details_handler", [{point_id : point_id}])
    ConsiderIt.router.on 'route:StaticPosition', (long_id, user_id) => @do_after_proposal_data_loaded(long_id, "prepare_for_static_position", [{user_id : user_id}])

    @listenTo ConsiderIt.router, 'user:signin', =>
      @load_anonymous_data()

      if ConsiderIt.inaccessible_proposal
        ConsiderIt.router.navigate(Routes.proposal_path(ConsiderIt.inaccessible_proposal.long_id), {trigger: true})
        ConsiderIt.inaccessible_proposal = null

    @listenTo ConsiderIt.router, 'user:signout', =>

    ConsiderIt.all_proposals = new ConsiderIt.ProposalList()
    ConsiderIt.all_proposals.add_proposals ConsiderIt.proposals
    if ConsiderIt.current_proposal
      ConsiderIt.all_proposals.add_proposal(ConsiderIt.current_proposal.data) 
      ConsiderIt.current_proposal = null


    @$el.find('#t-bg-content-top').append(@proposal_list_template({completed: false}))
    proposals_collection = new ConsiderIt.ProposalList()
    proposals_collection.add ConsiderIt.all_proposals.where({active: true})
    @proposalsview = new ConsiderIt.ProposalListView({collection : proposals_collection, el : '#m-proposals-container', active : true}) 

    @$el.find('#t-bg-content-top').append(@proposal_list_template({completed: true}))
    proposals_completed_collection = new ConsiderIt.ProposalList()
    proposals_completed_collection.add ConsiderIt.all_proposals.where({active: false}) 
    @proposalsview_completed = new ConsiderIt.ProposalListView({collection : proposals_completed_collection, el : '#m-proposals-container-completed', active : false})     


  render : ->

    @proposalsview.render()
    @proposalsview_completed.render()
    if ConsiderIt.inaccessible_proposal
      if ConsiderIt.limited_user
        @$('[data-target="login"]:first').trigger('click')
      else if ConsiderIt.limited_user_email
        @$('[data-target="create_account"]:first').trigger('click')



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
          proposalview = proposallistview.addModelView(proposal) if !proposalview?

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
          ConsiderIt.all_proposals.add proposal

          proposal.set_data data
          proposalview = proposallistview.getViewByModel(proposal)
          proposalview[callback].apply(proposalview, callback_params)
        # else if data && data['reason'] == 'Access denied'
        #   console.log data

  # After a user signs in, we're going to query the server and get all the points
  # that this user wrote *anonymously* and proposals they have access to. Then we'll update the data properly so
  # that the user can update them.
  load_anonymous_data : ->
    $.get Routes.content_for_user_path(), (data) =>
      for proposal in data.proposals
        ConsiderIt.all_proposals.add_proposals (p for p in data.proposals)

      for pnt in data.points
        [id, long_id, is_pro] = [pnt.point.id, pnt.point.long_id, pnt.point.is_pro]
        proposal = ConsiderIt.all_proposals.findWhere( {long_id : long_id} )
        proposal.update_anonymous_point(id, is_pro) if proposal && proposal.data_loaded
