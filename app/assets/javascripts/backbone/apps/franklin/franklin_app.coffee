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
      new Franklin.Root.Controller
        region : App.request "default:region"

    Consider: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, ->
        new Franklin.Proposal.PositionController
          region : App.request "default:region"
          model : proposal

    Aggregate: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, ->
        new Franklin.Proposal.AggregateController
          region : App.request "default:region"
          model : proposal

    PointDetails: (long_id, point_id) -> 
      App.vent.trigger 'route:PointDetails', long_id, point_id

    StaticPosition: (long_id, user_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, -> 
        #TODO: check first to see if it already exists
        new Franklin.Proposal.AggregateController
          region : App.request "default:region"
          model : proposal

        position = App.request('positions:get').findWhere {long_id : long_id, user_id : parseInt(user_id) }
        new Franklin.Position.PositionController
          model : position
          region: new Backbone.Marionette.Region
            el: $("body")



  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
