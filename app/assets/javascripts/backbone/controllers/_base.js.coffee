@ConsiderIt.module "Controllers", (Controllers, App, Backbone, Marionette, $, _) ->
  
  class Controllers.Base extends Marionette.Controller
    controllers : []

    constructor: (options = {}) ->
      @options = options
      @region = options.region or App.request "default:region"
      super options
      @_instance_id = _.uniqueId("controller")

      #console.log 'adding controller:', @

      App.execute "register:instance", @, @_instance_id
      
      if 'parent_controller' of options
        options.parent_controller.addController @

    close: (args...) ->
      #console.log "removing Controller:", @

      while @controllers.length > 0
        c = @controllers.pop()
        c.close()

      #@region.close() if @region
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

    removeController : (controller) ->
      @controllers = _.without @controllers, controller

    removeFromParent : ->
      @options.parent_controller.removeController @


    upRoot : ->
      @removeFromParent @
      @detached_el = $(@region.el).detach()

    plant : (region, new_parent = null) ->
      new_parent.addController @ if new_parent
      @region = region
      @detached_el.appendTo region.$el

  class Controllers.StatefulController extends Controllers.Base
    state : null
    prior_state : null

    initialize : (options = {}) ->
      @prior_state = options.prior_state if 'prior_state' of options
      @setState options.parent_state

      @listenTo options.parent_controller, 'state:changed', (state) =>
        @changeState state

    changeState : (new_parent_state) ->
      @setState new_parent_state
      @prepareForStateChange()
      @layout.setDataState @state
      @processStateChange()

      @trigger 'state:changed', @state

    setState : (new_parent_state) ->
      new_state = @state_map()[new_parent_state]

      if @state != new_state
        @prior_state = @state if @state != null  
        @state = new_state

    # convenience method for common action
    resetLayout : (layout) ->
      layout.close()
      layout = @getLayout()
      @setupLayout layout
      @region.show layout
      layout

    prepareForStateChange : ->

    processStateChange : ->
