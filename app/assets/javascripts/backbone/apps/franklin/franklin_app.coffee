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
      @franklin_controller = new Franklin.Root.Controller
        region : App.request "default:region"

      App.vent.trigger 'route:completed', [ ['homepage', '/'] ]

    Consider: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true

      region = App.request "default:region"

      if region.currentView
        App.execute "show:loading", region.currentView,
          region : region
          loading : 
            entities : [proposal]
            #loadingType : 'opacity'

      App.execute 'when:fetched', proposal, ->
        @franklin_controller = new Franklin.Proposal.PositionController
          region : region
          model : proposal

      App.vent.trigger 'route:completed', [ ['homepage', '/'], ["#{proposal.long_id}", Routes.new_position_proposal_path(proposal.long_id)] ]


    Aggregate: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, ->
        @franklin_controller = new Franklin.Proposal.AggregateController
          region : App.request "default:region"
          model : proposal

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["#{proposal.long_id}", Routes.new_position_proposal_path(proposal.long_id)] 
        ["results", Routes.proposal_path(proposal.long_id)]]



    PointDetails: (long_id, point_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, -> 
        region = App.request "default:region"
        if !(region.currentView instanceof Franklin.Proposal.PositionLayout || 
             region.currentView instanceof Franklin.Proposal.AggregateLayout)
          @franklin_controller = new Franklin.Proposal.AggregateController
            region : region
            model : proposal
            transition : false

        point = App.request 'point:get', parseInt(point_id), true
        App.execute 'when:fetched', point, =>
          @franklin_controller.trigger 'point:show_details', point

        crumbs = [ 
          ['homepage', '/'], 
          ["#{proposal.long_id}", Routes.new_position_proposal_path(long_id)]
          ["#{ if point.isPro() then 'Pro' else 'Con'} point", Routes.proposal_point_path(long_id, point_id)] ]

        if region.currentView instanceof Franklin.Proposal.AggregateLayout
          crumbs.splice crumbs.length -1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs

    StaticPosition: (long_id, user_id) ->
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, -> 
        region = App.request "default:region"
        if !(region.currentView instanceof Franklin.Proposal.PositionLayout || 
             region.currentView instanceof Franklin.Proposal.AggregateLayout)
          @franklin_controller = new Franklin.Proposal.AggregateController
            region : region
            model : proposal
            transition : false

        user = App.request 'user', parseInt(user_id)
        position = App.request('positions:get').findWhere {long_id : long_id, user_id : user.id }
        new Franklin.Position.PositionController
          model : position
          region: new Backbone.Marionette.Region
            el: $("body")

        crumbs = [ 
          ['homepage', '/'], 
          ["#{proposal.long_id}", Routes.new_position_proposal_path(long_id)]        
          ["#{user.get('name')}", Routes.proposal_position_path(long_id, position.id)] ]

        if region.currentView instanceof Franklin.Proposal.AggregateLayout
          crumbs.splice crumbs.length -1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs


  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
