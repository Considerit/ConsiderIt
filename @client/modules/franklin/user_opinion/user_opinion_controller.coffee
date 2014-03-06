@ConsiderIt.module "Franklin.UserOpinion", (UserOpinion, App, Backbone, Marionette, $, _) ->

  class UserOpinion.UserOpinionController extends App.Controllers.Base

    initialize : (options = {}) ->
      view = @getView()

      @listenTo view, 'show', =>
        @setupView view

      @dialog_overlay = @getOverlay view

      @listenTo @dialog_overlay, 'close', ->        
        App.request 'nav:back:crumb' if !@closing_via_history
        @close()

      @listenTo Backbone.history, 'route', (route, name, args) => 
        if !(name == 'UserOpinion' && parseInt(args[1]) == options.model.get('user_id'))
          @closing_via_history = true
          @dialog_overlay.close()
          @close()

    setupView : (view) ->

    getView : ->
      new UserOpinion.UserOpinionView
        model : @options.model

    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'user_opinion'
