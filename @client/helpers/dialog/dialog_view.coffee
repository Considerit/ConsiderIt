@ConsiderIt.module "Helpers.Dialog", (Dialog, App, Backbone, Marionette, $, _) ->
  class Dialog.DialogWrapper extends App.Views.Layout
    template: '#tpl_dialog_detachable'
    regions:
      titleRegion: '.l-dialog-title' 
      contentRegion: ".l-dialog-body"    

    serializeData: ->
      title : @options.config.title

    events : 
      'click [action="dialog-close"]' : 'closeRequested'

    closeRequested : (ev) => 
      @trigger 'closeRequested'      
      ev.stopPropagation()