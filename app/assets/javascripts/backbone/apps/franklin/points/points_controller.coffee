@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  Points.States = 
    collapsed : 'points-collapsed'
    together : 'points-together'
    separated : 'points-separated'
    position : 'points-position'
    hidden : 'points-hidden'


  class Points.AbstractPointsController extends App.Controllers.StatefulController
    state_map : ->
      throw 'need to override'

    point_controllers : {}

    initialize : (options = {}) ->
      super options

      @layout = @getLayout options.location     

      @setupLayout @layout

      @listenTo @options.parent_controller, 'point:show_details', (point) =>
        is_paginated = @options.collection.fullCollection?

        collection = if is_paginated then @options.collection.fullCollection else @options.collection
        if point = collection.get point
          # ensure that point is currently displayed
          if is_paginated
            page = @options.collection.pageOf point
            @options.collection.getPage page

          pointview = @layout.children.findByModel point
          pointview.trigger 'point:show_details'

          @listenToOnce pointview, 'details:closed', =>
            @trigger 'details:closed', pointview.model

          @trigger 'point:showed_details', point


          # @listenTo controller, 'close', =>
          #   pointview.render()

    processStateChange : ->
      @layout = @resetLayout @layout

    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        @listenTo layout, 'before:item:added', (view) => 
          return if view instanceof Points.PeerEmptyView
          if _.has @point_controllers, view.model.id
            @point_controllers[view.model.id].close()

          @point_controllers[view.model.id] = new App.Franklin.Point.PointController
            view : view
            model : view.model
            region : new Backbone.Marionette.Region { el : view.el }     
            parent_controller : @

        @listenTo layout, 'sort', (sort_by) =>
          @sortPoints sort_by

        @listenTo layout, 'childview:point:clicked', (view) =>
          point = view.model
          App.navigate Routes.proposal_point_path(point.get('long_id'), point.id), {trigger : true}

    sortPoints : (sort_by) ->
      if @options.collection.setSorting #if its pageable...
        @options.collection.setSorting sort_by, 1
        @options.collection.fullCollection.sort()


  class Points.PeerPointsController extends Points.AbstractPointsController
    removed_points : []

    state_map : ->
      map = {}
      map[App.Franklin.Proposal.ReasonsState.together] = Points.States.together
      map[App.Franklin.Proposal.ReasonsState.separated] = Points.States.separated
      map[App.Franklin.Proposal.ReasonsState.collapsed] = Points.States.collapsed
      map 


    initialize : (options = {}) ->
      super options

      @listenTo options.parent_controller, 'point:removal', (point_id) =>
        is_paginated = options.collection.fullCollection?
        collection = if is_paginated then options.collection.fullCollection else options.collection

        if collection.get point_id
          @sortPoints @layout.sort

      @region.show @layout

    processStateChange : ->
      #@layout = @resetLayout @layout

    segmentPeerPoints : (segment) ->
      fld = if segment == 'all' then 'score' else "score_stance_group_#{segment}"
      @layout.sort = fld
      @layout.segment = segment


      if @removed_points.length > 0
        @options.collection.fullCollection.add @removed_points

      @removed_points = @options.collection.fullCollection.filter (point) ->
        !point.get(fld) || point.get(fld) == 0

      @options.collection.fullCollection.remove @removed_points
      @options.collection.setSorting fld, 1
      @options.collection.fullCollection.sort()          


    setupLayout : (layout) ->
      super layout

      $transition_speed = 1200

      @listenTo layout, 'show', =>
        @listenTo layout, 'childview:point:include', (view) => 
          App.vent.trigger 'points:unexpand'
          @trigger 'point:include', view
        @listenTo layout, 'childview:point:highlight_includers', (view) => 
          @trigger 'point:highlight_includers', view
        @listenTo layout, 'childview:point:unhighlight_includers', (view) => 
          @trigger 'point:unhighlight_includers', view

        @listenTo layout, 'points:browsing', =>
          @trigger 'points:browsing', @options.valence
          _.delay =>
            @previous_page_size = @options.collection.state.pageSize
            @options.collection.setPageSize 1000
          , $transition_speed

        @listenTo layout, 'points:browsing:off', =>
          @trigger 'points:browsing:off', @options.valence

          _.delay =>
            @options.collection.setPageSize @previous_page_size
            @options.collection.getPage 1
          , $transition_speed

    getLayout : ->
      new Points.PeerPointList
        collection : @options.collection
        valence : @options.valence
        state : @state



  class Points.UserReasonsController extends Points.AbstractPointsController
    state_map : ->
      map = {}
      map[App.Franklin.Proposal.ReasonsState.separated] = Points.States.position    
      map[App.Franklin.Proposal.ReasonsState.together] = Points.States.position
      map[App.Franklin.Proposal.ReasonsState.collapsed] = Points.States.position
      map 

    initialize : (options = {}) ->

      super options

      @region.show @layout

    processStateChange : ->
      #@layout = @resetLayout @layout

    setupLayout : (layout) ->

      super layout

      @listenTo @layout, 'show', =>

        @listenTo @layout, 'childview:point:remove', (view) => @trigger 'point:remove', view

        @listenTo @layout, 'point:create:requested', (attrs) =>
          _.extend attrs, 
            proposal_id : @options.proposal.id
            long_id : @options.proposal.long_id

          new_point = App.request 'point:create', attrs
          App.execute 'when:fetched', new_point, =>

            @options.collection.add new_point    
            toastr.success "Good point! Please <strong style='text-decoration:underline'>Save Your Position</strong> below to share your point with others.", null,
              positionClass: "toast-top-full-width"

            @trigger 'point:created', new_point

          # App.execute 'show:loading',
          #   loading:
          #     entities : [new_point]

    getLayout : ->
      new Points.UserReasonsList
        collection : @options.collection
        valence : @options.valence
        state : @state
