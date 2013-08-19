# class ConsiderIt.ProposalsManagerView extends Backbone.View
#   proposal_list_template : _.template($('#tpl_proposal_list').html())

#   initialize : (options) ->
#     ConsiderIt.vent.on 'route:Consider', (long_id) => @do_after_proposal_data_loaded(long_id, "take_position") 
#     ConsiderIt.vent.on 'route:Aggregate', (long_id) => @do_after_proposal_data_loaded(long_id, "show_results_handler")
#     ConsiderIt.vent.on 'route:PointDetails', (long_id, point_id) => @do_after_proposal_data_loaded(long_id, "show_point_details_handler", [{point_id : point_id}])
#     ConsiderIt.vent.on 'route:StaticPosition', (long_id, user_id) => @do_after_proposal_data_loaded(long_id, "prepare_for_static_position", [{user_id : user_id}])

#     # if ConsiderIt.inaccessible_proposal
#     #   ConsiderIt.request 'user:signin:set_redirect', Routes.proposal_path(ConsiderIt.inaccessible_proposal.long_id)
#     #   ConsiderIt.inaccessible_proposal = null


#     @$el.append(@proposal_list_template({completed: false}))
#     proposals_collection = new ConsiderIt.ProposalList()
#     proposals_collection.add ConsiderIt.all_proposals.where({active: true})
#     @proposalsview = new ConsiderIt.ProposalListView({collection : proposals_collection, el : '#m-proposals-container', active : true}) 

#     @$el.append(@proposal_list_template({completed: true}))
#     proposals_completed_collection = new ConsiderIt.ProposalList()
#     proposals_completed_collection.add ConsiderIt.all_proposals.where({active: false}) 
#     @proposalsview_completed = new ConsiderIt.ProposalListView({collection : proposals_completed_collection, el : '#m-proposals-container-completed', active : false})     


#   render : ->
#     @proposalsview.render()
#     @proposalsview_completed.render()
#     # if ConsiderIt.inaccessible_proposal
#     #   ConsiderIt.vent.trigger 'signin:requested'

#   do_after_proposal_data_loaded : (long_id, callback, callback_params = []) ->

#     proposal = @proposalsview.collection.findWhere({long_id: long_id})
#     proposal = @proposalsview_completed.collection.findWhere({long_id: long_id}) if !proposal?

#     if proposal?
#       proposallistview = if proposal.get('active') then @proposalsview else @proposalsview_completed

#     proposalview = if proposal? then proposallistview.getViewByModel(proposal) else null

#     if proposalview? && proposal.data_loaded
#       proposalview[callback].apply(proposalview, callback_params)
#     else if proposal?
#       callback_params[0]['data_just_loaded'] = true if callback_params.length > 0
#       $.get Routes.proposal_path(long_id), (data) => 
#         if data && data['result'] == 'success'
#           proposal.set_data(data)
#           proposalview = proposallistview.addModelView(proposal) if !proposalview?

#           proposalview[callback].apply(proposalview, callback_params)
          
#         # else if data && data['reason'] == 'Access denied'
#         #   console.log data

#     else
#       callback_params[0]['data_just_loaded'] = true if callback_params.length > 0

#       $.get Routes.proposal_path(long_id), (data) => 
#         if data && data['result'] == 'success'
#           proposal = new ConsiderIt.Proposal(data.proposal)
#           proposallistview = if proposal.get('active') then @proposalsview else @proposalsview_completed

#           proposallistview.collection.add proposal
#           proposal = proposallistview.collection.get(proposal.id) #sometimes the collection won't keep the same proposal object
#           ConsiderIt.all_proposals.add proposal

#           proposal.set_data data
#           proposalview = proposallistview.getViewByModel(proposal)
#           proposalview[callback].apply(proposalview, callback_params)
#         # else if data && data['reason'] == 'Access denied'
#         #   console.log data
