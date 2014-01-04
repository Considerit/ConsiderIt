@ConsiderIt.module "Franklin.Position", (Position, App, Backbone, Marionette, $, _) ->

  class Position.PositionController extends App.Controllers.Base

    initialize : (options = {}) ->
      view = @getView()

      @listenTo view, 'show', =>
        @setupView view

      @dialog_overlay = @getOverlay view

      @listenToOnce @dialog_overlay, 'close', ->        
        App.request 'nav:back:history' if !@closing_via_history
        @close()

      @listenTo Backbone.history, 'route', (route, name, args) => 
        if name == 'StaticPosition' && parseInt(args[1]) != options.model.get('user_id')
          @closing_via_history = true
          @dialog_overlay.close()

    setupView : (view) ->

    getView : ->
      new Position.PositionView
        model : @options.model

    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'm-static-position'
