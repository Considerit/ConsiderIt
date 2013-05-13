class ConsiderIt.AppView extends Backbone.View

  el: '#l-wrap'

  initialize : (options) -> 

    #handle here because of dependency on proposal being loaded first

    @listenTo this, 'user:signin', =>
      @load_anonymous_data
      @render()
          
    @listenTo this, 'user:signout', => @render()

    @proposals = new ConsiderIt.ProposalList()
    @proposals.reset _.values(ConsiderIt.proposals)      

  render : () -> 

    @proposalsview = new ConsiderIt.ProposalListView({collection : @proposals, el : '#m-proposals-container'}) if !@proposalview?
    @usermanagerview = new ConsiderIt.UserManagerView({model: ConsiderIt.current_user, el : '#l-wrap'}) if !@usermanagerview?
    @dashboardview = new ConsiderIt.UserDashboardView({ model : ConsiderIt.current_user, el : '#l-wrap'}) if !@dashboardview?

    @proposalsview.renderAllItems()
    @usermanagerview.render()

    this

  # After a user signs in, we're going to query the server and get all the points
  # that this user wrote *anonymously*. Then we'll update the data properly so
  # that the user can update them.
  load_anonymous_data : ->
    $.get Routes.points_for_user_path(), (data) =>
      for pnt in data
        [id, long_id, is_pro] = [pnt.point.id, pnt.point.long_id, pnt.point.is_pro]
        proposal = @proposals.findWhere( {long_id : long_id} )
        proposal.update_anonymous_point(id, is_pro) if proposal && proposal.data_loaded

