@ConsiderIt.module "Franklin", (Franklin, App, Backbone, Marionette, $, _) ->

  class Franklin.Router extends Marionette.AppRouter
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
      @homepage_controller = new Franklin.Root.Controller
        region : App.request "default:region"

    Consider: (long_id) -> 
      App.vent.trigger 'route:Consider', long_id

    Aggregate: (long_id) -> 
      App.vent.trigger 'route:Aggregate', long_id

    PointDetails: (long_id, point_id) -> 
      App.vent.trigger 'route:PointDetails', long_id, point_id

    StaticPosition: (long_id, user_id) -> 
      App.vent.trigger 'route:StaticPosition', long_id, user_id

  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
