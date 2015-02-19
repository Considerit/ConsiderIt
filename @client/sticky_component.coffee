####
# StickyComponent
#
# A component that wraps around another component and enables it
# to stick to the top of the screen. 
# 
# Only works in browsers that support CSS3 transforms (i.e. IE9+)
#
# This component will: 
#   - assign the correct position to the element given the scroll 
#     position, desired starting and stopping docking locations,
#     while respecting the stacking order of all other sticky 
#     components. 
#   - use the best positioning for mobile or desktop
#   - drop a placeholder of the height of the component when it 
#     enters sticky state if necessary, to prevent jerks as the 
#     component is taken out of the normal layout flow
#   - implements sticking protocol outlined at 
#     http://stackoverflow.com/questions/18358816
#
# This component will NOT yet:
#   - allow for sticking to anything but the top
#
# Props (all optional): 
#
#   key (default = local key)
#     Where stuck state & y position is stored.
#
#   stuck_key
#     Additional key where stuck state should be written. We provide 
#     both key and stuck_key because some components change shape when 
#     they become stuck, but it becomes performance bottleneck if those
#     components get rerendered every scroll when the y-position stored
#     at key gets updated. 
#
#   start (default = initial y-position of sticky element)
#     Callback that gives the y-position where docking should start. 
#     A callback is used because docking may be dynamic given a 
#     container that may itself be moving. 
#
#   stop (default = Infinity)
#     Same as start, except the y-position where docking should end. 
#
#   stickable
#     Callback for determining whether this component is eligible for sticking. 
#     Useful if there is some other important external state that dictates
#     stickability. 
#
#   constraints (default = [])
#     An array of keys of other sticky components. These sticky components
#     will then never overlap each other. 
#
#   stick_on_zoomed_screens (default = true)
#     Whether to stick this component if on a zoomed or small screen. 

window.StickyComponent = ReactiveComponent
  displayName: 'StickyComponent'

  render : -> 
    sticky = fetch @key
    if sticky.stuck
      [x, y] = [sticky.x, sticky.y]
      positioning_method = if browser.is_mobile then 'absolute' else 'fixed'

      style = 
        top: 0
        position: positioning_method
        WebkitBackfaceVisibility: "hidden"
        transform: "translate(#{x}px, #{y}px)"
        zIndex: 999999 - @local.stack_priority
        width: '100%'
        
    @transferPropsTo DIV null,

      # A placeholder for content that suddenly got ripped out of the standard layout
      DIV 
        style: 
          height: if sticky.stuck then @local.placeholder_height else 0
      
      # The stickable content
      DIV ref: 'stuck', style: css.crossbrowserify(style or {}),
        @props.children

  componentWillMount : ->
    @key = if @props.key? then @props.key else @local.key
    sticky = fetch @key,
      stuck: false
      y: undefined
      x: undefined
    save sticky

  componentDidMount : -> 
    # Register this sticky with docker. 
    # Send docker a callback that it can invoke
    # to learn about this sticky component when 
    # making calculations. 

    $el = $(@refs.stuck.getDOMNode()).children()


    # The stacking order of this sticky component. Used to determine 
    # how sticky components stack up. The initial y position seems to be 
    # a good determiner of which sticky stack order. Perhaps a scenario 
    # in the future will crop up where this is untrue.
    @local.stack_priority = $el.offset().top
    save @local

    element_height = jut_above = jut_below = last_dom = null    
    # For caching results of realDimensions (see below)
    serializer = new XMLSerializer()

    docker.register @key, => 
      # This callback is invoked each scroll event handled by docker
      # in order to get data about this sticky component. 

      # We can't use $el.height() to determine the height of the sticky
      # component because there may be absolutely positioned elements
      # inside $el that we need to account for. For example, a Slider.    
      # We therefore need to recursively compute the real bounds of this
      # element with realDimensions. 
      #
      # Calls to realDimensions are quite expensive, however, so we try to 
      # avoid it as much as possible by caching a serialized version of 
      # the entire stuck element to determine whether we need to rerun 
      # realDimensions. This proves to work quite well in practice
      # as the stuck element rarely changes in comparison to the 
      # frequency of scroll events. 
      current_dom = serializer.serializeToString $el[0]

      if current_dom != last_dom
        [element_height, jut_above, jut_below] = realDimensions($el)
        last_dom = current_dom

        # If the sticky component is wrapping an element that isn't already 
        # absolutely or fixed positioned, then when we dock the element 
        # and take it out of normal flow, the screen is jerked. So we 
        # store the component's height to be assigned to a placeholder we
        # drop in when docked.  
        placeholder_height = if $el[0].style.position in ['absolute', 'fixed'] 
                                0 
                             else 
                               $el.height()
        if @local.placeholder_height != placeholder_height
          @local.placeholder_height = placeholder_height
          save @local
          
      return {
        start         : @props.start?() or $(@getDOMNode()).offset().top
        stop          : @props.stop?() or Infinity
        stick_on_zoom : if @props.stick_on_zoomed_screens? then @props.stick_on_zoomed_screens else true
        skip_stick    : @props.stickable && !@props.stickable()
        stack_priority: @local.stack_priority
        jut_above     : jut_above
        height        : element_height
        constraints   : @props.constraints or []
        stuck_key     : @props.stuck_key
        offset_parent : if browser.is_mobile then $(@getDOMNode()).offsetParent().offset().top 
      }


  componentWillUnmount : -> 
    docker.unregister @key



####
# docker
#
# The docker updates on scroll the stuck state and location of 
# all registered sticky components. 
#
# The docker will update the state(bus) of individual sticky 
# components so that they know how to render. 

# For console output: 
debug = true

docker =

  ####
  # Internal state
  registry: {} 
          # all registered sticky components, by key
  listening_to_scroll_events : false
          # whether docker is bound to scroll event
  
  component_history: {}
          # caches component location info at t, t-1, and time of docking 
          # for use in calculations
  viewport: {}
          # caches viewport information at t and t-1 for use in calculations
  
  #######
  # register & unregister
  # Enters or removes a ScrollComponent into/from the registry. 
  # Make sure we're listening to scroll event only if there is 
  # at least one registered sticky component. 
  register : (key, info_callback) -> 
    docker.registry[key] = info_callback
    docker.component_history[key] = {previous: {}, at_stick: {}}

    if !docker.listening_to_scroll_events
      
      $(window).on "scroll.docker", docker.onScroll
      $(window).on "resize.docker", docker.onResize

      # If the height of a stuck component changes, we need to recalculate
      # the layout. Unfortunately, it is non-trivial and error prone to detect 
      # when the height of an element changes, so we'll just check periodically. 
      docker.interval = setInterval docker.onCheckStickyResize, 500

      docker.listening_to_scroll_events = true


  unregister : (key) -> 
    delete docker.registry[key]
    if _.keys(docker.registry).length == 0
      $(window).off ".docker"
      docker.listening_to_scroll_events = false
      clearInterval docker.interval
      docker.interval = null

  #######
  # onScroll
  onScroll : -> 
    docker.updateViewport()

    # At most we will shift the sticky elements by the distance scrolled
    max_change = if docker.viewport.last.top?
                   Math.abs(docker.viewport.top - docker.viewport.last.top)
                 else
                   Infinity

    docker.layout max_change

  #######
  # onResize
  onResize : -> 
    docker.updateViewport()

    # Shift the sticky elements by at most the change in window height
    max_change = Math.abs(docker.viewport.height - docker.viewport.last.height)
    docker.layout max_change

  #######
  # onCheckStickyResize
  onCheckStickyResize : -> 
    height_changes = 0

    for own k,v of docker.registry
      sticky = fetch k
      if sticky.stuck && v().height != docker.component_history[k].previous.height
        console.error "HEIGHT RESIZE at most #{height_changes}" if debug
        docker.layout Infinity
        break


  #######
  # updateViewport()
  updateViewport : -> 
    docker.viewport =  
      last: 
        top: docker.viewport.top
        height: docker.viewport.height
      top: document.documentElement.scrollTop || document.body.scrollTop
      height: Math.max(document.documentElement.clientHeight, window.innerHeight || 0)



  #######
  # layout
  #
  # Orchestrates which components are stuck or unstuck. 
  # Calculates y values for each stuck component using a
  # linear constraint solver. 
  layout : (max_change) ->
    # The registered stickies with updated context values
    stickies = {}
    for own k,v of docker.registry
      stickies[k] = v()
      stickies[k].key = k

    # Figure out which components are docked
    [stuck, unstuck] = docker.determineIfStuck stickies

    # unstick components that were docked
    for k in unstuck
      if fetch(k).stuck
        docker.toggleStuck k, stickies[k]

    if stuck.length > 0
      # Calculate y-positions for all stuck components
      y_pos = docker.solveForY stuck, stickies, max_change

      for k in stuck
        sticky = fetch k
        docker.component_history[k].previous = _.extend stickies[k], 
                                                    calculated_y: y_pos[k].value

        [x, y] = docker.adjustForDevice y_pos[k].value, stickies[k]
        if sticky.y != y || sticky.x != x
          console.log "UPDATING #{sticky.key}" if debug
          sticky.y = y
          sticky.x = x
          if !sticky.stuck
            docker.toggleStuck k, stickies[k]
          
          save sticky


  #######
  # determineIfStuck
  #
  # Helper method for layout that separates the sticky components
  # into the keys of those which should now be stuck and those that
  # shouldn't.  
  determineIfStuck : (stickies) -> 
    stuck = []; unstuck = []

    # Whether the screen is zoomed or quite small 
    zoomed_or_small = window.innerWidth / $(window).width() < .95 || screen.width <= 700

    # Sort by stacking order. Stacking order based on the 
    # y position when the component was mounted. 
    sorted = _.sortBy(_.values(stickies), (v) -> v.stack_priority)

    y_stack = 0
    for v in sorted

      if v.skip_stick || (!v.stick_on_zoom && zoomed_or_small)
        is_stuck = false 
      else
        dimensions =  if fetch(v.key).stuck
                        docker.component_history[v.key].at_stick
                      else 
                        {height: v.height, jut_above: v.jut_above}

        is_stuck = docker.viewport.top + y_stack + dimensions.jut_above >= v.start

      if is_stuck
        y_stack += dimensions.height
        stuck.push v.key
      else
        unstuck.push v.key

    [stuck, unstuck]

  ########
  # toggleStuck
  #
  # Helper method for layout that updates a component's 
  # stuck state. Manage external stuck state if a component 
  # has defined one. 
  toggleStuck : (k, v) ->
    sticky = fetch k
    is_stuck = !sticky.stuck
    sticky.stuck = is_stuck
    if !is_stuck
      sticky.y = sticky.x = null
      docker.component_history[k].previous = {}
    else
      docker.component_history[k].at_stick = v

    save sticky

    if v.stuck_key?
      external_stuck = fetch(v.stuck_key)
      external_stuck.stuck = is_stuck
      save external_stuck

    console.log "Toggled #{k} to #{sticky.stuck}" if debug

  #######
  # solveForY
  #
  # Helper method for layout that returns optimal y positions for
  # each stuck component. Optimal placement facilitated by the definition
  # of linear constraints which are then processed by the cassowary constraint 
  # solver.
  #
  # Different constraints may need to be introduced to accommodate different
  # sticky component configurations.   
  #
  # max_change constrains how far each sticky component is allowed to move
  # since the last time it was laid out. 
  solveForY : (stuck, stickies, max_change) -> 
    
    # cassowary constraint solver
    solver = new c.SimplexSolver()    

    # We modify the contraints slightly based on whether we're scrolling up or down
    scroll_distance = Math.abs(docker.viewport.top - docker.viewport.last.top)
    if scroll_distance > 0
      docker.scrolling_down = docker.viewport.top > docker.viewport.last.top


    console.log("viewport height: ", docker.viewport.height) if debug
    # We'll iterate through each component in order of their stacking priority
    y_stack = 0

    sorted = (v for own k,v of stickies when k in stuck)
    sorted = _.sortBy( sorted, (v) -> v.stack_priority)

    # Stores the variables representing each component's y-position 
    # that the cassowary will optimize. 
    y_pos = {}
    for v in sorted
      y_pos[v.key] = new c.Variable

    ########
    # Linear constraints
    #
    # Set the constraints for the y-position of each docked component. 
    #
    # y(t) is the y-position of this component at time t. 
    # v(t) is the viewport top at time t
    #
    # START (strength = strong)
    # The component shouldn't be placed above its specified docking start location.
    #        y(t) >= start
    #
    # STOP (strength = strong)
    # The component shouldn't be placed below its specified docking stopping location.
    #        y(t) + height <= stop
    #    
    # BOUNDED BY MAX CHANGE (strength = strong)
    # If this component has previously been positioned, the change in position
    # should be bound by this amount (usually the scroll distance)
    #       |y(t) - y(t-1)| <= max_change
    #       |y(t) - y(t-1)| <= |v(t) - v(t-1)|  <-- usually scroll distance
    #
    # CLOSE TO TOP (strength = weak)
    # Prefer being close to the top of the viewport. In the future, if we need
    # to support components preferring to be stuck to bottom, we'd need to 
    # conditionally set the component's edge preference. 
    #        y(t) = v(t)
    #
    # TOP OF COMPONENT VISIBLE (strength = variable)
    # Try to keep y(t) at or below the viewport to be seen. In order to 
    # implement the scheme described at http://stackoverflow.com/questions/18358816, 
    # we weaken the strength of this constraint when scrolling down and strengthen 
    # it when scrolling up. 
    #        y(t) >= v(t) + sum of heights of components higher in stack
    #
    # BOTTOM OF COMPONENT VISIBLE (strength = variable)
    # Like the previous constraint. Try to keep the bottom of the component in
    # the viewport so it can be seen. We increase the strength of this constraint
    # when scrolling down and weaken it when scrolling up.
    #        y(t) + component height <= v(t) + viewport height
    #
    # RELATIONAL
    # Add any declared constraints between different sticky components, constraining
    # the one higher in the stacking order to always be above and non-overlapping 
    # the one lower in the stacking order
    #        y1(t) + height <= y2(t)


    for v, i in sorted
      console.log "**#{v.key} constraints**" if debug
      k = v.key; sticky = fetch k
      previous_calculated_y = docker.component_history[k].previous.calculated_y

      # START
      console.log "\tSTART: #{k} >= #{v.start}, strong" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], c.GEQ, v.start, c.Strength.strong

      # STOP
      console.log "\tSTOP: #{k} <= #{v.stop - (v.height)}, strong" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], c.LEQ, v.stop - v.height, c.Strength.strong

      if max_change? && previous_calculated_y?
        # BOUNDED BY MAX CHANGE (usually scroll distance)
        console.log "\tBOUNDED BY MAX CHANGE: |#{k} - #{previous_calculated_y}| <= #{max_change}, strong" if debug
        solver.addConstraint new c.Inequality \
          y_pos[k], \
          c.LEQ,
          previous_calculated_y + max_change, \
          c.Strength.strong

        solver.addConstraint new c.Inequality \
          y_pos[k], \
          c.GEQ,
          previous_calculated_y - max_change, \
          c.Strength.strong

      # CLOSE TO TOP
      # Prefer being close to the top of the viewport
      console.log "\tCLOSE TO TOP: #{k} = #{docker.viewport.top}, weak" if debug
      solver.addConstraint new c.Equation \
        y_pos[k], docker.viewport.top, c.Strength.weak

      # TOP OF COMPONENT VISIBLE
      # Try to keep it at or below the viewport, especially when scrolling up
      console.log "\tTOP OF COMPONENT VISIBLE: #{k} >= #{docker.viewport.top} + #{v.jut_above} + #{y_stack}, #{if docker.scrolling_down then 'weak' else 'medium'}" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.GEQ, \
        docker.viewport.top + v.jut_above + y_stack, \
        if docker.scrolling_down then c.Strength.weak else c.Strength.medium
      y_stack += v.height

      # BOTTOM OF COMPONENT VISIBLE
      # Try to keep the bottom above the viewport, especially when scrolling down
      console.log "\tBOTTOM OF COMPONENT VISIBLE: #{k} + #{v.height} <= #{docker.viewport.top} + #{docker.viewport.height}, #{if docker.scrolling_down then 'medium' else 'weak'}" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.LEQ, \
        docker.viewport.top + docker.viewport.height - v.height, \
        if docker.scrolling_down then c.Strength.medium else c.Strength.weak

      # RELATIONAL
      for sv, j in sorted
        sk = sv.key
        if j < i && sk in v.constraints
          console.log "\tRELATIONAL: #{k} >= #{sk} + #{sv.height} + #{v.jut_above} - #{sv.jut_above}}, required" if debug
          
          solver.addConstraint new c.Inequality \
                                y_pos[k], \
                                c.GEQ, \
                                c.plus(y_pos[sk], sv.height + v.jut_above - sv.jut_above), \
                                c.Strength.required


    solver.resolve()

    if debug
      for own k,v of y_pos
        console.info "#{k}: #{v.value}"

    y_pos

  ####
  # adjustForDevice
  #
  # Calculates x & y sticky component values based on the positioning
  # method used for the particular device. 
  #
  # On desktop we can safely use the more efficient fixed positioning. 
  # But for mobile, we use absolute positioning because mobile devices 
  # have terrible support for fixed positioning. 
  adjustForDevice : (y, v) ->
    if browser.is_mobile
      # When absolutely positioning, the reference is with respect to the closest
      # parent that has been positioned. Because sticky.y is with respect to the 
      # document, we need to adjust for the parent offset.   
      y -= v.offset_parent
      x = 0
    else
      # Fixed positioning is relative to the viewport, not the document
      y -= docker.viewport.top 

      # Adjust for horizontal scroll for fixed position elements because they don't 
      # move with the rest of the content (they're fixed to the viewport). 
      # ScrollLeft is used to offset the fixed element to simulate sticking to the window.
      x = -$(window).scrollLeft()

    [x,y]


  initialize : -> 
    docker.updateViewport()

docker.initialize()

#####
# realDimensions
#
# Calculates an element's true height by accounting for all 
# absolutely positioned child elements. Also returns
# The jut of child elements above and below $el.height()
#
# This method is expensive, use it sparingly.
realDimensions = ($el) -> 

  recurse = ($e, min_top, max_top) -> 
    t = $e.offset().top
    h = $e.height()
    if min_top > t
      min_top = t
    if t + h > max_top
      max_top = t + h

    for c in $e.children()
      [min_top, max_top] = recurse($(c), min_top, max_top)

    [min_top, max_top]

  [min_top, max_top] = recurse $el, Infinity, 0

  offset = $el.offset().top
  jut_above = offset - min_top
  jut_below = max_top - (offset + $el.height())
  [max_top - min_top, jut_above, jut_below]
