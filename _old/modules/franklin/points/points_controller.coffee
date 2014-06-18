@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  Points.State = 
    Summary : 'summary'
    Crafting : 'crafting'
    Results : 'results'

  class Points.AbstractPointsController extends App.Controllers.StatefulController

    point_controllers : 
      CommunityPointsController : {}
      DecisionBoardPointsController : {}

    initialize : (options = {}) ->
      super options

      @collection = options.collection

      @layout = @getLayout options.location     

      @setupLayout @layout

      @listenTo @options.parent_controller, 'point:open', (point) =>
        is_paginated = @options.collection.fullCollection?

        collection = if is_paginated then @options.collection.fullCollection else @options.collection
        if @canExpand() && point = collection.get(point)
          # ensure that point is currently displayed

          if is_paginated
            page = @options.collection.pageOf point
            @options.collection.getPage page

          pointview = @list_view.children.findByModel point
          pointview.trigger 'point:open'


          @listenToOnce pointview, 'point:closed', =>
            @trigger 'point:closed', pointview.model

          @trigger 'point:opened', point


          # @listenTo controller, 'close', =>
          #   pointview.render()

    stateWasChanged : ->
      #@layout = @resetLayout @layout

    setupLayout : (layout) ->


    setupListView : (list_view) ->

      @listenTo list_view, 'before:item:added', (view) => 
        return if view instanceof Points.NoCommunityPointsView
        if _.has @point_controllers[@cls_name], view.model.id
          @point_controllers[@cls_name][view.model.id].close()

        @point_controllers[@cls_name][view.model.id] = new App.Franklin.Point.PointController
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


  class Points.CommunityPointsController extends Points.AbstractPointsController
    cls_name: 'CommunityPointsController'
    removed_points : []
    is_expanded : false

    initialize : (options = {}) ->
      super options

      @listenTo options.parent_controller, 'point:removal', (point_id) =>
        is_paginated = options.collection.fullCollection?
        collection = if is_paginated then options.collection.fullCollection else options.collection

        if collection.get point_id
          @sortPoints @header_view.sort

      @region.show @layout

    stateWasChanged : ->
      super

      return if @collection.size() == 0

      if @state != Points.State.Crafting
        @list_view.children.each (vw) -> vw.disableDrag()
      else
        @list_view.children.each (vw) -> vw.enableDrag()

    segmentCommunityPoints : (segment) ->

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


    canExpand : -> true


    toggleExpanded : (is_expanded) ->
      header_view = @header_view
      footer_view = @footer_view

      if !is_expanded        
        @trigger 'points:expand', @options.valence
        header_view.setExpandPoints true
        footer_view.setExpandPoints true
        @previous_page_size = @options.collection.state.pageSize
        @options.collection.setPageSize 1000
        @is_expanded = true
      else
        header_view.setExpandPoints false
        footer_view.setExpandPoints false
        @trigger 'points:unexpand', @options.valence
        @options.collection.setPageSize @previous_page_size
        @options.collection.getPage 1
        @is_expanded = false

    setupLayout : (layout) ->
      super layout

      @listenTo layout, 'show', =>
        sort = if @state == Points.State.Crafting then 'persuasiveness' else 'score'

        @header_view = @getHeaderView sort  
        @footer_view = @getFooterView()

        @listenTo @header_view, 'sort', (sort_by) =>
          @sortPoints sort_by

        @listenTo @header_view, 'points:toggle_expanded', (is_expanded) =>
          if @state != Points.State.Summary
            @toggleExpanded is_expanded
          else
            App.navigate Routes.proposal_path(@options.proposal.id), {trigger : true}
          
        @listenTo @footer_view, 'points:toggle_expanded', (is_expanded) =>
          if @state != Points.State.Summary
            @toggleExpanded is_expanded

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
      new Points.CommunityPointsHeader
        expanded: false
        collection : @options.collection
        sort : sort
        valence : @options.valence

    getFooterView : ->
      new Points.CommunityPointsFooter
        valence : @options.valence
        collection : @options.collection

    getListView : ->
      new Points.PointsList
        itemView : App.Franklin.Point.CommunityPointView
        emptyView : Points.NoCommunityPointsView
        collection : @options.collection
        location: 'community'

    getLayout : ->
      new Points.CommunityPointsColumn
        state : @state
        valence : @options.valence


  class Points.DecisionBoardColumnController extends Points.AbstractPointsController
    cls_name: 'DecisionBoardPointsController'

    initialize : (options = {}) ->
      super options
      @region.show @layout

    canExpand : ->
      @state != Points.State.Results && @state != Points.State.Summary

    setupLayout : (layout) ->

      super layout

      @listenTo layout, 'show', =>

        header_view = @getHeaderView()
        footer_view = @getFooterView()
        list_view = @getListView()

        @setupListView list_view

        @listenTo footer_view, 'point:please_create_point', (attrs) =>
          _.extend attrs, 
            proposal_id : @options.proposal.get('id')
            long_id : @options.proposal.id

          new_point = App.request 'point:create', attrs, 
            success : => 
              @options.collection.add new_point    
              App.execute 'notify:success', "Thanks for your contribution!"

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
      new Points.DecisionBoardColumnHeader
        collection : @options.collection
        sort : null
        valence : @options.valence

    getFooterView : ->
      new Points.DecisionBoardColumnFooter
        valence : @options.valence

    getListView : ->
      new Points.PointsList
        itemView : App.Franklin.Point.DecisionBoardPointView
        collection : @options.collection
        location: 'decision_board'

    getLayout : ->
      new Points.DecisionBoardColumn
        state : @state
        valence : @options.valence



