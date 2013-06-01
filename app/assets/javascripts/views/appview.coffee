class ConsiderIt.AppView extends Backbone.View

  el: '#l-wrap'

  initialize : (options) -> 

    #handle here because of dependency on proposal being loaded first

    @on 'user:signin', =>
      @load_anonymous_data
      @render()
          
    @on 'user:signout', => 
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
      @render()

    ConsiderIt.router.bind 'all', (route, router) => @route_changed(route, router)

    @proposals = new ConsiderIt.ProposalList()
    @proposals.reset _.values(ConsiderIt.proposals)      

    @crumbs = ['home']

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

  events : 
    'click .l-navigate-back' : 'go_back'

  go_back : ->
    window.history.go(-1)

  route_changed : (route, router) ->
    return if route == 'route'
    console.log("Different Page: " + route)
    loc = Backbone.history.fragment.split('/')
    short = loc[loc.length - 1]
    
    if short 
      if short in @crumbs
        new_crumbs = []
        for loc in @crumbs
          break if loc == short
          new_crumbs.push loc
        @crumbs = new_crumbs
      @crumbs.push short
    else
      @crumbs = ['home']
    
    $back = $('.l-navigate-back')
    if @crumbs.length == 1 && $back.is(':visible')
      $back.hide()
    else if @crumbs.length > 1 && $back.is(':hidden')
      $back.show()

    console.log @crumbs
