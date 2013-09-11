@ConsiderIt.module "Components.Dialog", (Dialog, App, Backbone, Marionette, $, _) ->
  class Dialog.Controller extends App.Controllers.Base
    
    initialize: (options = {}) ->
      @contentView = options.view
      
      @dialogLayout = @getDialogLayout options.config
      @listenTo @dialogLayout, "show", =>
        @dialogLayout.contentRegion.show @contentView
        @center()

        @listenTo @contentView, 'close', ->
          @dialogLayout.trigger 'dialog:canceled'
          @close()  
        
        @listenTo @dialogLayout, 'closeRequested', ->
          @dialogLayout.trigger 'dialog:canceled'
          @close()

      # @listenTo @dialogLayout, "show", @formContentRegion
      # @listenTo @dialogLayout, "form:submit", @formSubmit
      # @listenTo @dialogLayout, "form:cancel", @formCancel

    getDialogLayout: (options = {}) ->
      config = @getDefaultConfig _.result(@contentView, "dialog")
      _.extend {}, config, options

      new Dialog.DialogWrapper
        config: config

    center : ->
      $overlay = @region.$el
      $overlay.offset 
        top: $(document).scrollTop() + 50
        left: $(window).innerWidth() / 2 - $overlay.outerWidth() / 2
  
    getDefaultConfig: (config = {}) ->
      _.defaults config,
        title: ''
        close_label: 'close'

    close: ->
      @dialogLayout.close()
      super
      $('#l-dialog-detachable').remove()

  App.reqres.setHandler "dialog:new", (contentView, options = {}) ->
    options.class ?= ''

    $overlay = $("<div id='l-dialog-detachable' class='#{options.class}'>")
    $('#l-wrap').prepend($overlay)

    @dialogController = new Dialog.Controller
      view: contentView
      config: options
      region: new Backbone.Marionette.Region
        el: "#l-dialog-detachable"

    @dialogController.show @dialogController.dialogLayout
    @dialogController.dialogLayout
    

  App.reqres.setHandler "dialog:close", (contentView, options = {}) ->
    @dialogController.close()