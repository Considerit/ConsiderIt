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

      if @franklin_controller && region.controlled_by != @franklin_controller
        @franklin_controller.close()

      @franklin_controller = new Franklin.Root.Controller
        region : region

      region.controlled_by = @franklin_controller


      App.vent.trigger 'route:completed', [ ['homepage', '/'] ]

    Consider: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true

      # @_loading [proposal]

      App.execute 'when:fetched', proposal, =>
        region = App.request 'default:region'

        if @franklin_controller && region.controlled_by != @franklin_controller
          @franklin_controller.close()
          @franklin_controller = null

        already_viewing = @franklin_controller && @franklin_controller.options.model == proposal && @franklin_controller instanceof Franklin.Proposal.PositionController
        if !already_viewing
          @franklin_controller.close() if @franklin_controller
          $(document).scrollTop(0)
          @franklin_controller = new Franklin.Proposal.PositionController
            region : region
            model : proposal
          region.controlled_by = @franklin_controller

        App.vent.trigger 'route:completed', [ ['homepage', '/'], ["#{proposal.long_id}", Routes.new_position_proposal_path(proposal.long_id)] ]
        App.vent.trigger 'navigated_to_base'


    Aggregate: (long_id) -> 
      proposal = App.request 'proposal:get', long_id, true

      # @_loading [proposal]

      App.execute 'when:fetched', proposal, =>
        region = App.request 'default:region'

        if @franklin_controller && region.controlled_by != @franklin_controller
          @franklin_controller.close()
          @franklin_controller = null

        already_viewing = @franklin_controller && @franklin_controller.options.model == proposal && @franklin_controller instanceof Franklin.Proposal.AggregateController

        if !already_viewing    
          $(document).scrollTop(0)
          @franklin_controller.close() if @franklin_controller

          @franklin_controller = new Franklin.Proposal.AggregateController
            region : App.request "default:region"
            model : proposal
            move_to_results : true
          region.controlled_by = @franklin_controller

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["#{proposal.long_id}", Routes.new_position_proposal_path(proposal.long_id)] 
          ["results", Routes.proposal_path(proposal.long_id)]]

        App.vent.trigger 'navigated_to_base'



    PointDetails: (long_id, point_id) -> 

      proposal = App.request 'proposal:get', long_id, true
      point = App.request 'point:get', parseInt(point_id), true, long_id

      App.execute 'when:fetched', [proposal, point], => 
        region = App.request "default:region"
        if !(region.currentView instanceof Franklin.Proposal.PositionLayout || 
             region.currentView instanceof Franklin.Proposal.AggregateLayout)
          @franklin_controller.close() if @franklin_controller
          @franklin_controller = new Franklin.Proposal.AggregateController
            region : region
            model : proposal
            transition : false
          region.controlled_by = @franklin_controller


        @franklin_controller.trigger 'point:show_details', point

        crumbs = [ 
          ['homepage', '/'], 
          ["#{proposal.long_id}", Routes.new_position_proposal_path(long_id)]
          ["#{ if point.isPro() then 'Pro' else 'Con'} point", Routes.proposal_point_path(long_id, point_id)] ]

        if region.currentView instanceof Franklin.Proposal.AggregateLayout
          crumbs.splice crumbs.length - 1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs

    StaticPosition: (long_id, user_id) ->
      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, => 
        region = App.request "default:region"        
        if !(region.currentView instanceof Franklin.Proposal.PositionLayout || 
             region.currentView instanceof Franklin.Proposal.AggregateLayout)
          @franklin_controller.close() if @franklin_controller
          @franklin_controller = new Franklin.Proposal.AggregateController
            region : region
            model : proposal
            transition : false
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

    _loading : (entities, region) ->
      region ?= App.request 'default:region'
      if region.currentView
        App.execute "show:loading",
          #view : region.currentView
          #region : region
          loading : 
            entities : entities
            #loadingType : 'opacity'




  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
