class ConsiderIt.AppView extends Backbone.View

  el: '#wrap'
  #@itemView : ConsiderIt.ProposalView

  initialize : (options) -> 

    @proposals = new ConsiderIt.ProposalList()
    @proposals.reset( _.pluck(_.values(ConsiderIt.proposals), 'model'))

    @proposalsview = new ConsiderIt.ProposalListView({collection : @proposals, el : '#proposals'})
    
    @usermanagerview = new ConsiderIt.UserManagerView({model: ConsiderIt.current_user, el : '#wrap'})

    ConsiderIt.router.on 'route:Consider', @show_position
    ConsiderIt.router.on 'route:Aggregate', @show_results

    #handle here because of dependency on proposal being loaded first
    ConsiderIt.router.on 'route:PointDetails', @handle_point_details

    @listenTo this, 'user:signin', @load_anonymous_data

  render : () -> 
    @proposalsview.renderAllItems()
    @usermanagerview.render()

    this

  #route handlers
  show_position : (long_id, params) ->
    ConsiderIt.proposals[long_id].view.take_position_handler()

  show_results : (long_id, params) ->
    ConsiderIt.proposals[long_id].view.show_results_handler()  

  handle_point_details : (long_id, point_id, params) ->
    ConsiderIt.proposals[long_id].view.show_point_details_handler(point_id)

  # After a user signs in, we're going to query the server and get all the points
  # that this user wrote *anonymously*. Then we'll update the data properly so
  # that the user can update them.
  load_anonymous_data : ->
    $.get Routes.points_for_user_path(), (data) =>
      _.each data, (pnt) =>
        [id, long_id, is_pro] = [pnt.point.id, pnt.point.long_id, pnt.point.is_pro]
        if ConsiderIt.proposals[long_id].view && ConsiderIt.proposals[long_id].view.data_loaded
          points = if is_pro then ConsiderIt.proposals[long_id].points.pros else ConsiderIt.proposals[long_id].points.cons
          _.each points, (pm) =>
            pm.set('user_id', ConsiderIt.current_user.id) if pm.id == id
      

