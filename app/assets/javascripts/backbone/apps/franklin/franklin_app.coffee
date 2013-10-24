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


    _transitionProposal: (proposal, new_state, crumbs) ->
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

        if proposal_controller
          proposal_controller.plant region if from_root
          proposal_controller.changeState new_state
        else
          proposal_controller = new Franklin.Proposal.ProposalController
            region : region
            model : proposal
            proposal_state : new_state   

        @franklin_controller = region.controlled_by = proposal_controller  

        App.vent.trigger 'route:completed', crumbs
        
        App.vent.trigger 'navigated_to_base'
        App.request 'meta:set', proposal.getMeta() 


    Consider: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      @_transitionProposal proposal, Franklin.Proposal.State.expanded.crafting, [ ['homepage', '/'], ["#{proposal.title(40)}", Routes.new_position_proposal_path(proposal.long_id)] ]

    Aggregate: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true
      @_transitionProposal proposal, Franklin.Proposal.State.expanded.results, [ 
          ['homepage', '/'], 
          ["#{proposal.title(40)}", Routes.new_position_proposal_path(proposal.long_id)] 
          ["results", Routes.proposal_path(proposal.long_id)]]

    PointDetails: (long_id, point_id) -> 

      proposal = App.request 'proposal:get', long_id, true
      point = App.request 'point:get', parseInt(point_id), true, long_id


      try
        proposal_controller = App.request "proposal_controller:#{proposal.id}"
      catch

      from_root = @franklin_controller instanceof Franklin.Root.RootController

      if from_root
        $pel = $(proposal_controller.region.el)
        @franklin_controller.region.hideAllExcept $pel


      App.execute 'when:fetched', [proposal, point], => 
        region = App.request "default:region"
        if !(@franklin_controller instanceof Franklin.Proposal.ProposalController && @franklin_controller.model.id == proposal.id)

          proposal_controller.upRoot() if from_root && proposal_controller 

          if @franklin_controller && @franklin_controller != proposal_controller
            @franklin_controller.close()
            @franklin_controller = null

          if proposal_controller
            proposal_controller.plant region if from_root
            proposal_controller.changeState Franklin.Proposal.State.expanded.results
          else
            proposal_controller = new Franklin.Proposal.ProposalController
              region : region
              model : proposal
              proposal_state : Franklin.Proposal.State.expanded.results   

          @franklin_controller = region.controlled_by = proposal_controller  

        @franklin_controller.trigger 'point:show_details', point

        crumbs = [ 
          ['homepage', '/'], 
          ["#{proposal.long_id}", Routes.new_position_proposal_path(long_id)]
          ["#{ if point.isPro() then 'Pro' else 'Con'} point", Routes.proposal_point_path(long_id, point_id)] ]

        if @franklin_controller instanceof Franklin.Proposal.ProposalController && @franklin_controller.state == Franklin.Proposal.State.expanded.results
          crumbs.splice crumbs.length - 1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs
        App.request 'meta:change:default'

    StaticPosition: (long_id, user_id) ->
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, => 
        region = App.request "default:region"        
        if !(@franklin_controller instanceof Franklin.Proposal.ProposalController && @franklin_controller.model.id == proposal.id)
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
