@ConsiderIt = do (Backbone, Marionette) ->
  
  App = new Marionette.Application

  App.on "initialize:before", (options) ->
    App.environment = options.environment
  
  App.addRegions
    headerRegion: "#l-header"
    mainRegion:    "#l-content-main-wrap"
    footerRegion: "#l-footer"
  
  App.rootRoute = Routes.root_path()
  
  App.reqres.setHandler "default:region", ->
    App.mainRegion
  
  App.commands.setHandler "register:instance", (instance, id) ->
    App.register instance, id if App.environment is "development"
  
  App.commands.setHandler "unregister:instance", (instance, id) ->
    App.unregister instance, id if App.environment is "development"
  

  App.addInitializer ->
    header_app = App.module("HeaderApp")

    @listenTo header_app, 'start', => 
      App.module("Auth").start()

    header_app.start()
    App.module("FooterApp").start()


  App.on "initialize:after", ->
    
    #TODO: don't remove this until everything loaded
    $('#l-preloader').hide()

    @startHistory()
    @navigate(@rootRoute, trigger: true) unless @getCurrentRoute()

    shared = new App.Shared.SharedController
      region: new Backbone.Marionette.Region
        el: $("body")


  App