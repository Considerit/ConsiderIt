@ConsiderIt.module "HeaderApp", (HeaderApp, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show: ->
      @controller = new HeaderApp.Show.HeaderShowController
        region: App.headerRegion

    getUserNav: ->
      @controller.layout.userNavRegion
  
  App.reqres.setHandler "userNavRegion", ->
    API.getUserNav()

  HeaderApp.on "start", ->
    API.show()