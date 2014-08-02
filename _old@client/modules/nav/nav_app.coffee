@ConsiderIt.module "NavApp", (NavApp, App, Backbone, Marionette, $, _) ->
  
  API =
    current_crumbs : []
    nav_history : []
    last_page : null

    trackHistory : (crumbs) ->
      @current_crumbs = crumbs
      $('.tooltipster-base').hide()

      # update history, making sure that if the current route is already in history, we just splice history to that position
      route = crumbs[crumbs.length - 1][1]
      if route != '/'
        new_history = []
        for [loc,full] in @nav_history
          break if loc == route
          new_history.push [loc,full]
        @nav_history = new_history
        @nav_history.push crumbs[crumbs.length - 1]
      else
        @nav_history = [['homepage','/']]

      @last_page = _.last(@nav_history)[1]

    backByCrumb : ->
      href = if @current_crumbs.length > 1 then @current_crumbs[@current_crumbs.length - 2][1] else '/'
      App.navigate(href, {trigger: true, replace: false})

    backByHistory : ->
      @nav_history.pop()
      if @nav_history.length < 2
        App.navigate(Routes.root_path(), {trigger: true})
      else
        route = @nav_history.pop()[1]
        App.navigate route, {trigger: true}

    historyLength : ->
      @nav_history.length

  App.vent.on 'route:completed', (crumbs) =>
    API.trackHistory crumbs

  App.reqres.setHandler "nav:back:crumb", ->
    API.backByCrumb()

  App.reqres.setHandler "nav:back:history", ->
    API.backByHistory()

  App.reqres.setHandler "nav:history:length", ->
    API.historyLength()