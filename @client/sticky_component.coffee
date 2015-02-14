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
#     Where stuck state & y position is pre_stick_dimensions.
#
#   stuck_key
#     Additional key where stuck state should be written. We provide 
#     both key and stuck_key because some components change shape when 
#     they become stuck, but it becomes performance bottleneck if those
#     components get rerendered every scroll when the y-position pre_stick_dimensions
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

    if !@key
      @key = if @props.key? then @props.key else @local.key
      sticky = fetch @key,
        stuck: false
        y: undefined
        x: undefined
      save sticky

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

  componentDidMount : -> 
    # Register this sticky with scroller. 
    # Send scroller a callback that it can invoke
    # to learn about this sticky component when 
    # making calculations. 

    $el = $(@refs.stuck.getDOMNode()).children()
    [element_height, jut_above, jut_below] = realDimensions($el)

    # For caching results of realDimensions (see below)
    serializer = new XMLSerializer()
    last_dom = null

    t1 = t2 = 0
    scroller.register @key, => 
      # This callback is invoked each scroll event handled by scroller
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

    # If the sticky component is wrapping an element that isn't already 
    # absolutely or fixed positioned, then when we enter sticky state 
    # and take it out of normal flow, the screen is jerked. So we 
    # store the component's height to be assigned to a placeholder we
    # drop in when docked.  
    @local.placeholder_height = if $el[0].style.position in ['absolute', 'fixed'] 
                                  0 
                                else 
                                  $el.height()

    # The stacking order of this sticky component. Used to determine 
    # how sticky components stack up. The initial y position seems to be 
    # a good determiner of which sticky stack order. Perhaps a scenario 
    # in the future will crop up where this is untrue.
    @local.stack_priority = $el.offset().top
    save @local

  componentWillUnmount : -> 
    scroller.unregister @key



####
# scroller
#
# The scroller updates on scroll the stuck state and location of 
# all registered sticky components. 
#
# The scroller will update the state(bus) of individual sticky 
# components so that they know how to render. 

# For console output: 
debug = true

scroller =

  ####
  # Internal state
  registry: {} 
          # all registered sticky components, by key
  responding_to_scroll : false
          # whether scroller is bound to scroll event
  viewport_top : document.documentElement.scrollTop || document.body.scrollTop  
  last_viewport_top : document.documentElement.scrollTop || document.body.scrollTop
          # caches scroll positions at t and t-1 for use in calculations
  
  last_positions : {}
  pre_stick_dimensions : {}

  #######
  # register & unregister
  # Enters or removes a ScrollComponent into/from the registry. 
  # Make sure we're listening to scroll event only if there is 
  # at least one registered sticky component. 
  register : (key, info_callback) -> 
    scroller.registry[key] = info_callback

    if !scroller.responding_to_scroll
      $(window).on "scroll.scroller", scroller.onScroll
      $(window).on "resize.scroller", scroller.onScroll
      scroller.responding_to_scroll = true

  unregister : (key) -> 
    delete scroller.registry[key]
    if _.keys(scroller.registry).length == 0
      $(window).off ".scroller"
      scroller.responding_to_scroll = false

  #######
  # onScroll
  #
  # Orchestrates which components are stuck or unstuck. 
  # Calculates y values for each stuck component using a
  # linear constraint solver. 
  onScroll : (e) -> 
    scroller.viewport_top = document.documentElement.scrollTop || document.body.scrollTop

    # The registered stickies with updated context values
    stickies = {}
    for own k,v of scroller.registry
      stickies[k] = v()
      stickies[k].key = k

    # Figure out which components are docked
    [stuck, unstuck] = scroller.determineIfStuck stickies


    # unstick components that were docked
    for k in unstuck
      if fetch(k).stuck
        scroller.toggleStuck k, stickies[k]

    if stuck.length > 0
      # Calculate y-positions for all stuck components
      y_pos = scroller.solveForY stuck, stickies

      for k in stuck
        sticky = fetch k
        scroller.last_positions[k] = y_pos[k].value
        [x, y] = scroller.adjustForDevice y_pos[k].value, stickies[k]
        if sticky.y != y || sticky.x != x
          sticky.y = y
          sticky.x = x
          if !sticky.stuck
            scroller.toggleStuck k, stickies[k]
          
          save sticky

    scroller.last_viewport_top = scroller.viewport_top


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
      y -= scroller.viewport_top 

      # Adjust for horizontal scroll for fixed position elements because they don't 
      # move with the rest of the content (they're fixed to the viewport). 
      # ScrollLeft is used to offset the fixed element to simulate sticking to the window.
      x = -$(window).scrollLeft()

    [x,y]


  ########
  # toggleStuck
  #
  # Helper method for onScroll that updates a component's 
  # stuck state. Manage external stuck state if a component 
  # has defined one. 
  toggleStuck : (k, v) ->
    sticky = fetch k
    is_stuck = !sticky.stuck
    sticky.stuck = is_stuck
    if !is_stuck
      sticky.y = sticky.x = null
      delete scroller.last_positions[k]
    else
      scroller.pre_stick_dimensions[k] = [v.height, v.jut_above, v.jut_below]
    save sticky

    if v.stuck_key?
      external_stuck = fetch(v.stuck_key)
      external_stuck.stuck = is_stuck
      save external_stuck

    console.log "Toggled #{k} to #{sticky.stuck}" if debug

  #######
  # determineIfStuck
  #
  # Helper method for onScroll that separates the sticky components
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
        [height, jut_above, jut_below] = if v.key of scroller.pre_stick_dimensions 
                                           scroller.pre_stick_dimensions[v.key] 
                                         else 
                                           [v.height, v.jut_above, v.jut_below]

        is_stuck = scroller.viewport_top + y_stack + jut_above >= v.start

      if is_stuck
        y_stack += height
        stuck.push v.key
      else
        unstuck.push v.key

    [stuck, unstuck]

  #######
  # solveForY
  #
  # Helper method for onScroll that returns optimal y positions for
  # each stuck component. Optimal placement facilitated by the definition
  # of linear constraints which are then processed by the cassowary constraint 
  # solver.
  #
  # Different constraints may need to be introduced to accommodate different
  # sticky component configurations.   
  solveForY : (stuck, stickies) -> 
    
    # cassowary constraint solver
    solver = new c.SimplexSolver()    

    # We modify the contraints slightly based on whether we're scrolling up or down
    scrolling_down = scroller.viewport_top > scroller.last_viewport_top
    scroll_distance = Math.abs(scroller.viewport_top - scroller.last_viewport_top)

    viewport_height = Math.max(document.documentElement.clientHeight, window.innerHeight || 0)

    console.log("viewport height: ", viewport_height) if debug
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
    # START
    # The component shouldn't be placed above its specified docking start location.
    #        y(t) >= start
    #
    # STOP
    # The component shouldn't be placed below its specified docking stopping location.
    #        y(t) + height <= stop
    #    
    # BOUNDED BY SCROLL DISTANCE (strength = strong)
    # If this component has previously been positioned, the change in position
    # should be bound by the scroll distance. 
    #       |y(t) - y(t-1)| <= |v(t) - v(t-1)|
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

      # START
      console.log "\tSTART: #{k} >= #{v.start}, required" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], c.GEQ, v.start

      # STOP
      console.log "\tSTOP: #{k} <= #{v.stop - (v.height)}, required" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], c.LEQ, v.stop - v.height

      if sticky.y?
        # BOUNDED BY SCROLL DISTANCE
        console.log "\tBOUNDED BY SCROLL DISTANCE: |#{k} - #{scroller.last_positions[k]}| <= |#{scroller.viewport_top} - #{scroller.last_viewport_top}|, strong" if debug
        solver.addConstraint new c.Inequality \
          y_pos[k], \
          c.LEQ,
          scroller.last_positions[k] + scroll_distance, \
          c.Strength.strong

        solver.addConstraint new c.Inequality \
          y_pos[k], \
          c.GEQ,
          scroller.last_positions[k] - scroll_distance, \
          c.Strength.strong

      # CLOSE TO TOP
      # Prefer being close to the top of the viewport
      console.log "\tCLOSE TO TOP: #{k} = #{scroller.viewport_top}, weak" if debug
      solver.addConstraint new c.Equation \
        y_pos[k], scroller.viewport_top, c.Strength.weak

      # TOP OF COMPONENT VISIBLE
      # Try to keep it at or below the viewport, especially when scrolling up
      console.log "\tTOP OF COMPONENT VISIBLE: #{k} >= #{scroller.viewport_top} + #{v.jut_above} + #{y_stack}, #{if scrolling_down then 'weak' else 'medium'}" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.GEQ, \
        scroller.viewport_top + v.jut_above + y_stack, \
        if scrolling_down then c.Strength.weak else c.Strength.medium
      y_stack += v.height

      # BOTTOM OF COMPONENT VISIBLE
      # Try to keep the bottom above the viewport, especially when scrolling down
      console.log "\tBOTTOM OF COMPONENT VISIBLE: #{k} + #{v.height} - #{v.jut_above} <= #{scroller.viewport_top} + #{viewport_height}, #{if scrolling_down then 'medium' else 'weak'}" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.LEQ, \
        scroller.viewport_top + viewport_height - (v.height - v.jut_above), 
        if scrolling_down then c.Strength.required else c.Strength.weak

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
