@ConsiderIt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->
  
  class Show.Controller extends App.Controllers.Base
    
    initialize: ->
      @layout = @getLayout()
      @show @layout
    
    getLayout: ->
      new Show.Layout