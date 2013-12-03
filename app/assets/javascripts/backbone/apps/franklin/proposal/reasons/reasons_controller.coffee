@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  class Proposal.ReasonsController extends App.Controllers.StatefulController
    transitions_enabled : true

    # maps from parent state to this controller's state
    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.ReasonsState.collapsed
      map[Proposal.State.expanded.crafting] = Proposal.ReasonsState.separated
      map[Proposal.State.expanded.results] = Proposal.ReasonsState.together
      map


    initialize : (options = {}) ->
      super options

      @model = options.model

      @listenTo @options.parent_controller, 'point:show_details', (point) =>
        @trigger 'point:show_details', point

      @layout = @getLayout()
      @setupLayout @layout

      @region.show @layout

    # transition or reset views as appropriate after state has been updated
    processStateChange : ->
      participants_view = @getParticipantsView()
      @layout.participantsRegion.show participants_view

      footer_view = @getResultsFooterView()
      @layout.footerRegion.show footer_view if footer_view

      wait = if @crafting_controller && @prior_state != null then @transition_speed() else 0
      _.delayIfWait =>
        @updatePeerPoints @layout

        if !@crafting_controller #&& @options.model.fetched && @state != Proposal.ReasonsState.collapsed
          @crafting_controller = @getCraftingController @layout.positionRegion
          @setupCraftingController @crafting_controller 

      , wait

      if @layout.$el.is('.transitioning')
        @layout.sizeToFit 10
        # @layout.sizeToFit @transition_speed() / 2
        # @layout.sizeToFit @transition_speed()
        # @layout.sizeToFit @transition_speed() + 10
        @layout.sizeToFit @transition_speed() + 100

      else
        @layout.sizeToFit()

    setupLayout : (layout) ->

      @listenTo layout, 'show', =>
        @listenTo layout, 'point:viewed', (point_id) =>
          position = @model.getUserPosition()
          position.addViewedPoint point_id if position

        @listenTo layout, 'show_results', =>
          if @state == Proposal.ReasonsState.collapsed
            App.navigate Routes.proposal_path(@model.id), {trigger: true}

        @processStateChange()

    updatePeerPoints : (layout) ->

      if @peer_pros_controller && @peer_cons_controller
        all_points = App.request 'points:get:proposal', @model.id
        @peer_pros_controller.options.collection.fullCollection.add all_points.filter((point) -> point.isPro()) 
        @peer_cons_controller.options.collection.fullCollection.add all_points.filter((point) -> !point.isPro())


        _.each [@peer_pros_controller, @peer_cons_controller], (controller) =>
          collection = controller.options.collection
          switch @state 
            when Proposal.ReasonsState.separated
              included_points = @model.getUserPosition().getIncludedPoints()              
              collection.fullCollection.remove (App.request('point:get', i) for i in included_points)
              collection.setPageSize 4
              controller.sortPoints 'persuasiveness'


            when Proposal.ReasonsState.collapsed
              top_points = [@model.get('top_pro'), @model.get('top_con')]
              collection.fullCollection.set top_points

              collection.setPageSize 1

            when Proposal.ReasonsState.together
              collection.setPageSize 4
              controller.sortPoints 'score'

      else
        points = switch @state 
          when Proposal.ReasonsState.collapsed
            page_size = 1
            App.request 'points:get:proposal:top', @model.id
          when Proposal.ReasonsState.separated
            included_points = @model.getUserPosition().getIncludedPoints()
            all_points = App.request 'points:get:proposal', @model.id
            page_size = 4
            new App.Entities.Points all_points.filter (point) -> !(point.id in included_points)
          else
            page_size = 4
            App.request 'points:get:proposal', @model.id

        aggregated_pros = new App.Entities.PaginatedPoints points.filter((point) -> point.isPro()), {state: {pageSize:page_size} }
        aggregated_cons = new App.Entities.PaginatedPoints points.filter((point) -> !point.isPro()), {state: {pageSize:page_size} }


        @peer_pros_controller = @getPointsController layout.peerProsRegion, 'pro', aggregated_pros
        @peer_cons_controller = @getPointsController layout.peerConsRegion, 'con', aggregated_cons

        _.each [ [@peer_pros_controller, @peer_cons_controller], [@peer_cons_controller, @peer_pros_controller]], (item) =>
          [controller, other_controller] = item
          @listenTo controller, 'point:showed_details', (point) =>
            @layout.pointExpanded controller.region

            @listenToOnce controller, 'details:closed', (point) =>
              @layout.pointClosed controller.region

          @listenTo controller, 'points:browsing', (valence) =>

            if other_controller.current_browse_state
              other_controller.toggleBrowsing other_controller.current_browse_state

            @layout.pointsBrowsing valence

            @listenToOnce controller, 'points:browsing:off', (valence) =>
              @layout.pointsBrowsingOff valence


        @setupPointsController @peer_pros_controller
        @setupPointsController @peer_cons_controller

    segmentPeerPoints : (segment) ->
      # @layout.reasonsHeaderRegion.show @getHeaderView(segment)

      _.each [@peer_pros_controller, @peer_cons_controller], (controller, idx) =>
        controller.segmentPeerPoints segment

      @layout.sizeToFit()

    includePoint : (model) ->
      position = @model.getUserPosition()
      position.includePoint model

      source_controller = if model.isPro() then @peer_pros_controller else @peer_cons_controller
      source = source_controller.options.collection
      source.remove model

      @crafting_controller.handleIncludePoint model

      params =
        proposal_id : @model.id
        point_id : model.id
      
      window.addCSRF params
      $.post Routes.inclusions_path(), 
        params, (data) =>
          current_user = App.request 'user:current'
          current_user.setFollowing 
            followable_type : 'Point'
            followable_id : model.id
            follow : true
            explicit: false      

    setupCraftingController : (controller) ->
      @listenTo controller, 'point:removal', (model) =>
        controller = if model.isPro() then @peer_pros_controller else @peer_cons_controller
        controller.options.collection.add model
        @trigger 'point:removal', model.id

      @listenTo controller, 'point:showed_details', (point) =>
        @layout.pointExpanded @layout.positionRegion
        @listenToOnce controller, 'details:closed', (point) => 
          @layout.pointClosed @layout.positionRegion

      # After signing in, the existing user may have a preexisting position. We need
      # to refresh the points shown in the margins if that preexisting position had included points.
      # Similarily after a user signs out, the points in their list should be returned to peer points.
      @listenTo controller, 'signin:position_changed', =>
        if @state == Proposal.ReasonsState.separated
          @updatePeerPoints @layout

      @listenTo controller, 'position:published', =>
        @trigger 'position:published'


      @listenTo controller, 'point:include', (model) =>
        @includePoint model


    setupPointsController : (controller) ->
      @listenTo controller, 'point:highlight_includers', (view) =>
        if @state == Proposal.ReasonsState.together
          # don't highlight users on point mouseover unless the histogram is fully visible
          includers = view.model.getIncluders() || []
          includers.push view.model.get('user_id')
          @trigger 'point:highlight_includers', includers 

      @listenTo controller, 'point:unhighlight_includers', (view) =>
        if @state == Proposal.ReasonsState.together
          includers = view.model.getIncluders() || []
          includers.push view.model.get('user_id')
          @trigger 'point:unhighlight_includers', includers 

      @listenTo controller, 'point:include', (model) =>
        @includePoint model



    getCraftingController : (region) ->
      new Proposal.CraftingController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @
        prior_state : @prior_state

    getPointsController : (region, valence, collection) ->
      new App.Franklin.Points.PeerPointsController
        valence : valence
        collection : collection
        proposal : @model
        region : region
        parent_controller : @
        parent_state : @state

    getResultsFooterView : ->
      switch @state
        when Proposal.ReasonsState.together
          new Proposal.ResultsFooterView
            model : @model
        when Proposal.ReasonsState.collapsed
          new Proposal.ResultsFooterCollapsedView
            model : @model
        when Proposal.ReasonsState.separated
          new Proposal.ResultsFooterSeparatedView
            model : @model

    getParticipantsView : ->
      new Proposal.ParticipantsView
        model : @model

    # getHeaderView : (group = 'all') ->
    #   switch @state
    #     when Proposal.ReasonsState.together
    #       new Proposal.ResultsHeaderView
    #         model : @model
    #         group : group
    #     when Proposal.ReasonsState.collapsed
    #       new Proposal.ResultsHeaderViewCollapsed
    #         model : @model
    #         group : group
    #     when Proposal.ReasonsState.separated
    #       new Proposal.ResultsHeaderViewSeparated
    #         model : @model
    #         group : group

    getLayout : ->
      new Proposal.ReasonsLayout
        model : @model
        state : @state



