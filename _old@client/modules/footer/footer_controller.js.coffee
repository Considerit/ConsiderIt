@ConsiderIt.module "Footer", (Footer, App, Backbone, Marionette, $, _) ->
  
  class Footer.FooterController extends App.Controllers.Base
    
    initialize: ->
      showView = @getShowView()
      @show showView

      @listenTo App.vent, 'transition:start', =>
        @region.$el.hide()

      @listenTo App.vent, 'transition:end', =>
        @region.$el.fadeIn()
    
    getShowView: ->
      new Footer.FooterView