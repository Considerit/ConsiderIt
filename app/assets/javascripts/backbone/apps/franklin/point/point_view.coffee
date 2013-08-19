@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->
  
  class Point.PointView extends App.Views.ItemView
    tagName : 'li'
    template : '#tpl_point_view'

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        adjusted_nutshell : @model.adjusted_nutshell()
        user : @model.getUser().attributes
        proposal : @model.getProposal().attributes

      params

    onRender : ->
      #TODO: in previous scheme, this change was intended to trigger render on point details close
      @listenTo @model, 'change', @render

      valence = if @model.attributes.is_pro then 'pro' else 'con'
      @$el.addClass valence
      @stickit()

    bindings : 
      '.m-point-read-more' : 
        observe : 'comment_count'
        onGet : -> if @model.get('comment_count') == 1 then "1 comment" else "#{@model.get('comment_count')} comments"


  class Point.PeerPointView extends Point.PointView

    events : 
      'click [data-target="point-include"]' : 'includePoint'

    includePoint : (ev) ->
      @trigger 'point:include'

  class Point.PositionPointView extends Point.PointView

    events : 
      'click [data-target="point-remove"]' : 'removePoint'

    removePoint : (ev) ->
      @trigger 'point:remove'

  class Point.AggregatePointView extends Point.PointView

    events : 
      'mouseenter' : 'highlightIncluders'
      'mouseleave' : 'unhighlightIncluders'

    highlightIncluders : ->
      @trigger 'point:highlight_includers'

    unhighlightIncluders : ->
      @trigger 'point:unhighlight_includers'


  class Point.PointDetailsView extends App.Views.ItemView


  # class Point.NewPointView extends App.Views.ItemView