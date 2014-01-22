@ConsiderIt = do (Backbone, Marionette) ->
  
  App = new Marionette.Application

  App.on "initialize:before", (options) ->
    App.environment = options.environment
  
  App.addRegions
    headerRegion: "#l-header"
    mainRegion:    "#l-content-main-wrap"
    footerRegion: "#l-footer"
    stickyFooterRegion : '#l-sticky-footer-region'
  
  App.rootRoute = Routes.root_path()
  
  App.reqres.setHandler "default:region", ->
    App.mainRegion
  
  App.commands.setHandler "register:instance", (instance, id) ->
    App.register instance, id if App.environment is "development"
  
  App.commands.setHandler "unregister:instance", (instance, id) ->
    App.unregister instance, id if App.environment is "development"

  window.onerror = (msg, url, line, column, error_obj) ->


    trace = if error_obj? then error_obj.stack else null # works in chrome for now

    attrs = ['javascript', msg, url, line].join()
    if window.xx_last_js_error != attrs
      App.vent.trigger 'javascript:error', 'js', trace, msg, window.location.pathname, line
      window.xx_last_js_error = attrs

    suppress_errors = true
    # If you return true, then error alerts (like in older versions of Internet Explorer) will be suppressed.
    return suppress_errors

  $( document ).ajaxError (event, jqxhr, settings, exception) ->
    attrs = ['ajax', exception, settings.url, settings.type].join()

    console.log exception
    if window.xx_last_ajax_error != attrs
      App.vent.trigger 'javascript:error', 'ajax', settings.data, exception, settings.url, settings.type
      window.xx_last_ajax_error = attrs

  
  App.addInitializer ->
    $.get Routes.get_avatars_path(), (data) ->
      $('head').append data

    $(document).on "click", "a[href^='/']", (event) ->
      href = $(event.currentTarget).attr('href')
      target = $(event.currentTarget).attr('target')

      if target == '_blank' || href == '/newrelic'  || $(event.currentTarget).data('remote') # || href[1..9] == 'dashboard'
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

    App.vent.trigger 'App:Initialization:Complete'


  App