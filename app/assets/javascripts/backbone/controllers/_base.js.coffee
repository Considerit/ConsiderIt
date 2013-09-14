@ConsiderIt.module "Controllers", (Controllers, App, Backbone, Marionette, $, _) ->
  
  class Controllers.Base extends Marionette.Controller
    controllers : []

    constructor: (options = {}) ->
      @region = options.region or App.request "default:region"
      super options
      @_instance_id = _.uniqueId("controller")

      # console.log 'adding controller:', @

      App.execute "register:instance", @, @_instance_id
      
      if 'parent_controller' of options
        options.parent_controller.addController @

    close: (args...) ->
      # console.log "removing Controller:", @

      while @controllers.length > 0
        c = @controllers.pop()
        c.close()

      delete @region
      delete @options
      super args
      App.execute "unregister:instance", @, @_instance_id
    
    show: (view) ->
      @listenTo view, "close", @close
      @region.show view

    addController : (controllers) ->
      controllers = _.compact [controllers]
      @controllers = @controllers.concat controllers
