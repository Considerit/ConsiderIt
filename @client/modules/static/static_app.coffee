@ConsiderIt.module "Static", (Static, App, Backbone, Marionette, $, _) ->
  class Static.Router extends Marionette.AppRouter
    appRoutes : 
      "home/:page(/)": "show"


  API =    
    show: (page) ->      
      $(document).scrollTop(0)
      region = App.request 'default:region'
      
      region.controlled_by.close() if region.controlled_by

      new Static.StaticController
        region: region
        page : page

      App.vent.trigger 'route:completed', [ ['homepage', '/'], [page, "/home/#{page}"] ]
      App.request 'meta:change:default'

  

  Static.on "start", ->
    new Static.Router
      controller : API