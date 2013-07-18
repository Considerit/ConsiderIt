class ConsiderIt.AppView extends Backbone.View

  el: 'body'
  breadcrumbs_template : _.template($('#tpl_breadcrumbs').html())


  initialize : (options) -> 

    @listenTo ConsiderIt.router, 'user:signin', =>
 
    @listenTo ConsiderIt.router, 'user:signout', => 
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})

    ConsiderIt.router.bind 'all', (route, router) => @route_changed(route, router)

    @history = [ ['homepage', '/'] ]
    @last_page = '/'

    @usermanagerview = new ConsiderIt.UserManagerView({model: ConsiderIt.current_user, el : '#l-wrap'})
    @dashboardview = new ConsiderIt.UserDashboardView({ model : ConsiderIt.current_user, el : '#l-wrap'})
    @proposals_manager = new ConsiderIt.ProposalsManagerView({el : '#l-wrap'}) 

  render : () ->
    @usermanagerview.render()
    @proposals_manager.render()    

    # kick off events for the current path
    #ConsiderIt.router.navigate @last_page, {trigger: true}
    this

  events : 
    'click .l-navigate-back' : 'go_back'

  go_back : ->
    @history.pop()
    if @history.length < 2
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})
    else
      route = @history.pop()[1]
      ConsiderIt.router.navigate(route, {trigger: true})

  go_back_crumb : ->
    href = if @breadcrumbs.length > 1 then @breadcrumbs[@breadcrumbs.length - 2][1] else '/'
    ConsiderIt.router.navigate(href, {trigger: true, replace: false})

  route_changed : (route, router) ->
    return if route == 'route'
    ## wait for endpoint to finish rendering ...

    loc = Backbone.history.fragment.split('?')[0].split('/')
    short = loc[loc.length - 1]
    $('.tooltipster-base').hide()
    
    if short 
      new_crumbs = []
      for [loc,full] in @history
        break if loc == short
        new_crumbs.push [loc,full]
      @history = new_crumbs
      @history.push [short, "/#{Backbone.history.fragment.split('?')[0]}"]
    else
      @history = [['homepage','/']]
    
    $back = $('.l-navigate')

    if @history.length == 1 && $back.is(':visible')
      $("[data-domain='homepage']:hidden").show()

      $back.hide()
    else if @history.length > 1
      @breadcrumbs = [['homepage', '/']]
      path = ''
      for loc in @history[@history.length-1][1].split('/')
        continue if loc.length == 0
        path = "#{path}/#{loc}"
        @breadcrumbs.push [loc.split('?')[0], path] if ConsiderIt.router.valid_endpoint(path)

      ######################
      #### HACK: if static position or point details, need to insert "results" into breadcrumbs if loaded from results page
      if _.contains(['route:PointDetails', 'route:StaticPosition'], route) && ($('.m-position:visible').length == 0)
        @breadcrumbs.splice(@breadcrumbs.length - 1, 0, ['results', "#{@breadcrumbs[@breadcrumbs.length - 2][1]}/results"])
      ######

      $("[data-domain='homepage']:visible").hide()

      $(document).scrollTop(0) if @last_page == '/' && !_.contains(['route:PointDetails', 'route:StaticPosition'], route)
        

      $back.find('.l-navigate-breadcrumbs').html @breadcrumbs_template({crumbs: @breadcrumbs})
      $back.show()

    @last_page = _.last(@history)[1]
    # console.log route
    # console.log router
    # console.log @history
    #console.log @breadcrumbs
