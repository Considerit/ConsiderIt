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
    $.get Routes.get_avatars_path(), (data) ->
      $('head').append data

    $(document).on "click", "a[href^='/']", (event) ->
      href = $(event.target).attr('href')
      target = $(event.target).attr('target')

      if target == '_blank' || href == '/newrelic'  || $(event.target).data('remote') # || href[1..9] == 'dashboard'
        return true

      # Allow shift+click for new tabs, etc.
      if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
        event.preventDefault()
        # Instruct Backbone to trigger routing events
        App.navigate(href, { trigger : true })
        return false

    nav_app = App.module 'NavApp'

    header_app = App.module "HeaderApp"

    @listenTo header_app, 'start', => 
      App.module("Auth").start()

    header_app.start()
    App.module("FooterApp").start()

    theme_app = App.module 'Theme'

    static_app = App.module 'Static'

  App.on "initialize:after", ->
    
    $('#l-preloader').hide()

    @startHistory()
    @navigate(@rootRoute, trigger: true) unless @getCurrentRoute()

    shared = new App.Shared.SharedController
      region: new Backbone.Marionette.Region
        el: $("#t-bg")

  App