@ConsiderIt.module "Components.Dialog", (Dialog, App, Backbone, Marionette, $, _) ->
  class Dialog.DialogWrapper extends App.Views.Layout
    template: '#tpl_dialog_detachable'
    regions:
      titleRegion: '.l-dialog-title' 
      contentRegion: ".l-dialog-body"    

    serializeData: ->
      title : @options.config.title
      close_label : @options.config.close_label

    events : 
      'click [data-target="dialog-close"]' : 'closeRequested'

    closeRequested : => 
      console.log 'TRIGGERED'
      @trigger 'closeRequested'      