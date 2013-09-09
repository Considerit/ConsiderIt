@ConsiderIt.module "FooterApp", (FooterApp, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show: ->
      new FooterApp.Show.FooterShowController
        region: App.footerRegion
  
  FooterApp.on "start", ->
    API.show()