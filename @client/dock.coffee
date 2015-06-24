

####
# Dock
#
# A component that wraps around another component and enables it
# to stick (dock) to the top of the screen. 
# 
# Only works in browsers that support CSS3 transforms (i.e. IE9+)
#
# This component does: 
#   - Assign the correct position to the element given the scroll 
#     position, desired starting and stopping docking locations,
#     while respecting the stacking order of all other docked 
#     components. 
#   - Use the best positioning method for mobile or desktop
#   - Insert a placeholder of the height of the component when it 
#     docks if necessary, to prevent jerks as the 
#     component is taken out of the normal layout flow
#   - Implement the docking protocol outlined at 
#     http://stackoverflow.com/questions/18358816
#
# This component does NOT yet:
#   - allow for docking to anything but the top
#   - allow you to override default z-index for stacking components
#     which is problematic if you have sticky components that are 
#     designed to overlap. 
#
# You can use this component by:
#
#     Dock
#       key: 'my-dock'
#       ComponentToDoc
#         key: 'my-docked-component'
#
# Props (all optional): 
#
#   key (default = local key)
#     Where docked state & y position is stored.
#
#   docked_key
#     Additional key where docked state should be written. We provide 
#     both key and docked_key because some components change shape when 
#     they become docked, but it becomes performance bottleneck if those
#     components get rerendered every scroll when the y-position stored
#     at key gets updated. 
#
#   start (default = initial y-position of docking element)
#     Can be a 
#       1. Callback that gives the y-position where docking should start. 
#          A callback may be used because docking may be dynamic given a 
#          container that may itself be moving. 
#       2. An offset that will be added to the default start location
#
#   stop (default = Infinity)
#     A callback in the same vein as start, except it should return the 
#     y-position where docking should end. 
#
#   dockable
#     Callback for determining whether this component is eligible for docking. 
#     Useful if there is some other important external state that dictates
#     dockability. 
#
#   constraints (default = [])
#     An array of keys of other docks. These docked components
#     will be treated as a single docked component.
#
#   dock_on_zoomed_screens (default = true)
#     Whether to dock this component if on a zoomed or small screen. 
#
#   skip_jut (default = false)
#     Sometimes you want absolutely positioned children to count toward the
#     top/height calculation of a docking component...sometimes not. This is an 
#     ugly prop and I'd like to solve it more elegantly. 

require './browser_hacks' # for access to browser object
require './shared'

cassowary = require './vendor/cassowary'

window.Dock = ReactiveComponent
  displayName: 'Dock'

  render : -> 
    dock = fetch @key

    if dock.docked
      [x, y] = [dock.x, dock.y]

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
          height: if dock.docked then @local.placeholder_height else 0
      
      # The dockable content
      DIV ref: 'dock_child', style: css.crossbrowserify(style or {}),
        @props.children

  componentWillMount : ->

    @key = if @props.key? then @props.key else @local.key
    dock = fetch @key,
      docked: false
      y: undefined
      x: undefined
    save dock

  componentDidMount : -> 

    # Register this dock with dockingStation. Send dockingStation a callback that it 
    # can invoke to learn about this dock when making calculations. 

    $el = $(@refs.dock_child.getDOMNode()).children(':visible')

    # The stacking order of this dock. Used to determine 
    # how docking components stack up. The initial y position seems to be 
    # a good determiner of stacking order. Perhaps a scenario 
    # in the future will crop up where this is untrue.
    @local.stack_priority = $el.offset().top
    # If the docking element isn't already absolutely or fixed positioned, 
    # then when we dock the element and take it out of normal flow, the 
    # screen is jerked. So we store the component's height to be assigned 
    # to a placeholder we drop in when docked.  
    placeholder_height = if $el[0].style.position in ['absolute', 'fixed'] 
                           0 
                         else 
                           $el.outerHeight()

    @local.placeholder_height = placeholder_height
    save @local

    element_height = jut_above = jut_below = last_dom = null    
    # For caching results of realDimensions (see below)
    serializer = new XMLSerializer()

    dockingStation.register @key, => 
      # This callback is invoked each time the dock is laid out by dockingStation.
      #
      # We can't use $el.height() to determine the height of the docking
      # component because there may be absolutely positioned elements
      # inside $el that we need to account for. For example, a Slider.    
      # We therefore need to recursively compute the real bounds of this
      # element with realDimensions. 
      #
      # Calls to realDimensions are quite expensive, however, so we try to 
      # avoid it as much as possible by caching a serialized version of 
      # the entire docked element to determine whether we need to rerun 
      # realDimensions. This proves to work quite well in practice
      # as the docked element changes rarely compared to the 
      # frequency of scroll events. 

      $el = $(@refs.dock_child.getDOMNode()).children(':visible')
      current_dom = serializer.serializeToString($el[0]) + @props.skip_jut

      if current_dom != last_dom

        [element_height, jut_above, jut_below] = if !@props.skip_jut 
                                                   realDimensions($el) 
                                                 else 
                                                   [$el.height(), 0, 0]
        last_dom = current_dom
      
      return {
        start         : if _.isFunction(@props.start) 
                          @props.start() 
                        else 
                          $(@getDOMNode()).offset().top + (@props.start || 0)
        stop          : @props.stop?() or Infinity
        dock_on_zoom  : if @props.dock_on_zoomed_screens?
                          @props.dock_on_zoomed_screens 
                        else 
                          true
        skip_docking  : @props.dockable && !@props.dockable()
        stack_priority: @local.stack_priority
        jut_above     : jut_above
        height        : element_height
        constraints   : @props.constraints or []
        docked_key    : @props.docked_key
        offset_parent : if browser.is_mobile then $(@getDOMNode()).offsetParent().offset().top 
      }

  componentWillUnmount : -> 
    dockingStation.unregister @key



####
# dockingStation
#
# The dockingStation updates on scroll and resize the docked state and location of 
# all registered docks. 
#
# The dockingStation will update the state(bus) of the docks so that 
# they know if they're docked and where they should position.

# For console output: 
debug = false

dockingStation =

  ####
  # Internal state
  registry: {} 
          # all registered docks, by key
  listening_to_scroll_events : false
          # whether dockingStation is bound to scroll event
  
  component_history: {}
          # caches component location info at t, t-1, and time of docking 
          # for use in calculations
  viewport: {}
          # caches viewport information at t and t-1 for use in calculations
  
  #######
  # register & unregister
  # Enters or removes a ScrollComponent into/from the registry. 
  # Make sure we're listening to scroll event only if there is 
  # at least one registered dock. 
  register : (key, info_callback) -> 
    dockingStation.registry[key] = info_callback
    dockingStation.component_history[key] = {previous: {}, on_dock: {}}

    if !dockingStation.listening_to_scroll_events
      
      $(window).on "scroll.dockingStation", -> dockingStation.user_scrolled = true
      $(window).on "resize.dockingStation", dockingStation.onResize

      # If the height of a docked component changes, we need to recalculate
      # the layout. Unfortunately, it is non-trivial and error prone to detect 
      # when the height of an element changes, so we'll just check periodically. 
      dockingStation.check_resize_interval = setInterval dockingStation.onCheckStickyResize, 500

      dockingStation.listening_to_scroll_events = true

      # Recompute layout if we've seen a scroll in past X ms
      dockingStation.interval = setInterval -> 
        if dockingStation.user_scrolled
          dockingStation.user_scrolled = false
          dockingStation.onScroll()
      , 100 

  unregister : (key) -> 
    delete dockingStation.registry[key]
    if _.keys(dockingStation.registry).length == 0
      $(window).off ".dockingStation"
      dockingStation.listening_to_scroll_events = false
      clearInterval dockingStation.check_resize_interval
      dockingStation.check_resize_interval = null
      clearInterval dockingStation.interval
      dockingStation.interval = null

  #######
  # onScroll
  onScroll : -> 
    dockingStation.updateViewport()

    # At most we will shift the docked components by the distance scrolled
    max_change = if dockingStation.viewport.last.top?
                   Math.abs(dockingStation.viewport.top - dockingStation.viewport.last.top)
                 else
                   Infinity

    dockingStation.layout max_change

  #######
  # onResize
  onResize : -> 
    dockingStation.updateViewport()

    # Shift the docked components by at most the change in window height
    max_change = Math.abs(dockingStation.viewport.height - dockingStation.viewport.last.height)
    dockingStation.layout max_change

  #######
  # onCheckStickyResize
  onCheckStickyResize : -> 
    

    for own k,v of dockingStation.registry
      dock = fetch k

      if dock.docked && v().height != dockingStation.component_history[k].previous.height
        height_change = v().height - dockingStation.component_history[k].previous.height

        console.log "HEIGHT RESIZE at most #{height_change}" if debug
        dockingStation.layout Math.abs(height_change)
        break


  #######
  # updateViewport()
  updateViewport : -> 
    dockingStation.viewport =  
      last: 
        top: dockingStation.viewport.top
        height: dockingStation.viewport.height
      top: document.documentElement.scrollTop || document.body.scrollTop
      height: Math.max(document.documentElement.clientHeight, window.innerHeight || 0)



  #######
  # layout
  #
  # Orchestrates which components are docked or undocked. 
  # Calculates y values for each docked component using a
  # linear constraint solver. 
  layout : (max_change) ->

    # The registered docks with updated context values
    docks = {}
    for own k,v of dockingStation.registry
      docks[k] = v()
      docks[k].key = k

    # Figure out which components are docked
    [docked, undocked, y_stack] = dockingStation.determineIfDocked docks

    # undock components that were docked
    for k in undocked
      if fetch(k).docked
        dockingStation.toggleDocked k, docks[k]

    if docked.length > 0
      # Calculate y-positions for all docked components
      y_pos = dockingStation.solveForY docked, docks, max_change

      for k in docked
        dock = fetch k
        dockingStation.component_history[k].previous = _.extend docks[k], 
                                                    calculated_y: y_pos[k].value

        [x, y] = dockingStation.adjustForDevice y_pos[k].value, docks[k]
        if dock.y != y || dock.x != x
          console.log "UPDATING #{dock.key}" if debug
          dock.y = y
          dock.x = x
          if !dock.docked
            dockingStation.toggleDocked k, docks[k]
          
          save dock

      docks = fetch('docking_station')
      if docks.y_stack != y_stack
        docks.y_stack = y_stack
        save docks


  #######
  # determineIfDocked
  #
  # Helper method for layout that returns which docking components should 
  # be docked and which are undocked.  
  determineIfDocked : (docks) -> 
    docked = []; undocked = []

    # Whether the screen is zoomed or quite small 
    zoomed_or_small = window.innerWidth / $(window).width() < .95 || screen.width <= 700

    # Sort by stacking order. Stacking order based on the 
    # y position when the component was mounted. 
    sorted = _.sortBy(_.values(docks), (v) -> v.stack_priority)

    y_stack = 0
    for v in sorted

      if v.skip_docking || (!v.dock_on_zoom && zoomed_or_small)
        is_docked = false 
      else
        dimensions =  if fetch(v.key).docked
                        dockingStation.component_history[v.key].on_dock
                      else 
                        {height: v.height, jut_above: v.jut_above}

        is_docked = dockingStation.viewport.top + y_stack + dimensions.jut_above >= v.start

      if is_docked
        y_stack += dimensions.height
        docked.push v.key
      else
        undocked.push v.key

    [docked, undocked, y_stack]

  ########
  # toggleDocked
  #
  # Helper method for layout that updates a component's 
  # docked state. Manage external docked state if a component 
  # has defined one. 
  toggleDocked : (k, v) ->
    dock = fetch k
    is_docked = !dock.docked
    dock.docked = is_docked
    if !is_docked
      dock.y = dock.x = null
      dockingStation.component_history[k].previous = {}
    else
      dockingStation.component_history[k].on_dock = v

    save dock

    if v.docked_key?
      external_docked = fetch(v.docked_key)
      external_docked.docked = is_docked
      save external_docked

    console.log "Toggled #{k} to #{dock.docked}" if debug

  #######
  # solveForY
  #
  # Helper method for layout that returns optimal y positions for
  # each docked component. Optimal placement facilitated by the definition
  # of linear constraints which are then processed by the cassowary constraint 
  # solver.
  #
  # Different constraints may need to be introduced to accommodate different
  # docking configurations.   
  #
  # max_change constrains how far each docking element is allowed to move
  # since the last time it was laid out. 
  solveForY : (docked, docks, max_change) -> 
    c = cassowary

    # cassowary constraint solver
    solver = new c.SimplexSolver()    

    # We modify the contraints slightly based on whether we're scrolling up or down
    scroll_distance = Math.abs(dockingStation.viewport.top - dockingStation.viewport.last.top)
    if scroll_distance > 0
      dockingStation.scrolling_down = dockingStation.viewport.top > dockingStation.viewport.last.top


    console.log("viewport height: ", dockingStation.viewport.height) if debug
    # We'll iterate through each component in order of their stacking priority
    y_stack = 0

    sorted = (v for own k,v of docks when k in docked)
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
    # Add any declared constraints between different docks, constraining
    # the one higher in the stacking order to always be above and non-overlapping 
    # the one lower in the stacking order, preferring them to be right up against
    # each other.
    #        y1(t) + height <= y2(t)   (required)
    #        y1(t) + height  = y2(t)   (strong)


    for v, i in sorted
      console.log "**#{v.key} constraints**" if debug
      k = v.key; dock = fetch k
      previous_calculated_y = dockingStation.component_history[k].previous.calculated_y

      # START
      console.log "\tSTART: #{k} >= #{v.start}, strong" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], c.GEQ, v.start, c.Strength.strong

      if v.stop != Infinity
        # STOP
        console.log "\tSTOP: #{k} <= #{v.stop} - #{v.height}, strong" if debug
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

      # TOP OF COMPONENT VISIBLE
      # Try to keep it at or below the viewport, especially when scrolling up
      console.log """\tTOP OF COMPONENT VISIBLE: 
                          #{k} >= #{dockingStation.viewport.top} + #{v.jut_above} + #{y_stack}, 
                          #{if dockingStation.scrolling_down then 'weak' else 'medium'}""" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.GEQ, \
        dockingStation.viewport.top + v.jut_above + y_stack, \
        if dockingStation.scrolling_down then c.Strength.weak else c.Strength.medium
      y_stack += v.height

      # BOTTOM OF COMPONENT VISIBLE
      # Try to keep the bottom above the viewport, especially when scrolling down
      console.log """\tBOTTOM OF COMPONENT VISIBLE: 
                         #{k} + #{v.height} <= #{dockingStation.viewport.top} + #{dockingStation.viewport.height}, 
                         #{if dockingStation.scrolling_down then 'medium' else 'weak'}""" if debug
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.LEQ, \
        dockingStation.viewport.top + dockingStation.viewport.height - v.height, \
        if dockingStation.scrolling_down then c.Strength.medium else c.Strength.weak

      # RELATIONAL
      for sv, j in sorted
        sk = sv.key
        if j < i && sk in v.constraints
          console.log """\tRELATIONAL: 
                         #{k} >= #{sk} + #{sv.height} + #{v.jut_above} - #{sv.jut_above}}, required""" if debug
          
          solver.addConstraint new c.Inequality \
                                y_pos[k], \
                                c.GEQ, \
                                c.plus(y_pos[sk], sv.height + v.jut_above - sv.jut_above), \
                                c.Strength.required

          solver.addConstraint new c.Equation \
                                y_pos[k], \
                                c.plus(y_pos[sk], sv.height + v.jut_above - sv.jut_above), \
                                c.Strength.strong


    solver.resolve()

    if debug
      for own k,v of y_pos
        console.info "#{k}: #{v.value}"

    y_pos

  ####
  # adjustForDevice
  #
  # Calculates x & y offset values based on the positioning
  # method used for the particular device. 
  #
  # On desktop we can safely use the more efficient and less jerky fixed 
  # positioning. 
  #
  # But for mobile, we use absolute positioning because fixed positioning
  # doesn't work in conjunction with touch based zooming. 
  #  - http://remysharp.com/2012/05/24/issues-with-position-fixed-scrolling-on-ios#position-drift. 
  #  - https://developer.apple.com/library/safari/technotes/tn2010/tn2262/_index.html 
  #    ("4. Modify code that relies on CSS fixed positioning")
  #  - http://www.quirksmode.org/blog/archives/2010/12/the_fifth_posit.html

  adjustForDevice : (y, v) ->
    if browser.is_mobile
      # When absolutely positioning, the reference is with respect to the closest
      # parent that has been positioned. Because dock.y is with respect to the 
      # document, we need to adjust for the parent offset.   
      y -= v.offset_parent
      x = 0
    else
      # Fixed positioning is relative to the viewport, not the document
      y -= dockingStation.viewport.top 

      # Adjust for horizontal scroll for fixed position elements because they don't 
      # move with the rest of the content (they're fixed to the viewport). 
      # ScrollLeft is used to offset the fixed element to simulate docking to the window.
      x = -$(window).scrollLeft()

    [x,y]


  initialize : -> 
    dockingStation.updateViewport()

dockingStation.initialize()

#####
# realDimensions
#
# Calculates an element's true height by accounting for all 
# absolutely positioned child elements. Also returns
# The jut of child elements above and below $el.height()
#
# This method is expensive, use it sparingly.
realDimensions = ($el) -> 
  tar = $el.is('.opinion_region')
  recurse = ($e, min_top, max_top) -> 
    
    t = $e.offset().top
    h = $e.height()

    return [min_top, max_top] if h == 0 ||
                                 $e[0].style.display == 'none'
                              # skip elements that don't take up space

    if min_top > t
      min_top = t
    if t + h > max_top
      max_top = t + h

    for child in $e.children()
      [min_top, max_top] = recurse($(child), min_top, max_top)

    [min_top, max_top]

  [min_top, max_top] = recurse $el, Infinity, 0

  offset = $el.offset().top
  jut_above = offset - min_top
  jut_below = max_top - (offset + $el.height())

  [max_top - min_top, jut_above, jut_below]
