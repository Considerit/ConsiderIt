@ConsiderIt.module "FooterApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.Controller extends App.Controllers.Base
    
    initialize: ->
      showView = @getShowView()
      @show showView
    
    getShowView: ->
      new Show.Footer