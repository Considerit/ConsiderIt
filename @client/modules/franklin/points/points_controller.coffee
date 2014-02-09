@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  Points.State = 
    Summary : 'summary'
    Crafting : 'crafting'
    Results : 'results'

  class Points.AbstractPointsController extends App.Controllers.StatefulController

    point_controllers : 
      PeerController : {}
      PositionController : {}

    initialize : (options = {}) ->
      super options

      @collection = options.collection

      @layout = @getLayout options.location     

      @setupLayout @layout

      @listenTo @options.parent_controller, 'point:show_details', (point) =>
        is_paginated = @options.collection.fullCollection?

        collection = if is_paginated then @options.collection.fullCollection else @options.collection
        if @respondToPointExpansions() && point = collection.get(point)
          # ensure that point is currently displayed

          if is_paginated
            page = @options.collection.pageOf point
            @options.collection.getPage page

          pointview = @list_view.children.findByModel point
          pointview.trigger 'point:show_details'


          @listenToOnce pointview, 'details:closed', =>
            @trigger 'details:closed', pointview.model

          @trigger 'point:showed_details', point


          # @listenTo controller, 'close', =>
          #   pointview.render()

    processStateChange : ->
      #@layout = @resetLayout @layout

    setupLayout : (layout) ->


    setupListView : (list_view) ->

      @listenTo list_view, 'before:item:added', (view) => 
        return if view instanceof Points.PeerEmptyView
        if _.has @point_controllers[@cname], view.model.id
          @point_controllers[@cname][view.model.id].close()

        @point_controllers[@cname][view.model.id] = new App.Franklin.Point.PointController
          view : view
          model : view.model
          region : new Backbone.Marionette.Region { el : view.el }     
          parent_controller : @


      @listenTo list_view, 'childview:point:clicked', (view) =>
        point = view.model
        App.navigate Routes.proposal_point_path(point.get('long_id'), point.id), {trigger : true}

      @list_view = list_view

    sortPoints : (sort_by) ->
      if @options.collection.setSorting && sort_by #if its pageable...
        @header_view.sort = sort_by
        @options.collection.setSorting sort_by, 1
        @options.collection.fullCollection.sort()


  class Points.PeerPointsController extends Points.AbstractPointsController
    cname: 'PeerController'

    removed_points : []

    current_browse_state : false



    initialize : (options = {}) ->
      super options

      @listenTo options.parent_controller, 'point:removal', (point_id) =>
        is_paginated = options.collection.fullCollection?
        collection = if is_paginated then options.collection.fullCollection else options.collection

        if collection.get point_id
          @sortPoints @header_view.sort

      @region.show @layout

    processStateChange : ->
      super

      return if @collection.size() == 0

      if @state != Points.State.Crafting
        @list_view.children.each (vw) -> vw.disableDrag()
      else
        @list_view.children.each (vw) -> vw.enableDrag()

    segmentPeerPoints : (segment) ->

      fld = if segment == 'all' then 'score' else "score_stance_group_#{segment}"

      @header_view.sort = fld
      @header_view.segment = segment
      @header_view.render()

      if @removed_points.length > 0
        @options.collection.fullCollection.add @removed_points

      @removed_points = @options.collection.fullCollection.filter (point) ->
        !point.get(fld) || point.get(fld) == 0

      all_points = _.difference @options.collection.fullCollection.models, @removed_points

      @options.collection.setSorting fld, 1
      @options.collection.fullCollection.reset all_points
      # @options.collection.fullCollection.remove @removed_points #causing renders
      # @options.collection.fullCollection.sort()    #causing 2x renders    


    respondToPointExpansions : -> true


    toggleBrowsing : (current_browse_state) ->
      header_view = @header_view
      footer_view = @footer_view

      if !current_browse_state
        @trigger 'points:browsing', @options.valence
        header_view.setBrowsing true
        footer_view.setBrowsing true
        @previous_page_size = @options.collection.state.pageSize
        @options.collection.setPageSize 1000
        @current_browse_state = true
      else
        header_view.setBrowsing false
        footer_view.setBrowsing false
        @trigger 'points:browsing:off', @options.valence
        @options.collection.setPageSize @previous_page_size
        @options.collection.getPage 1
        @current_browse_state = false

    setupLayout : (layout) ->
      super layout

      @listenTo layout, 'show', =>
        sort = if @state == Points.State.Crafting then 'persuasiveness' else 'score'

        @header_view = @getHeaderView sort  
        @footer_view = @getFooterView()

        @listenTo @header_view, 'sort', (sort_by) =>
          @sortPoints sort_by

        @listenTo @header_view, 'points:browsing:toggle', (current_browse_state) =>
          if @state != Points.State.Summary
            @toggleBrowsing current_browse_state
          else
            App.navigate Routes.proposal_path(@options.proposal.id), {trigger : true}
          
        @listenTo @footer_view, 'points:browsing:toggle', (current_browse_state) =>
          if @state != Points.State.Summary
            @toggleBrowsing current_browse_state

        layout.headerRegion.show @header_view

        layout.footerRegion.show @footer_view


        # setup listview after, so that sorting takes place without rerendering
        list_view = @getListView()

        @setupListView list_view

        layout.listRegion.show list_view


    setupListView : (list_view) ->
      super list_view

      @listenTo list_view, 'childview:point:include', (view) => 
        App.vent.trigger 'points:unexpand'
        @trigger 'point:include', view.model

      @listenTo list_view, 'childview:point:highlight_includers', (view) => 
        @trigger 'point:highlight_includers', view

      @listenTo list_view, 'childview:point:unhighlight_includers', (view) => 
        @trigger 'point:unhighlight_includers', view

      @listenTo list_view, 'before:item:added', (view) => 
        @listenTo view, 'render', =>
          if @state == Points.State.Crafting && @collection.size() > 0
            view.enableDrag()

    getHeaderView : (sort) ->
      new Points.ExpandablePointListHeader
        browsing: false
        collection : @options.collection
        sort : sort
        valence : @options.valence

    getFooterView : ->
      new Points.ExpandablePointListFooter
        valence : @options.valence
        collection : @options.collection

    getListView : ->
      new Points.PointList
        itemView : App.Franklin.Point.PeerPointView
        emptyView : Points.PeerEmptyView
        collection : @options.collection
        location: 'peer'

    getLayout : ->
      new Points.PeerPointList
        state : @state
        valence : @options.valence


  class Points.UserReasonsController extends Points.AbstractPointsController
    cname: 'PositionController'



    initialize : (options = {}) ->
      super options
      @region.show @layout

    respondToPointExpansions : ->
      @state != Points.State.Results && @state != Points.State.Summary

    setupLayout : (layout) ->

      super layout

      @listenTo layout, 'show', =>

        header_view = @getHeaderView()
        footer_view = @getFooterView()
        list_view = @getListView()

        @setupListView list_view

        @listenTo footer_view, 'point:create:requested', (attrs) =>
          _.extend attrs, 
            proposal_id : @options.proposal.get('id')
            long_id : @options.proposal.id

          new_point = App.request 'point:create', attrs, 
            success : => 
              @options.collection.add new_point    
              toastr.success "Thanks for your contribution! Please <strong style='text-decoration:underline'>Save Your Position</strong> below to share your point with others.", null,
                positionClass: "toast-top-full-width"

              @trigger 'point:created', new_point

          # App.execute 'show:loading',
          #   loading:
          #     entities : [new_point]

        layout.headerRegion.show header_view
        layout.listRegion.show list_view
        layout.footerRegion.show footer_view

    setupListView : (list_view) ->
      super list_view
      @listenTo list_view, 'childview:point:remove', (view) => @trigger 'point:remove', view

    getHeaderView : ->
      new Points.UserReasonsPointListHeader
        collection : @options.collection
        sort : null
        valence : @options.valence

    getFooterView : ->
      new Points.UserReasonsPointListFooter
        valence : @options.valence

    getListView : ->
      new Points.PointList
        itemView : App.Franklin.Point.PositionPointView
        collection : @options.collection
        location: 'position'

    getLayout : ->
      new Points.UserReasonsList
        state : @state
        valence : @options.valence



