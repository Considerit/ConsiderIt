@ConsiderIt.module "Footer", (Footer, App, Backbone, Marionette, $, _) ->
  @startWithParent = false
  
  API =
    show: ->
      new Footer.FooterController
        region: App.footerRegion
  
  Footer.on "start", ->
    API.show()