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
      crumbs = [ ['homepage', '/'] ]

      App.vent.trigger 'route:started', crumbs

      region = App.request "default:region"

      return if @franklin_controller && @franklin_controller instanceof Franklin.Root.RootController && region.controlled_by == @franklin_controller

      App.request "sticky_footer:close"

      last_proposal_id = null
      if @franklin_controller && (region.controlled_by != @franklin_controller || !(@franklin_controller instanceof Franklin.Root.RootController))
        if @franklin_controller instanceof Franklin.Proposal.ProposalController
          last_proposal_id = @franklin_controller.model.id

        @franklin_controller.close()
        @franklin_controller = null

      @franklin_controller = new Franklin.Root.RootController
        region : region
        last_proposal_id : last_proposal_id

      region.controlled_by = @franklin_controller      

      App.vent.trigger 'route:completed', crumbs
      App.request 'meta:change:default'


    _transitionProposal: (proposal, new_state, crumbs) ->
      $description_animation_time = 500
      App.vent.trigger 'route:started', crumbs

      region = App.request 'default:region'

      from_root = @franklin_controller instanceof Franklin.Root.RootController && region.controlled_by == @franklin_controller && proposal.get('published') 

      if proposal.get('published')
        try
          proposal_controller = App.request "proposal_controller:#{proposal.id}"
        catch

      use_existing_proposal_controller = from_root && proposal_controller && proposal_controller.region

      if use_existing_proposal_controller
        #remove surrounding elements, while suspending proposal el and moving it gracefully to top
        $pel = $(proposal_controller.region.el)
        $pel_offset = $pel.position()
        $pel.css
          top : $pel_offset.top - $(document).scrollTop()
          minHeight : 2000

        @franklin_controller.region.hideAllExcept $pel
        $pel.addClass('transitioning')

        $pel.animate
          top : 0
        , $description_animation_time, =>
          _.delay ->
            $pel.attr 'style', ''
          , 2500
        start = new Date().getTime()

        proposal_controller.showDescription new_state

      App.execute 'when:fetched', proposal, =>

        transition = =>
          if use_existing_proposal_controller
            proposal_controller.upRoot() 

          if @franklin_controller && @franklin_controller != proposal_controller
            @franklin_controller.close()
            @franklin_controller = null

          if @franklin_controller && (@franklin_controller == proposal_controller && region.controlled_by == @franklin_controller) || use_existing_proposal_controller
            proposal_controller.plant region if from_root
            proposal_controller.changeState new_state
          else
            proposal_controller = new Franklin.Proposal.ProposalController
              region : region
              model : proposal
              proposal_state : new_state   

          @franklin_controller = region.controlled_by = proposal_controller  

          $pel.removeClass('transitioning') if $pel

          App.vent.trigger 'route:completed', crumbs
          
          App.vent.trigger 'points:unexpand'
          App.request 'meta:set', proposal.getMeta() 

        if use_existing_proposal_controller
          remaining = $description_animation_time - (new Date().getTime() - start)
          if remaining > 0
            _.delay transition, remaining
          else
            transition()
        else
          transition()

    Consider: (long_id) -> 
      return if ConsiderIt.inaccessible_proposal != null      
      proposal = App.request 'proposal:get', long_id, true
      @_transitionProposal proposal, Franklin.Proposal.State.expanded.crafting, [ ['homepage', '/'], ["#{proposal.title(40)}", Routes.new_position_proposal_path(proposal.id)] ]

    Aggregate: (long_id) -> 
      return if ConsiderIt.inaccessible_proposal != null      
      proposal = App.request 'proposal:get', long_id, true
      @_transitionProposal proposal, Franklin.Proposal.State.expanded.results, [ 
          ['homepage', '/'], 
          ["#{proposal.title(40)}", Routes.new_position_proposal_path(proposal.id)] 
          ["results", Routes.proposal_path(proposal.id)]]

    PointDetails: (long_id, point_id) -> 
      return if ConsiderIt.inaccessible_proposal != null      

      App.vent.trigger 'route:started', null

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
          ["#{proposal.id}", Routes.new_position_proposal_path(long_id)]
          ["#{ if point.isPro() then 'Pro' else 'Con'} point", Routes.proposal_point_path(long_id, point_id)] ]

        if @franklin_controller instanceof Franklin.Proposal.ProposalController && @franklin_controller.state == Franklin.Proposal.State.expanded.results
          crumbs.splice crumbs.length - 1, 0, ['results', Routes.proposal_path(long_id)]

        App.vent.trigger 'route:completed', crumbs
        App.request 'meta:change:default'

    StaticPosition: (long_id, user_id) ->
      return if ConsiderIt.inaccessible_proposal != null      

      App.vent.trigger 'route:started', null

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
          ["#{proposal.id}", Routes.new_position_proposal_path(long_id)],      
          ["results", Routes.proposal_path(long_id)],          
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
