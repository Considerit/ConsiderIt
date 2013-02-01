class ConsiderIt.AppView extends Backbone.View

  el: '#content'
  #@itemView : ConsiderIt.ProposalView

  initialize : (options) -> 
    @proposals = new ConsiderIt.ProposalList()
    @proposals.reset( _.pluck(_.values(ConsiderIt.proposals), 'model'))

    @proposalsview = new ConsiderIt.ProposalListView({collection : @proposals, el : '#proposals'})
    
    ConsiderIt.router.on('route:Consider', @show_position)
    ConsiderIt.router.on('route:Aggregate', @show_results)

    #handle here because of dependency on proposal being loaded first
    ConsiderIt.router.on('route:PointDetails', @handle_point_details) 

  render : () -> 
    @proposalsview.renderAllItems()
    this

  #route handlers
  show_position : (long_id) ->
    ConsiderIt.proposals[long_id].view.take_position_handler()

  show_results : (long_id) ->
    ConsiderIt.proposals[long_id].view.show_results_handler()  

  handle_point_details : (long_id, point_id) ->
    ConsiderIt.proposals[long_id].view.show_point_details_handler(point_id)
    
  #event handlers
  events : {}