@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->
  
  class Point.PointView extends App.Views.Layout
    tagName : 'li'
    template : '#tpl_point_view'

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        adjusted_nutshell : @model.adjusted_nutshell()
        user : @model.getUser().attributes
        proposal : @model.getProposal().attributes

      params

    expand : ->

    onRender : ->
      #TODO: in previous scheme, this change was intended to trigger render on point details close
      @listenTo @model, 'change', @render

      @stickit()

    bindings : 
      '.m-point-read-more' : 
        observe : 'comment_count'
        onGet : -> if @model.get('comment_count') == 1 then "1 comment" else "#{@model.get('comment_count')} comments"

    @events : 
      'click' : 'pointClicked'

    pointClicked : (ev) ->
      @trigger 'point:clicked'
      ev.stopPropagation()

  class Point.PeerPointView extends Point.PointView

    events : _.extend @events,
      'click [data-target="point-include"]' : 'includePoint'

    includePoint : (ev) ->
      @trigger 'point:include'
      ev.stopPropagation()

  class Point.PositionPointView extends Point.PointView

    events : _.extend @events,
      'click [data-target="point-remove"]' : 'removePoint'

    removePoint : (ev) ->
      @trigger 'point:remove'
      ev.stopPropagation()

  class Point.AggregatePointView extends Point.PointView

    events : _.extend @events,
      'mouseenter' : 'highlightIncluders'
      'mouseleave' : 'unhighlightIncluders'

    highlightIncluders : ->
      @trigger 'point:highlight_includers'

    unhighlightIncluders : ->
      @trigger 'point:unhighlight_includers'

  class Point.ExpandedPointView extends Point.PointView
    template : '#tpl_expanded_point'
    className : 'm-point-expanded'
    regions :
      pointHeaderRegion : '.m-point-header'
      assessmentRegion : '.m-point-assessment'
      discussionRegion : '.m-point-discussion'



    onShow : ->
      # when clicking outside of point, close it      
      $(document).on 'click.m-point-details', (ev)  => 
        if ($(ev.target).closest('.m-point-expanded').length == 0 || $(ev.target).closest('.m-point-expanded').data('id') != @model.id) && $(ev.target).closest('.editable-buttons').length == 0
          @closeDetails( $(ev.target).closest('[data-role="m-point"]').length == 0 && $(ev.target).closest('.l-navigate-wrap').length == 0 ) 

      $(document).on 'keyup.m-point-details', (ev) => @closeDetails() if ev.keyCode == 27 && $('#l-dialog-detachable').length == 0

      current_user = ConsiderIt.request('user:current')
      if current_user.id == @model.get('user_id') #|| ConsiderIt.request('user:current').isAdmin()
        @$el.find('.m-point-nutshell ').editable
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @model.get('long_id'), @model.id
          type: 'textarea'
          name: 'nutshell'
          success : (response, new_value) => @model.set('nutshell', new_value)


        @$el.find('.m-point-details-description ').editable
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @model.get('long_id'), @model.id
          type: 'textarea'
          name: 'text'
          success : (response, new_value) => @model.set('text', new_value)

    closeDetails : (go_back) ->
      $(document).off '.m-point-details'
      
      App.navigate Routes.root_path(), {trigger : true}


      # go_back ?= true
      # @$el.find('.m-point-wrap > *').css 'visibility', 'hidden'

      # @commentsview.clear()
      # @commentsview.remove()
      # @assessmentview.remove() if @assessmentview?


      # @$el.removeClass('m-point-expanded')
      # @$el.addClass('m-point-unexpanded')

      # @undelegateEvents()
      # @stopListening()
      
      # @model.trigger 'change' #trigger a render event
      # ConsiderIt.app.go_back_crumb() if go_back


  # class Point.NewPointView extends App.Views.ItemView