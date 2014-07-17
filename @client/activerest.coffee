##
# ActiveREST
#
# Key/value data store. Use fetch to get data stored at a key; save adds an object to the cache
#
# • Components are automatically registered to be updated whenever a particular property of an 
#   object stored in the cache changes (see the full list of dependencies by inspecting the 
#   global "data_dependencies" in your console)
# • Save will trigger a render on all components that depend on the data that was just
#   modified (and NO components that didn't depend on the changed data will be rendered)
# • Save will batch the components to be rerendered in order to not trigger wasteful renders
# • Save handles routing (when Application.page changes). Routing needs to be examined in depth. 
# • When initializing ActiveREST, the programmer can specify routes/server endpoints that can
#   be used to fetch data from the server. The options specify a regex key (like a route) 
#   that maps to a callback method for GETs and for POSTs. Currently, ActiveREST uses these 
#   options to determine when to fetch data from the server by matching a key against the 
#   regex keys on the routes option. 



class ActiveRESTCache
  _cache : {} #all the data
  _routes_loaded : {} #keys that have already been fetched from server

  constructor : (options) -> @options = _.defaults options, {routes : {}}

  fetch : (key) -> 

    endpoint = @_endpoint(key)

    if endpoint && !(key of @_routes_loaded)
      # If there is a server endpoint for this key, fetch the data,
      # and save it in the cache. 
      # Assumes that the success callbacks provided by client
      # will return list of key, object pairs to be stored in 
      # the cache. 
      # TODO: handle summary vs full datasets

      @_routes_loaded[key] = true

      $.ajax
        url: "/#{key}"
        dataType: 'json'
        success: (data) =>
          if endpoint.get && endpoint.get.success
            data_to_save = endpoint.get.success(key, data)
            for [ar_key, ar_obj] in data_to_save
              @save ar_key, ar_obj, _.keys(ar_obj)
            
        error : (xhr, status, err) ->
          if endpoint.get && endpoint.get.error
            endpoint.get.error xhr, status, err
          else 
            console.error "Error fetching #{key}: #{err}"
      return if key of @_cache then @_cache[key] else {}

    else if key of @_cache
      return @_cache[key]

    else
      return undefined

  # Tries to identify a server endpoint for this key
  _endpoint : (key) ->
    for endpoint in _.keys(@options.routes)
      regex = new RegExp endpoint, "g"
      if regex.test key
        return @options.routes[endpoint]
    return false

  # ##########
  # Saving data into activeREST
  # 
  # key: identify this data object
  # value: must be an object
  # changed_props: which props of the object have been changed
  save : (key, value, changed_props = null) -> 
    exists = key of @_cache

    if exists && key == 'application' && @fetch('application').page != value.page
      long_id = @fetch('application').route.split('/')[1]
      route = "/#{long_id}#{if value.page == 'results' then '/results' else ''}"
      app_router.navigate route, {trigger : true}
      @_cache['_route_changed'] = true #nasty, eliminate need for this

    # console.log 'saving', key, value
    if !exists
      @_cache[key] = value
    else
      _.extend @_cache[key], value

    if changed_props
      for changed_item in changed_props 
        @_batched_data_changes["#{key}--#{changed_item}"]=1 

    if !@_render_scheduled
      #wait a few millis for other changes to come down the pipe before rerendering
      @_render_scheduled = true
      _.delay => 
        @_render_scheduled = false

        # console.log "RE-RENDERING #{@_componentsToUpdate().length} components because of changes to #{ _.keys(@_batched_data_changes)}"
        components_to_update = @_componentsToUpdate()
        for component in components_to_update
          component._dirty = true

        for component in components_to_update
          if component._lifeCycleState != 'UNMOUNTED'
            # use @setState instead of forceUpdate so that React's 
            # lifecycle methods get called for the component
            component.setState {dirty: true}

        @_cache['_route_changed'] = false #nasty, eliminate need for this
        @_batched_data_changes = {}
      , @_BATCH_TIMEOUT

  # time to wait for additional calls to save before rerendering
  _BATCH_TIMEOUT : 50 
  # whether there is a pending rerender
  _render_scheduled : false 
  # all of the changed props whose dependent components will have to be rerendered
  _batched_data_changes : {}

  # Builds list of components that need to be rerendered given all the 
  # data that's been changed since last render
  _componentsToUpdate : ->
    components = []
    for dependency_key in _.keys @_batched_data_changes
      if dependency_key of @_data_dependencies
        components = components.concat _.values @_data_dependencies[dependency_key]
    _.uniq(components)


  # Registry of data dependencies
  # Maps from key-item to map of component keys to the component
  _data_dependencies : {}
  registerDataDependency : (key, item, component_key, component) -> 
    key = "#{key}--#{item}"
    if !(key of @_data_dependencies)
      @_data_dependencies[key] = {}
    @_data_dependencies[key][component_key] = component


  #Gets a unique id when saving a new item. This method is total hack for now. 
  getUniqueID : (key_prefix) -> 
    id = -1
    while ActiveREST.fetch "#{key_prefix}/#{id}" 
      id = -(Math.floor(Math.random() * 999999) + 1)
    id


window.ActiveRESTCache = ActiveRESTCache


## #########################
# ReActiveREST 
#
# Wrapper React Component class that integrates with ActiveREST. 
#
# • Provides an @data object that can get/set ActiveREST cache objects. 
# • Defaults to providing this component's activeREST data, the key of 
#   which is determined based on upon the component's name and the key 
#   specified by the React programmer. 
# • Registers the data dependencies of this component based on the 
#   data that it accesses. 
# • Implements strong shouldComponentUpdate that is managed by ActiveREST
# • The programmer defines a getDefaultData method in their Component
#   that must define any UI state stored on that Component

ReactiveComponent = (obj) ->

  _.extend obj,

    _shouldComponentUpdate : (next_props, next_state) -> 
      # console.log 'SHOULD? ', @_activeREST_key, @_dirty
      @_dirty or 
      JSON.stringify([next_state, next_props]) != JSON.stringify([@state, @props])

    _componentWillMount : ->
      @_dirty = false
      @_subscribed_data = {}

      # initialize data stored at this component's ActiveREST key
      @_activeREST_key = 
        "#{obj.displayName.toLowerCase()}#{ if @props.key then '/' + @props.key else ''}"

      data = ActiveREST.fetch @_activeREST_key
      data = {} if !data

      # initialize default data specified by component
      _.defaults data, if @getDefaultData then @getDefaultData() else {}

      ActiveREST.save @_activeREST_key, data
      # console.log 'Initialized', @_activeREST_key, data, ActiveREST.fetch(@_activeREST_key)

    _componentDidUpdate : (prev_props, prev_state) -> 
      @_dirty = false

    # Fetches data at any key in ActiveREST, defaulting to this component's key. 
    # Wraps data with getters and setters for each top-level property on the data. 
    # Registers a dependency for this component for each accessed property. 
    # Getters/setters applied to each property *everytime* @data called...improve.
    data : (key = null) -> 
      key ||= @_activeREST_key

      if !(key of @_subscribed_data)
        @_subscribed_data[key] = {}

      getters_setters = @_subscribed_data[key]

      # Add getters / setters
      # Need to do this every access in case new properties were added 
      # to this key since the last access
      for prop in _.keys ActiveREST.fetch(key)
        if !getters_setters.hasOwnProperty prop
          @_addGetterSetter getters_setters, prop, key, @

      getters_setters

    # Adds a getter and setter for the given property
    _addGetterSetter : (getters_setters, prop, key, component) => 
      Object.defineProperty getters_setters, prop,
        get : -> 
          # console.log 'Getting', component._activeREST_key, prop, ActiveREST.fetch key       
          ActiveREST.registerDataDependency(key, prop, component._activeREST_key, component)
          data = ActiveREST.fetch key
          data[prop]
        set : (value) -> 
          # console.log 'Setting', prop, key, value
          data = ActiveREST.fetch key
          updated_data = $.extend true, {}, data
          updated_data[prop] = value
          ActiveREST.save key, updated_data, [prop]


  # Wrap React methods with (re)ActiveREST functionality.
  to_wrap = 'render componentWillMount componentDidMount componentWillUpdate componentDidUpdate shouldComponentUpdate getInitialState getDefaultProps'.split(' ')
  wrap = (name) ->
    old_method = obj[name];

    obj[name] = () ->

      switch name

        when 'componentWillMount'
          @_componentWillMount arguments...

        when 'componentDidUpdate'
          @_componentDidUpdate arguments...

        when 'shouldComponentUpdate'
          @_shouldComponentUpdate arguments...

      if old_method then (old_method.bind(this))(arguments...) else {}

  wrap name for name in to_wrap
  ##


  React.createClass obj


window.ReactiveComponent = ReactiveComponent

