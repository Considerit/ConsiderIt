@ConsiderIt.module "Franklin.Position", (Position, App, Backbone, Marionette, $, _) ->

  class Position.PositionController extends App.Controllers.Base

    initialize : (options = {}) ->
      view = @getView()

      @listenTo view, 'show', =>
        @setupView view

      @dialog_overlay = @getOverlay view

      @listenTo @dialog_overlay, 'close', ->
        App.request 'nav:back:crumb'

    setupView : (view) ->

    getView : ->
      new Position.PositionView
        model : @options.model

    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'm-static-position'
