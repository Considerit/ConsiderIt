@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  class Points.AbstractPointsController extends App.Controllers.Base
    initialize : (options = {}) ->
      layout = @getLayout options.location
      @listenTo layout, 'before:item:added', (view) => 
        new App.Franklin.Point.PointController
          view : view
          model : view.model
          region : new Backbone.Marionette.Region { el : view.el }     
          parent_controller : @
     

      @listenTo layout, 'show', =>
        App.vent.on 'point:removal', (point_id) =>
          is_paginated = @options.collection.fullCollection?
          collection = if is_paginated then @options.collection.fullCollection else @options.collection

          if collection.get point_id
            @sortPoints layout.sort
        @listenTo layout, 'sort', (sort_by) =>
          @sortPoints sort_by

        @listenTo layout, 'childview:point:clicked', (view) =>
          point = view.model
          App.navigate Routes.proposal_point_path(point.get('long_id'), point.id), {trigger : true}

      @listenTo @options.parent, 'point:show_details', (point) =>
        is_paginated = @options.collection.fullCollection?

        collection = if is_paginated then @options.collection.fullCollection else @options.collection
        if point = collection.get point
          # ensure that point is currently displayed
          if is_paginated
            page = @options.collection.pageOf point
            @options.collection.getPage page

          pointview = layout.children.findByModel point
          pointview.trigger 'point:show_details'

          # @listenTo controller, 'close', =>
          #   pointview.render()

      @layout = layout

    sortPoints : (sort_by) ->
      if @options.collection.setSorting #if its pageable...
        @options.collection.setSorting sort_by, 1
        @options.collection.fullCollection.sort()


  class Points.PeerPointsController extends Points.AbstractPointsController

    initialize : (options = {}) ->
      super options
      @listenTo @layout, 'show', =>
        @listenTo @layout, 'childview:point:include', (view) => @trigger 'point:include', view

      @region.show @layout

    getLayout : ->
      new Points.PeerPointList
        collection : @options.collection
        valence : @options.valence

  class Points.UserReasonsController extends Points.AbstractPointsController
  
    initialize : (options = {}) ->
      super options
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


      @region.show @layout

    getLayout : ->
      new Points.UserReasonsList
        collection : @options.collection
        valence : @options.valence

  class Points.AggregatedReasonsController extends Points.AbstractPointsController

    initialize : (options = {}) ->
      super options
      @listenTo @layout, 'show', =>
        @listenTo @layout, 'childview:point:highlight_includers', (view) => 
          @trigger 'point:highlight_includers', view
        @listenTo @layout, 'childview:point:unhighlight_includers', (view) => @trigger 'point:unhighlight_includers', view

      @region.show @layout


    getLayout : ->
      new Points.AggregatedReasonsList
        collection : @options.collection
        valence : @options.valence