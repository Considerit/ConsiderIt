@ConsiderIt.module "HeaderApp", (HeaderApp, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show: ->
      new HeaderApp.Show.Controller
        region: App.headerRegion
  
  HeaderApp.on "start", ->
    API.show()