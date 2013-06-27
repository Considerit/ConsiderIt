class ConsiderIt.AppView extends Backbone.View

  el: 'body'
  breadcrumbs_template : _.template($('#tpl_breadcrumbs').html())


  initialize : (options) -> 

    #handle here because of dependency on proposal being loaded first

    @on 'user:signin', =>

      @load_anonymous_data()
      @render()
      if ConsiderIt.inaccessible_proposal
        ConsiderIt.router.navigate(Routes.proposal_path(ConsiderIt.inaccessible_proposal.long_id), {trigger: true})
        ConsiderIt.inaccessible_proposal = null

          
    @on 'user:signout', => 
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
      @proposals.purge_inaccessible()
      @render()

    ConsiderIt.router.bind 'all', (route, router) => @route_changed(route, router)

    @proposals = new ConsiderIt.ProposalList()
    @proposals.add_proposals ConsiderIt.proposals

    @crumbs = [ ['homepage', '/'] ]

  render : () -> 
    if ConsiderIt.current_proposal
      @proposals.add_proposal(ConsiderIt.current_proposal.data) 
      ConsiderIt.current_proposal = null

    @proposalsview = new ConsiderIt.ProposalListView({collection : @proposals, el : '#m-proposals-container'}) if !@proposalsview?
    @usermanagerview = new ConsiderIt.UserManagerView({model: ConsiderIt.current_user, el : '#l-wrap'}) if !@usermanagerview?
    @dashboardview = new ConsiderIt.UserDashboardView({ model : ConsiderIt.current_user, el : '#l-wrap'}) if !@dashboardview?

    @proposalsview.renderAllItems()
    @usermanagerview.render()

    if ConsiderIt.inaccessible_proposal
      if ConsiderIt.limited_user
        @$('[data-target="login"]:first').trigger('click')
      else if ConsiderIt.limited_user_email
        @$('[data-target="create_account"]:first').trigger('click')


    this

  # After a user signs in, we're going to query the server and get all the points
  # that this user wrote *anonymously* and proposals they have access to. Then we'll update the data properly so
  # that the user can update them.
  load_anonymous_data : ->
    $.get Routes.content_for_user_path(), (data) =>
      for proposal in data.proposals
        @proposals.add_proposals (p for p in data.proposals)

      for pnt in data.points
        [id, long_id, is_pro] = [pnt.point.id, pnt.point.long_id, pnt.point.is_pro]
        proposal = @proposals.findWhere( {long_id : long_id} )
        proposal.update_anonymous_point(id, is_pro) if proposal && proposal.data_loaded

  events : 
    'click .l-navigate-back' : 'go_back'
    'click [data-target="user_profile_page"]' : 'view_user_profile'

  # handles user profile access for anyone throughout the app  
  view_user_profile : (ev) ->
    #$('body').animate {scrollTop: 0 }, 500
    ConsiderIt.router.navigate(Routes.profile_path($(ev.currentTarget).data('id')), {trigger: true})

  go_back : ->
    if @crumbs.length < 3
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    else
      window.history.go(-1)

  go_back_crumb : ->
    href = if @breadcrumbs.length > 1 then @breadcrumbs[@breadcrumbs.length - 2][1] else '/'
    ConsiderIt.router.navigate(href, {trigger: true})

  route_changed : (route, router) ->
    return if route == 'route'
    loc = Backbone.history.fragment.split('?')[0].split('/')
    short = loc[loc.length - 1]
    $('.tooltipster-base').hide()
    
    if short 
      new_crumbs = []
      for [loc,full] in @crumbs
        break if loc == short
        new_crumbs.push [loc,full]
      @crumbs = new_crumbs
      @crumbs.push [short, "/#{Backbone.history.fragment.split('?')[0]}"]
    else
      @crumbs = [['homepage','/']]
    
    $back = $('.l-navigate')

    if @crumbs.length == 1 && $back.is(':visible')
      $back.hide()
    else if @crumbs.length > 1
      @breadcrumbs = [['homepage', '/']]
      path = ''
      for loc in @crumbs[@crumbs.length-1][1].split('/')
        continue if loc.length == 0
        path = "#{path}/#{loc}"
        @breadcrumbs.push [loc.split('?')[0], path] if ConsiderIt.router.valid_endpoint(path)

      $back.find('.l-navigate-breadcrumbs').html @breadcrumbs_template({crumbs: @breadcrumbs})
      $back.show()

