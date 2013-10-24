@ConsiderIt.module "Franklin", (Franklin, App, Backbone, Marionette, $, _) ->

  class Franklin.Router extends Marionette.AppRouter
    appRoutes : 
      "" : "Root"      
      ":proposal": "Consider"
      ":proposal/results": "Aggregate"
      ":proposal/points/:point" : "PointDetails"
      ":proposal/positions/:user_id" : "StaticPosition"


  API =
    Root: -> 
      region = App.request "default:region"
      App.request "sticky_footer:close"

      if @franklin_controller && (region.controlled_by != @franklin_controller || !(@franklin_controller instanceof Franklin.Root.RootController))
        @franklin_controller.close()
        @franklin_controller = null

      @franklin_controller = new Franklin.Root.RootController
        region : region

      region.controlled_by = @franklin_controller      

      App.vent.trigger 'route:completed', [ ['homepage', '/'] ]
      App.request 'meta:change:default'

    Consider: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true

      # @_loading [proposal]

      from_root = @franklin_controller instanceof Franklin.Root.RootController

      try
        proposal_controller = App.request "proposal_controller:#{proposal.id}"
      catch

      if from_root
        $pel = $(proposal_controller.region.el)
        @franklin_controller.region.hideAllExcept $pel

      App.execute 'when:fetched', proposal, =>
        region = App.request 'default:region'

        proposal_controller.upRoot() if from_root && proposal_controller 

        if @franklin_controller && @franklin_controller != proposal_controller
          @franklin_controller.close()
          @franklin_controller = null

        #$(document).scrollTop(0)
        @franklin_controller = proposal_controller || new Franklin.Proposal.ProposalController
          region : region
          model : proposal
          proposal_state : Franklin.Proposal.State.expanded.crafting
        
        if proposal_controller
          proposal_controller.plant region if from_root
          proposal_controller.changeState Franklin.Proposal.State.expanded.crafting

        region.controlled_by = @franklin_controller

        App.vent.trigger 'route:completed', [ ['homepage', '/'], ["#{proposal.title(40)}", Routes.new_position_proposal_path(proposal.long_id)] ]
        App.vent.trigger 'navigated_to_base'
        App.request 'meta:set', proposal.getMeta() 

    Aggregate: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true

      # @_loading [proposal]

      from_root = @franklin_controller instanceof Franklin.Root.RootController

      try
        proposal_controller = App.request "proposal_controller:#{proposal.id}"
      catch

      if from_root
        $pel = $(proposal_controller.region.el)
        @franklin_controller.region.hideAllExcept $pel

      App.execute 'when:fetched', proposal, =>
        region = App.request 'default:region'

        proposal_controller.upRoot() if from_root && proposal_controller

        if @franklin_controller && @franklin_controller != proposal_controller
          @franklin_controller.close()
          @franklin_controller = null

        #$(document).scrollTop(0)

        @franklin_controller = proposal_controller || new Franklin.Proposal.ProposalController
          region : App.request "default:region"
          model : proposal
          proposal_state : Franklin.Proposal.State.expanded.results            
          #move_to_results : !from_root

        if proposal_controller
          proposal_controller.plant region if from_root
          proposal_controller.changeState Franklin.Proposal.State.expanded.results

        region.controlled_by = @franklin_controller


        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["#{proposal.title(40)}", Routes.new_position_proposal_path(proposal.long_id)] 
          ["results", Routes.proposal_path(proposal.long_id)]]

        App.vent.trigger 'navigated_to_base'
        App.request 'meta:set', proposal.getMeta()



    PointDetails: (long_id, point_id) -> 

      proposal = App.request 'proposal:get', long_id, true
      point = App.request 'point:get', parseInt(point_id), true, long_id

      App.execute 'when:fetched', [proposal, point], => 
        region = App.request "default:region"
        if !(region.currentView instanceof Franklin.Proposal.PositionLayout || 
             region.currentView instanceof Franklin.Proposal.AggregateLayout)
          @franklin_controller.close() if @franklin_controller
          @franklin_controller = new Franklin.Proposal.ProposalController
            region : region
            model : proposal
            proposal_state : Franklin.Proposal.State.expanded.results                        
          region.controlled_by = @franklin_controller


        @franklin_controller.trigger 'point:show_details', point

        crumbs = [ 
          ['homepage', '/'], 
          ["#{proposal.long_id}", Routes.new_position_proposal_path(long_id)]
          ["#{ if point.isPro() then 'Pro' else 'Con'} point", Routes.proposal_point_path(long_id, point_id)] ]

        if region.currentView instanceof Franklin.Proposal.AggregateLayout
          crumbs.splice crumbs.length - 1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs
        App.request 'meta:change:default'

    StaticPosition: (long_id, user_id) ->
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, => 
        region = App.request "default:region"        
        if !(region.currentView instanceof Franklin.Proposal.PositionLayout || 
             region.currentView instanceof Franklin.Proposal.AggregateLayout)
          @franklin_controller.close() if @franklin_controller
          @franklin_controller = new Franklin.Proposal.ProposalController
            region : region
            model : proposal
            proposal_state : Franklin.Proposal.State.expanded.results                        
          region.controlled_by = @franklin_controller

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
          crumbs.splice crumbs.length - 1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs
        App.request 'meta:change:default'

    _loading : (entities, region) ->
      region ?= App.request 'default:region'
      if region.currentView
        App.execute "show:loading",
          loading : 
            entities : entities




  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
