@ConsiderIt = do (Backbone, Marionette) ->
  
  App = new Marionette.Application

  App.on "initialize:before", (options) ->
    App.environment = options.environment
  
  App.addRegions
    headerRegion: "#l-header"
    #mainRegion:    "#main-region"
    footerRegion: "#l-footer"
  
  # App.rootRoute = Routes.crew_index_path()
  
  App.addInitializer ->
    App.module("HeaderApp").start()
    App.module("FooterApp").start()
  
  # App.reqres.setHandler "default:region", ->
  #   App.mainRegion
  
  # App.commands.setHandler "register:instance", (instance, id) ->
  #   App.register instance, id if App.environment is "development"
  
  # App.commands.setHandler "unregister:instance", (instance, id) ->
  #   App.unregister instance, id if App.environment is "development"
  
  App.on "initialize:after", ->

    # REFACTOR
    ConsiderIt.router = new ConsiderIt.Router();
    ConsiderIt.app = new ConsiderIt.AppView();
    ConsiderIt.app.render();
    #####
    
    @startHistory()
    #@navigate(@rootRoute, trigger: true) unless @getCurrentRoute()



  App