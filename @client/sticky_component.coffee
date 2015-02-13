####
# Implements scheme described at http://stackoverflow.com/questions/18358816/sticky-sidebar-stick-to-bottom-when-scrolling-down-top-when-scrolling-up 
# Only works in browsers that support CSS3 transforms (i.e. IE9+)
#
# Useful reference: http://www.quirksmode.org/mobile/viewports.html
#
# Stores its top & bottom at sticky-{id}
#
# Registers itself at stuck-stickies
#
# set props.parent_key if you want the parent to know when 
# we're in sticky mode
#
# TODO: redesign state

total = 0

####
# stickies
#
# Global registry of sticky components
# Sticky components can consult the registry to 
# figure out how they need to adjust to make run
# for other sticky components. 

window.stickies =
  registry: {}
  last_viewport_top : 0
  responding_to_scroll : false

  register : (key, info_callback) -> 
    stickies.registry[key] = info_callback

    if !stickies.responding_to_scroll
      $(window).on "scroll.stickies", stickies.onScroll
      stickies.responding_to_scroll = true

  unregister : (key) -> 
    delete stickies.registry[key]
    if _.keys(stickies.registry).length == 0
      $(window).off "scroll.stickies"
      stickies.responding_to_scroll = false

  onScroll : (e) -> 

    # s = new Date().getTime()

    # Determine stacking order based on the y position at which 
    # the sticky was mounted. 
    sorted_by_original_y = ( [k, v()] for own k,v of stickies.registry)
    sorted_by_original_y.sort (a,b) -> a.stack_priority - b.stack_priority

    [stuck, unstuck] = stickies.determineIfStuck sorted_by_original_y

    for k in unstuck
      sticky = fetch(k)
      if sticky.stuck
        sticky.stuck = false
        stuck.y = null
        save sticky
        console.log "Toggled #{k} to #{sticky.stuck}"

    if stuck.length > 0
      stuck_with_values = _.filter sorted_by_original_y, (s) -> s[0] in stuck
      y_pos = stickies.calculateYPositions stuck_with_values

      for k in stuck
        sticky = fetch k

        if !sticky.stuck
          sticky.stuck = true
          console.log "Toggled #{@key} to #{sticky.stuck}"

        sticky.y = y_pos[k].value
        save sticky

    viewport_top = document.documentElement.scrollTop || document.body.scrollTop
    stickies.last_viewport_top = viewport_top
    # t = new Date().getTime() - s
    # total += t
    # console.log total, t

  determineIfStuck : (sorted_by_original_y) -> 
    stuck = []; unstuck = []

    viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)    

    # Whether the screen is zoomed or quite small 
    zoomed_or_small = window.innerWidth < $(window).width() || screen.width <= 700

    y_stack = 0
    for [k, v] in sorted_by_original_y

      if v.skip_stick || (!v.stick_on_zoom && zoomed_or_small)
        is_stuck = false 
      else
        is_stuck = viewport_top + y_stack + v.top - v.jut >= v.start

      if is_stuck
        y_stack += v.height + v.top
        stuck.push k
      else
        unstuck.push k

    [stuck, unstuck]

  calculateYPositions : (stuck) -> 
    solver = new c.SimplexSolver()    
    exp = c.Expression

    y_pos = {}

    viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)    
    viewport_height = Math.max(document.documentElement.clientHeight, window.innerHeight || 0)

    scrolling_down = viewport_top > stickies.last_viewport_top


    y_stack = 0

    for [k,v], i in stuck
      # console.log k, v      
      # console.log "**#{k} constraints**"
      y_pos[k] = new c.Variable

      sticky = fetch k

      # If we've already been moving, we should be bounded by the amount scrolled. 
      # |y(t) - y(t-1)| <= |v(t) - v(t-1)|
      if sticky.y?
        scroll_distance = Math.abs(viewport_top - stickies.last_viewport_top)

        # console.log "\tBounded: |#{k} - #{sticky.y}| <= |#{viewport_top} - #{stickies.last_viewport_top}|, strong"
        solver.addConstraint new c.Inequality \
          y_pos[k], \
          c.LEQ,
          sticky.y + scroll_distance, \
          c.Strength.strong

        solver.addConstraint new c.Inequality \
          y_pos[k], \
          c.GEQ,
          sticky.y - scroll_distance, \
          c.Strength.strong


        # console.log "\tBounded: #{k} #{if scrolling_down then '>=' else '<='} #{sticky.y}, weak"
        # solver.addConstraint new c.Inequality \
        #   y_pos[k], \
        #   if scrolling_down then c.GEQ else c.LEQ,
        #   sticky.y, \
        #   c.Strength.weak


      # Try to keep it at or below the viewport, especially when scrolling up
      # console.log "\tBelow top: #{k} >= #{viewport_top} - #{v.jut}, #{c.Strength.medium}"
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.GEQ, \
        viewport_top - v.jut + y_stack, \
        if scrolling_down then c.Strength.weak else c.Strength.medium

      # Get as close to the top of the viewport as possible
      # console.log "\tTo top: #{k} >= #{viewport_top}, weak"
      solver.addConstraint new c.Equation \
        y_pos[k], viewport_top, c.Strength.weak

      # # Try to keep the bottom above the viewport, especially when scrolling down
      # console.log "\tAbove bottom: #{k} + #{v.$el.height() + v.jut} <= #{viewport_top} + #{viewport_height}, #{if scrolling_down then 'weak' else 'medium'}"
      solver.addConstraint new c.Inequality \
        y_pos[k], \
        c.LEQ, \
        viewport_top + viewport_height - (v.height + v.jut), \ #(realDimensions(v.$el)[0] + v.jut), \
        if scrolling_down then c.Strength.medium else c.Strength.weak


      # Endpoint constraints.
      # console.log "\tStart: #{k} >= #{v.start}, required"
      solver.addConstraint new c.Inequality \
        y_pos[k], c.GEQ, v.start

      # console.log "\tStop: #{k} <= #{v.stop - (v.height + v.top)}, required"
      solver.addConstraint new c.Inequality \
        y_pos[k], c.LEQ, v.stop - (v.height + v.top)


      # Relational constraint. Make sure this sticky is stuck below the 
      # others in the stack. 
      # console.log "\tRelational: #{k} >= #{viewport_top} + #{y_stack} + #{v.top} - #{v.jut}}, weak"
      solver.addConstraint new c.Inequality \
                            y_pos[k], \
                            c.GEQ, \
                            viewport_top + y_stack + v.top - v.jut, \
                            c.Strength.weak
      y_stack += v.height + v.top



      # Handle declared relational constraints. 
      for [sk, sv], j in stuck
        if j < i && sk in v.constraints
          # console.log "\tRelational: #{k} >= #{sk} + #{sv.height} + #{sv.top} - #{v.jut} + #{sv.jut}}, required"
          solver.addConstraint new c.Inequality \
                                y_pos[k], \
                                c.GEQ, \
                                c.plus(y_pos[sk], sv.height + sv.top - v.jut + sv.jut), \
                                c.Strength.required

    solver.resolve()

    # if stuck.length > 2
    #   console.log(scrolling_down, y_pos[stuck[2][0]].value, fetch(stuck[2][0]).y)

    # for own k,v of y_pos
    #   console.info "#{k}: #{v.value}"

    y_pos


####
# StickyComponent
#
# Makes the child component sticky.
#
# ...
# 

window.StickyComponent = ReactiveComponent
  displayName: 'StickyComponent'

  render : -> 

    # intialize
    if !@key

      # Give the option of using a key that the parent
      # knows about so that its sticky state can be used
      # elsewhere. 
      @key = if @props.key? then @props.key else @local.key

      sticky = fetch @key,
        stuck: false
        y: 0

      save sticky


    sticky = fetch @key

    if sticky.stuck

      [x, y] = [0, sticky.y]

      if browser.is_mobile
        positioning_method = 'absolute'
      else
        positioning_method = 'fixed'

        # We are using fixed positioning, so we need to offset
        viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)
        y -= viewport_top #+ $(@getDOMNode()).offsetParent().offset().top 

        # Adjust for horizontal scroll for fixed position elements because they don't 
        # move with the rest of the content (they're fixed to the viewport). 
        # ScrollLeft is used to offset the fixed element to simulate sticking to the window.
        x -= $(window).scrollLeft()


      style = 
        position: positioning_method
        top: @props.top_offset or 0
        WebkitBackfaceVisibility: "hidden"
        transform: "translate(#{x}px, #{y}px)"
        zIndex: 999999 - @local.stack_priority
        width: '100%'
        
    else 
      style = {}

    @transferPropsTo DIV {id: @key},

      # A placeholder for content that suddenly got ripped out of the standard layout
      DIV 
        style: 
          height: if sticky.stuck then @local.placeholder_height else 0
      
      # The stickable content
      DIV ref: 'stuck', style: css.crossbrowserify(style),
        @props.children

  componentDidMount : -> 
    $el = $(@refs.stuck.getDOMNode()).children()

    [element_height, element_top] = realDimensions($el)
    jutting = element_top - $el.offset().top

    stickies.register @key, => 
      start         : @props.start?() or $("##{@key}").offset().top
      stop          : @props.stop?() or Infinity
      jut           : 0
      stick_on_zoom :(@props.stick_stick_on_zoomed_screens? && @props.stick_stick_on_zoomed_screens) or true
      skip_stick    : @props.stickable && !@props.stickable()
      top           : @props.top_offset or 0
      bottom        : @props.bottom_offset or 0
      $el           : $el
      stack_priority: @local.stack_priority
      jut           : jutting
      height        : element_height
      constraints   : @props.constraints or []

    @local.placeholder_height = if $el[0].style.position in ['absolute', 'fixed'] then 0 else $el.height()
    @local.stack_priority = $el.offset().top
    save @local
        

  componentWillUnmount : -> 
    stickies.unregister @key



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

  [max_top - min_top, min_top]



  # onScroll : -> 
  #   sticky = fetch @key

  #   should_be_stuck = @determineIfStuck()

  #   if sticky.stuck != should_be_stuck
  #     sticky = fetch @key
  #     sticky.stuck = !sticky.stuck
  #     save sticky
  #     console.log "Toggled #{@key} to #{sticky.stuck}"

  #   @local.last_viewport_top = viewport_top

  #   if sticky.stuck
  #     @local.dimensions_before_stick = [element_height, element_top, jutting]
  #     save @local
  #     updatePosition()
  #   else
  #     save @local

  # determineIfStuck : -> 

  #   is_zoomed = window.innerWidth < $(window).width()

  #   return false if (@props.stickable && !@props.stickable()) ||
  #                   (!@local.stick_stick_on_zoomed_screens && (is_zoomed || screen.width <= 700))

  #   start_sticking_at_y = @props.start?() or $("##{@key}").offset().top
  #   stop_sticking_at_y = @props.stop?() or Infinity

  #   viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)


  #   $el = $(@refs.stuck.getDOMNode()).children()


  #   ######
  #   # TODO: refactor this crap

  #   # Can't use $el.height() because there may be absolutely positioned elements
  #   # inside $el that we need to account for. For example, a Slider.    
  #   [element_height, element_top] = @realDimensions($el) 
  #   # How far absolutely positioned child elements jut above $el      
  #   jutting = element_top - $el.offset().top

  #   if @local.stuck
  #     # Adjust values based on the measurements taken _before_ this element got stuck 
  #     [before_element_height, before_element_top, before_jutting] = @local.dimensions_before_stick
  #     element_top = $el.offset().top - (before_jutting - jutting)
  #     element_height = before_element_height
  #     jutting = before_jutting


  #   viewport_offset = @local.top_offset - jutting

  #   stickies = fetch('stickies')
  #   sticky = fetch @key

  #   for other_sticky in _.filter(stickies.registry, (s) -> s.stuck && s.y_at_mount < sticky.y_at_mount)
  #     # if the other sticky got stuck _above_ this sticky, add its height
  #     other_sticky = fetch other_sticky
  #     viewport_offset += other_sticky.viewport_bottom - other_sticky.viewport_top


  #   return viewport_top + viewport_offset >= start_sticking_at_y


  # updatePosition : -> 
  #   sticky = fetch @key
  #   stickies = fetch 'stickies'

  #   @local.last_viewport_top = viewport_top
  #   save @local





# window.StickyComponent2 = ReactiveComponent
#   displayName: 'StickyComponent'


#   render : -> 


#     if !@local.initialized
#       stickies = fetch('stickies')
#       all_stickies = (s for s in _.union(stickies.unstuck, stickies.stuck))
#       @key = "sticky-0"; i=1
#       while @key in all_stickies
#         @key = "sticky-#{i}"
#         i++
#       stickies.unstuck.push @key
#       save stickies

#       _.defaults @local,
#         initialized: true
#         stuck: false
#         top_offset: @props.top_offset? or 0 #distance from top of viewport to stick top of element
#         bottom_offset: @props.bottom_offset? or 0 #distance from bottom of viewport to stick bottom of element
#         stick_stick_on_zoomed_screens : (@props.stick_stick_on_zoomed_screens? && @props.stick_stick_on_zoomed_screens) or true
#         last_viewport_top : document.documentElement.scrollTop || document.body.scrollTop
#         translate_y: 0
#         translate_x: 0
#       save @local


#     if @local.stuck
#       sticky = fetch @key

#       viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)
#       adjust_to_position_method = if browser.is_mobile then 0 else - viewport_top #- $(@getDOMNode()).offsetParent().offset().top 
#       console.log "adjust_to_position_method: ", @key, sticky.y, adjust_to_position_method, viewport_top, $(@getDOMNode()).offsetParent().offset().top
#       style = 
#         position: if !browser.is_mobile then 'fixed' else 'absolute'
#         top: @local.top_offset
#         WebkitBackfaceVisibility: "hidden"
#         transform: "translate(-#{@local.translate_x}px, #{sticky.y + adjust_to_position_method}px)"
#         zIndex: 9999
#         width: '100%'
#     else 
#       style = {}

#     @transferPropsTo DIV {id: @key},
#       DIV style: {height: if @local.stuck && @local.placeholder_height? then @local.placeholder_height else 0}
       
#       DIV ref: 'stuck', style: css.crossbrowserify(style),
#         @props.children

#   componentDidMount : -> 

#     # attach event listeners
#     $(window).on "scroll.#{@key}", => @updatePosition()
    

#     sticky = fetch @key
#     sticky.y_at_mount = $(@refs.stuck.getDOMNode()).children().offset().top
#     save sticky

#   componentWillUnmount : -> 
#     $(window).off ".#{@key}"
#     stickies = fetch('stickies')
#     stickies.stuck = _.without stickies.stuck, @key
#     stickies.unstuck = _.without stickies.unstuck, @key
#     save stickies

#   toggleStuck : -> 
#     @local.stuck = !@local.stuck
    
#     # update global stickies
#     stickies = fetch('stickies')
#     if @local.stuck
#       stickies.stuck.push @key
#       stickies.unstuck = _.without stickies.unstuck, @key
#     else
#       stickies.unstuck.push @key
#       stickies.stuck = _.without stickies.stuck, @key

#     if @props.parent_key
#       external = fetch(@props.parent_key)
#       external.sticky = @local.stuck
#       save external

#     save @local
#     save stickies

#     console.log "Toggled #{@key} to #{@local.stuck}"




#   updatePosition : -> 

#     stickies = fetch('stickies')


#     $el = $(@refs.stuck.getDOMNode()).children()

#     # Can't use $el.height() because there may be absolutely positioned elements
#     # inside $el that we need to account for. For example, a Slider.    
#     [element_height, element_top] = @realDimensions($el) 
#     # How far absolutely positioned child elements jut above $el      
#     jutting = element_top - $el.offset().top

#     if @local.stuck
#       # Adjust values based on the measurements taken _before_ this element got stuck 
#       [before_element_height, before_element_top, before_jutting] = @local.dimensions_before_stick
#       element_top = $el.offset().top - (before_jutting - jutting)
#       element_height = before_element_height
#       jutting = before_jutting
      
#     viewport_offset = @local.top_offset - jutting

#     for other_sticky in stickies.stuck
#       if other_sticky != sticky.key
#         # if the other sticky got stuck _above_ this sticky, add its height
#         other_sticky = fetch other_sticky

#         if other_sticky.y_at_mount < sticky.y_at_mount || 
#             (other_sticky.y_at_mount == sticky.y_at_mount && sticky.key < other_sticky.key)
#           viewport_offset += other_sticky.viewport_bottom - other_sticky.viewport_top

#     if @props.container_selector
#       $container = $(@props.container_selector)
#       start_sticking_at_y = $container.offset().top 
#       stop_sticking_at_y = start_sticking_at_y + $container.height()
#     else 
#       start_sticking_at_y = @props.start?() or $("##{@key}").offset().top
#       stop_sticking_at_y = @props.stop?() or Infinity

#     viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)

#     effective_viewport_top = viewport_top + viewport_offset

#     is_zoomed = window.innerWidth < $(window).width()
    
#     ######
#     # DETERMINE OUR STICKY STATE
#     # Are we transitioning between being stuck and not being stuck?
#     should_be_stuck = effective_viewport_top >= start_sticking_at_y && 
#                        (@local.stick_stick_on_zoomed_screens || (!is_zoomed && screen.width > 700) ) && 
#                        (!@props.stickable || @props.stickable())

#     if should_be_stuck
#       @local.dimensions_before_stick = [element_height, element_top, jutting]
#       save @local

#     if should_be_stuck != @local.stuck
#       @toggleStuck()

#     # Don't need to do anything if we're not actually stuck
#     if !@local.stuck
#       @local.last_viewport_top = viewport_top
#       save @local
#       return


#     ######
#     # HORIZONTAL ADJUSTMENTS
#     # We need to adjust for any horizontal scroll for fixed position elements because they don't 
#     # move with the rest of the content (they're fixed to the viewport). 
#     # So we'll use scrollLeft to offset the fixed element so it actually is stuck to the window. 
#     translate_x = if !browser.is_mobile then -$(window).scrollLeft() else 0

#     ######
#     # VERTICAL ADJUSTMENTS 

#     element_fits_in_viewport = element_height < (window.innerHeight - viewport_offset)
#     element_bottom = element_top + element_height

#     if element_fits_in_viewport #the common case, often for an empty decision board or the proposal header
#       translate_y = if !browser.is_mobile 
#                       viewport_offset 
#                     else 
#                       viewport_offset + $(window).scrollTop() - $(@getDOMNode()).offsetParent().offset().top

#     else # if element doesn't fit in viewport, such as if you have a really full decision board

#       viewport_bottom = viewport_top + window.innerHeight
#       effective_viewport_bottom = viewport_bottom - @local.bottom_offset

#       is_scrolling_up = viewport_top < @local.last_viewport_top

#       # When scrolling up, simulate sticking to the top of the screen. 
#       if is_scrolling_up
#         if effective_viewport_top <= element_top
#           translate_y = @local.translate_y + (effective_viewport_top - element_top) #adjustment is for scroll flicks
#         else
#           translate_y = @local.translate_y + (@local.last_viewport_top - viewport_top)

#       # When scrolling down, simulate sticking to the bottom of the screen. 
#       else           
#         # if scrolled past the element bottom, we want to stick here
#         if effective_viewport_bottom >= element_bottom  
#           translate_y = @local.translate_y + (effective_viewport_bottom - element_bottom) #adjustment is for scroll flicks

#         # otherwise, we'll simulate scrolling down through this element with negative Y translation
#         else 
#           translate_y = @local.translate_y + (@local.last_viewport_top - viewport_top)

#     # make sure that inertial scroll didn't force us to scroll past the bottom of the container
#     if element_bottom + (translate_y - @local.translate_y) > stop_sticking_at_y
#       translate_y = stop_sticking_at_y - element_bottom + @local.translate_y

#     ####
#     # APPLY THE ADJUSTMENTS to the fixed element
#     if translate_y != @local.translate_y || translate_x != @local.translate_x
#       @local.translate_y = translate_y
#       @local.translate_x = translate_x
#       console.log @key, translate_y

#     @local.last_viewport_top = viewport_top
#     @local.placeholder_height = if $el[0].style.position in ['absolute', 'fixed'] then 0 else $el.height() 
#     save @local

#     sticky.viewport_top = viewport_offset
#     sticky.viewport_bottom = viewport_offset + element_height
#     save sticky


# window.Stickies = ReactiveComponent
#   displayName: 'Stickies'

#   render : -> 
#     fetch('stickies').stuck
#     @update()

#     SPAN null

#   componentDidMount : -> 
#     # attach event listeners
#     # $(window).on "resize.stickies", => @windowResized()
#     $(window).on "scroll.stickies", @update
    
#     # @windowResized()

#   componentWillUnmount : -> 
#     $(window).off ".stickies"

#   # windowResized : -> 
#   #   window.innerHeight = window.innerHeight
#   #   save @local

#   update : -> 
#     stickies = fetch 'stickies'

#     solver = new c.SimplexSolver()    
#     exp = c.Expression

#     y_pos = {}

#     viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)    

#     stickies.stuck.sort (a,b) -> a.y_at_mount - b.y_at_mount

#     for sticky, i in stickies.stuck
#       sticky = fetch sticky

#       console.log "**#{sticky.key} constraints**"
#       y_pos[sticky.key] = new c.Variable


#       # Try to keep it at or below the viewport
#       console.log "\t#{sticky.key} >= #{viewport_top}, strong"
#       solver.addConstraint new c.Inequality \
#         y_pos[sticky.key], c.GEQ, viewport_top, c.Strength.medium

#       # Get as close to the viewport as possible
#       console.log "\t#{sticky.key} >= #{viewport_top}, weak"
#       solver.addConstraint new c.Equation \
#         y_pos[sticky.key], viewport_top, c.Strength.weak

#       # Endpoint constraints.
#       console.log "\t#{sticky.key} >= #{sticky.start}, required"
#       solver.addConstraint new c.Inequality \
#         y_pos[sticky.key], c.GEQ, sticky.start

#       console.log "\t#{sticky.key} <= #{sticky.stop - (sticky.viewport_bottom - sticky.viewport_top)}, required"
#       solver.addConstraint new c.Inequality \
#         y_pos[sticky.key], c.LEQ, sticky.stop - (sticky.viewport_bottom - sticky.viewport_top)

#       # Relational constraints. 
#       for stacked_sticky, j in stickies.stuck
#         if j < i
#           stacked_sticky = fetch stacked_sticky
#           console.log "\t#{sticky.key} >= #{stacked_sticky.key} + #{stacked_sticky.viewport_bottom - stacked_sticky.viewport_top}, required"
#           solver.addConstraint new c.Inequality \
#                                 y_pos[sticky.key], \
#                                 c.GEQ, \
#                                 c.plus(y_pos[stacked_sticky.key], stacked_sticky.viewport_bottom - stacked_sticky.viewport_top)

#     solver.resolve()

#     for own k,v of y_pos
#       console.info "#{k}: #{v.value}"
#       sticky = fetch(k)
#       if sticky.y != v.value
#         sticky.y = v.value
#         save sticky






