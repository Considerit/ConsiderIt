@ConsiderIt.module "Franklin", (Franklin, App, Backbone, Marionette, $, _) ->

  class Franklin.Router extends Marionette.AppRouter

  API = 
    test : null
    
  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
