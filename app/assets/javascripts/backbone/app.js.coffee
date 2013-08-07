@ConsiderIt = do (Backbone, Marionette) ->
  
  App = new Marionette.Application

  App.on "initialize:before", (options) ->
    App.environment = options.environment
  
  App.addRegions
    headerRegion: "#l-header"
    mainRegion:    "#l-content-main-wrap"
    footerRegion: "#l-footer"
  
  App.rootRoute = Routes.root_path()
  
  App.addInitializer ->
    headerApp = App.module("HeaderApp")

    @listenTo headerApp, 'start', => 
      App.module("Auth").start()

    headerApp.start()
    App.module("FooterApp").start()

  
  App.reqres.setHandler "default:region", ->
    App.mainRegion
  
  App.reqres.setHandler "tenant:get", ->
    ConsiderIt.current_tenant

  App.reqres.setHandler "tenant:update", (data) ->
    ConsiderIt.current_tenant.set data
    App.vent.trigger "tenant:updated"

  App.commands.setHandler "register:instance", (instance, id) ->
    App.register instance, id if App.environment is "development"
  
  App.commands.setHandler "unregister:instance", (instance, id) ->
    App.unregister instance, id if App.environment is "development"
  
  App.on "initialize:after", ->
    
    #TODO: don't remove this until everything loaded
    $('#l-preloader').hide()

    # REFACTOR
    # ConsiderIt.router = new ConsiderIt.Router();

    appview = new ConsiderIt.AppView()
    #@mainRegion.show appview

    #@dashboardview = new ConsiderIt.UserDashView({ model : ConsiderIt.request('user:current'), el : '#l-wrap'})

    #appview.render()

    #####
    
    ConsiderIt.all_proposals = new ConsiderIt.ProposalList()
    ConsiderIt.all_proposals.add_proposals ConsiderIt.proposals
    if ConsiderIt.current_proposal
      ConsiderIt.all_proposals.add_proposal(ConsiderIt.current_proposal.data) 
      ConsiderIt.current_proposal = null


    @startHistory()
    @navigate(@rootRoute, trigger: true) unless @getCurrentRoute()

  ######
  ## TODO: distribute!
  class Router extends Marionette.AppRouter

    appRoutes : 
      "" : "Root"      
      ":proposal": "Consider"
      ":proposal/results": "Aggregate"
      ":proposal/points/:point" : "PointDetails"
      ":proposal/positions/:user_id" : "StaticPosition"

    # TODO: distribute this to each module with valid routes
    valid_endpoint : (path) ->
      parts = path.split('/')
      return true if parts.length == 1
      if parts[1] == 'dashboard'
        return _.contains(['profile', 'edit', 'account', 'application', 'proposals', 'roles', 'notifications', 'analytics', 'data', 'moderate', 'assessment'], parts[parts.length-1])  

      else
        return !_.contains(['positions', 'points'], parts[parts.length-1])
  
  API =
    Root: -> 
      App.vent.trigger 'route:Root'

    Consider: (long_id) -> 
      App.vent.trigger 'route:Consider', long_id

    Aggregate: (long_id) -> 
      App.vent.trigger 'route:Aggregate', long_id

    PointDetails: (long_id, point_id) -> 
      App.vent.trigger 'route:PointDetails', long_id, point_id

    StaticPosition: (long_id, user_id) -> 
      App.vent.trigger 'route:StaticPosition', long_id, user_id

  
  App.addInitializer ->
    @router = new Router
      controller: API


  App