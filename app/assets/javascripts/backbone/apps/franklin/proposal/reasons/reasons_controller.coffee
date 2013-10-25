@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  class Proposal.ReasonsController extends App.Controllers.StatefulController
    removed_points : {}

    # maps from parent state to this controller's state
    state_map : ->
      map = {}
      map[Proposal.State.collapsed] = Proposal.ReasonsState.collapsed
      map[Proposal.State.expanded.crafting] = Proposal.ReasonsState.separated
      map[Proposal.State.expanded.results] = Proposal.ReasonsState.together
      map


    # transition or reset views as appropriate after state has been updated
    processStateChange : ->
      @updatePeerPoints @layout
      @layout.sizeToFit @state != Proposal.ReasonsState.separated

      if !@crafting_controller && @options.model.fetched && @state != Proposal.ReasonsState.collapsed
        @crafting_controller = @getCraftingController @layout.positionRegion
        @setupCraftingController @crafting_controller 

      #if @state != Proposal.ReasonsState.collapsed || (@peer_pros_controller.options.collection.length + @peer_cons_controller.options.collection.length > 0)
      footer_view = @getResultsFooterView()
      @header_view = @getHeaderView()

      @layout.reasonsHeaderRegion.show @header_view


      if @state == Proposal.ReasonsState.together && !@options.model.getUserPosition().get('published')
        _.delay =>
          footer_view.$el.hide()
          App.request "sticky_footer:new", footer_view
          footer_view.$el.fadeIn 300
        , 2000

      else
        @layout.footerRegion.show footer_view
        if @prior_state != null
          App.request "sticky_footer:close"


    initialize : (options = {}) ->
      super options

      @model = options.model

      @listenTo @options.parent_controller, 'point:show_details', (point) =>
        @trigger 'point:show_details', point

      @layout = @getLayout()
      @setupLayout @layout

      @region.show @layout


    setupLayout : (layout) ->

      @listenTo layout, 'show', =>
        @processStateChange()

    updatePeerPoints : (layout) ->
      if @prior_state
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

            when Proposal.ReasonsState.collapsed
              top_points = [@model.get('top_pro'), @model.get('top_con')]
              collection.fullCollection.set  top_points
              collection.setPageSize 1

            when Proposal.ReasonsState.together
              collection.setPageSize 5

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
            page_size = 5
            App.request 'points:get:proposal', @model.id

        aggregated_pros = new App.Entities.PaginatedPoints points.filter((point) -> point.isPro()), {state: {pageSize:page_size} }
        aggregated_cons = new App.Entities.PaginatedPoints points.filter((point) -> !point.isPro()), {state: {pageSize:page_size} }

        @peer_pros_controller = @getPointsController layout.peerProsRegion, 'pro', aggregated_pros
        @peer_cons_controller = @getPointsController layout.peerConsRegion, 'con', aggregated_cons

        _.each [@peer_pros_controller, @peer_cons_controller], (controller) =>
          @listenTo controller, 'point:show_details', (point) =>
            @layout.pointExpanded point, @state != Proposal.ReasonsState.separated

            @listenToOnce controller, 'details:close', (point) =>
              @layout.pointClosed point, @state != Proposal.ReasonsState.separated

        @setupPointsController @peer_pros_controller
        @setupPointsController @peer_cons_controller

    segmentPeerPoints : (segment) ->
      fld = if segment == 'all' then 'score' else "score_stance_group_#{segment}"
      @header_view.updateHeader segment            
      _.each [@peer_pros_controller.options.collection, @peer_cons_controller.options.collection], (collection, idx) =>
        if idx of @removed_points
          collection.fullCollection.add @removed_points[idx]

        @removed_points[idx] = collection.fullCollection.filter (point) ->
          !point.get(fld) || point.get(fld) == 0

        collection.fullCollection.remove @removed_points[idx]
        collection.setSorting fld, 1
        collection.fullCollection.sort()      

    setupCraftingController : (controller) ->
      @listenTo controller, 'point:removal', (model) =>
        controller = if model.isPro() then @peer_pros_controller else @peer_cons_controller
        controller.options.collection.add model
        @trigger 'point:removal', model.id

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

      @listenTo controller, 'point:include', (view) =>
        model = view.model # a Point...
        source_controller = if model.isPro() then @peer_pros_controller else @peer_cons_controller
        source = source_controller.options.collection
        dest_controller  = if model.isPro() then @crafting_controller.position_pros_controller else @crafting_controller.position_cons_controller
        dest = dest_controller.options.collection

        dest.add model

        $included_point = @layout.$el.find ".m-point-position[data-id='#{model.id}']"

        @layout.includePoint model, view.$el, $included_point, source

        params =
          proposal_id : @model.id
          point_id : model.id
        
        window.addCSRF params
        $.post Routes.inclusions_path(), 
          params, (data) =>
            position = @model.getUserPosition()
            position.includePoint model

            current_user = App.request 'user:current'
            current_user.setFollowing 
              followable_type : 'Point'
              followable_id : model.id
              follow : true
              explicit: false


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


    getHeaderView : ->
      switch @state
        when Proposal.ReasonsState.together
          new Proposal.ResultsHeaderView
            model : @model
        when Proposal.ReasonsState.collapsed
          new Proposal.ResultsHeaderViewCollapsed
            model : @model
        when Proposal.ReasonsState.separated
          new Proposal.ResultsHeaderViewSeparated
            model : @model

    getLayout : ->
      new Proposal.ReasonsLayout
        model : @model
        state : @state



