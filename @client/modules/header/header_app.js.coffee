@ConsiderIt.module "Header", (Header, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show: ->
      @controller = new Header.HeaderController
        region: App.headerRegion

    getUserNav: ->
      @controller.layout.userNavRegion
  
  App.reqres.setHandler "userNavRegion", ->
    API.getUserNav()

  Header.on "start", ->
    API.show()