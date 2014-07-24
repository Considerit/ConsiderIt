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
      #console.log "removing Controller:"
        
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

    # extracts this controller (and its attached DOM) from its parent
    upRoot : ->
      @removeFromParent @
      @detached_el = $(@region.el).detach()

    # re-attaches this controller's DOM to a new region.
    # upRoot must have been called before plant
    plant : (region, new_parent = null) ->
      throw 'Has no detached element to plant!!' if !@detached_el
      new_parent.addController @ if new_parent
      @region = region
      @detached_el.appendTo region.$el
      @detached_el = null

  class Controllers.StatefulController extends Controllers.Base
    state : null
    prior_state : null
    transitions_enabled : false
    
    transition_speed : -> 
      $transition_speed = if Modernizr.csstransitions then 1000 else 0
      $transition_speed    

    initialize : (options = {}) ->
      @prior_state = options.prior_state if 'prior_state' of options
      @setState options.parent_state

      @listenTo options.parent_controller, 'state:changed', (state) =>
        @changeState state

    changeState : (new_parent_state) ->
      if @transitions_enabled
        @layout.enterTransition()
        App.vent.trigger 'transition:start'
        _.delay =>
          @layout.exitTransition()
          App.vent.trigger 'transition:end'
        , @transition_speed() + 5

      _.delay => # the delay is to get around a strange issue where the state was transitioning too fast
        @setState new_parent_state
        @prepareForStateChange()
        @layout.setDataState @state


        @stateWasChanged()

        @trigger 'state:changed', @state
      , 5

    setState : (new_parent_state) ->

      new_state = new_parent_state

      #if @state != new_state
      @prior_state = @state if @state != null  
      @state = new_state

    # convenience method for common action
    resetLayout : (layout) ->
      #layout.close()
      layout = @getLayout()
      @setupLayout layout
      @region.show layout
      layout

    prepareForStateChange : ->

    stateWasChanged : ->
