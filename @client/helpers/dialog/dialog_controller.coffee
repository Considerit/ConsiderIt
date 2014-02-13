@ConsiderIt.module "Helpers.Dialog", (Dialog, App, Backbone, Marionette, $, _) ->
  class Dialog.DialogController extends App.Controllers.Base
    
    initialize: (options = {}) ->
      @contentView = options.view
      
      @dialogLayout = @getDialogLayout options.config
      @listenTo @dialogLayout, "show", =>
        @center()
        @dialogLayout.contentRegion.show @contentView
        @region.$el.putBehindLightbox()
        @center()

        @listenTo @contentView, 'close', ->
          @region.$el.removeLightbox()
          @close()  
        
        @listenTo @dialogLayout, 'closeRequested', ->
          @dialogLayout.trigger 'dialog:canceled'
          @close()

        App.vent.trigger 'dialog:opened', @

        @listenTo App.vent, 'dialog:opened', (dialog) =>
          if dialog != @
            @close()

        @$el = @region.$el


    getDialogLayout: (options = {}) ->
      config = @getDefaultConfig _.result(@contentView, "dialog")
      _.extend {}, config, options

      new Dialog.DialogWrapper
        config: config

    center : ->
      window_height = $(window).height()
      dialog_height = @region.$el.height()

      $overlay = @region.$el
      $overlay.offset 
        top: $(document).scrollTop() + Math.max( (window_height - dialog_height) / 2, 50)
        left: $(window).innerWidth() / 2 - $overlay.outerWidth() / 2
  
    getDefaultConfig: (config = {}) ->
      _.defaults config,
        title: ''

    close: ->
      @dialogLayout.close()
      super
      @$el.remove()

  App.reqres.setHandler "dialog:new", (contentView, options = {}) ->
    options.class ?= ''

    $existing = $('.l-dialog-detachable')

    $overlay = $("<div class='l-dialog-detachable #{options.class}'>")
    $('#l_wrap').prepend($overlay)

    @dialogController = new Dialog.DialogController
      view: contentView
      config: options
      region: new Backbone.Marionette.Region
        el: ".l-dialog-detachable"

    @dialogController.show @dialogController.dialogLayout
    @dialogController.dialogLayout
    

  App.reqres.setHandler "dialog:close", (contentView, options = {}) ->
    @dialogController.close()