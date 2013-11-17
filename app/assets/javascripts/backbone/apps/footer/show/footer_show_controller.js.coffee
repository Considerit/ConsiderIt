@ConsiderIt.module "FooterApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.FooterShowController extends App.Controllers.Base
    
    initialize: ->
      showView = @getShowView()
      @show showView

      @listenTo App.vent, 'transition:start', =>
        @region.$el.hide()

      @listenTo App.vent, 'transition:end', =>
        @region.$el.fadeIn()
    
    getShowView: ->
      new Show.Footer