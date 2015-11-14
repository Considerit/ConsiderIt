require './browser_hacks'

##
# Histogram
#
# Controls the display of the users arranged on a histogram. 
# 
# The user avatars are arranged imprecisely on the histogram
# based on the user's opinion, using a physics simulation. 
#
# The pros and cons can be filtered to specific opinion regions
# (individual and collective). 
#
# TODO: 
#   - is it correct to store selected_opinion, selected_opinions, 
#     highlighted_users at the histogram's key? 
#   - reconsider how "selection" is incorporated. Selection seems 
#     almost like a mixin. Now it is baked in, with the option to
#     opt out if necessary, but the code wouldn't be very nice
#     to work with to extend in a different direction other than
#     selection. 
#
##
# Props
# 
#   opinions
#     The opinions to show in the histogram. 
#   width, height
#   enable_selection (default = false)
#     Whether users can select opinions segments on the histogram
#   draw_base (default = false)
#     Whether to draw a base with +/- labels. If a slider is attached,
#     don't need the labels.
#   backgrounded (default = false)
#     If backgrounded, the histogram avatars are dimmed, and interactivity
#     disabled. 
#
##
# The interaction rules: 
#
# Selection
#   * Click on a user in the histogram, show that user's opinion:
#      - Filter decision board points to those included by this user
#      - Show a second, larger image of the user and their name in
#         the region between the histogram and decision board
#   * Click an area of the histogram unoccupied by a user, when 
#     not already in selection mode, to enter selection mode:
#      - Show the collective opinions of the users in that region. 
#         Rerank the points in the decision board accordingly.
#   * Move the mouse in histogram when in group selection mode:
#      - selected opinions dynamically updated based on mouse position 
#      - selection region stays entirely within the histogram 
#   * Drag the edges of the region selection top edge to resize the selection
#
# Deselection
#   * If a single user is selected, clicking anywhere outside of that 
#     user's picture in the histogram or opinion area will deselect
#   * If a region is selected, clicking anywhere except within the 
#     decision board will deselect the region.
#
# Note that for mobile, region resizing is disabled, and the selection 
# changes on touch move rather than mousemove.
# 
##
# Selected region background
#   * A selection region background follows the mouse in the histogram if:
#      - we're in group selection mode
#      - we're hovering over the histogram in 
#   * Show a border at the top if in group selection mode
#
# The selection region is imprecise. It defines
# a selection region based on the real values of the users' opinions,
# _not_ the imprecise location of the avatar's position on the 
# histogram. This can cause some confusion as to who will be 
# highlighted. 
#
# Other components can also request that certain users be 
# highlighted in the histogram, though the pros/cons will 
# NOT be filtered as a consequence of the highlighting. 
# This occurs when someone mouses over the inclusion pogs
# for a point. 
#
# State design for histogram:
#
# Global state:
#   selection_opinion
#      If set, an opinion key for an avatar that was clicked
#   selected_opinions
#      Array of opinion keys defining the current set of selected opinions. 
#   selected_opinion_value
#      The opinion value around which the current selection is defined  
#   region_selection_width
#      The width of the opinion selection region. 
#   highlighted_users
#      Users that other components want to have highlighted in the 
#      histogram. In the render, this is intersected with the users whose 
#      opinions are selected to determine which avatars are highlighted. 
#   dragging
#      Whether the user is currently dragging the mouse through the
#      histogram. 
#
# Local state: 
#   simulation_opinion_hash
#      Hash of all opinion stances. Used to determine if the physics
#      simulation needs to be rerun on a rerender.
#   mouse_opinion_value
#      Stores the mapped opinion value of the current mouse position
#      within the histogram. 
#   last_selection_via_drag
#      Whether the last time the selection region moved was done by dragging
#      in the histogram. This is used to resolve a technicality with 
#      the order in which mouseUp and mouseClick events are fired. 
#   avatar_size
#      The base size of the avatars, as determined by the physics 
#      simulation. This piece of state would be local, but it needs
#      to be settable from the physics simulation.
#   mouse_x_of_last_resize
#      Stores last mouse position when in selection area resize mode.

require './vendor/d3.v3.min'
require './shared'

window.Histogram = ReactiveComponent
  displayName : 'Histogram'

  render: -> 
    hist = fetch @props.key

    if !hist.initialized
      _.defaults hist,
        initialized: true
        highlighted_users : null
        # region_selection_width controls the size of the selection region when 
        # hovering over the histogram. It defines the opinion bounds within which 
        # opinions are selected. Opinions = [-1, 1]. region_selection_width is 
        # on this scale. 
        region_selection_width : .25
        selected_opinion : null
        selected_opinions : null 
          # use null instead of [] because an empty selection of []
          # is treated differently than no selection whatsoever
      save hist
      
    avatar_radius = calculateAvatarRadius(@props.width, @props.height, @props.opinions)
    if @local.avatar_size != avatar_radius * 2
      @local.avatar_size = avatar_radius * 2
      save @local

    @props.enable_selection &&= @props.opinions.length > 0

    # Controls the size of the vertical space at the top of 
    # the histogram that gives some space for users to hover over 
    # the most populous areas
    region_selection_vertical_padding = if @props.enable_selection then 30 else 0
    if @local.region_selection_vertical_padding != region_selection_vertical_padding
       @local.region_selection_vertical_padding = region_selection_vertical_padding
       save @local

    # whether to show the shaded opinion selection region in the histogram
    draw_selection_area = @props.enable_selection &&
                            !hist.selected_opinion && 
                            !@props.backgrounded &&
                            (hist.selected_opinions || 
                              (!@local.touched && 
                                @local.mouse_opinion_value && 
                                !@local.hoving_over_avatar))

    histogram_props = 
      className: 'histogram'
      style: css.crossbrowserify
        width: @props.width
        height: @props.height + @local.region_selection_vertical_padding
        position: 'relative'
        borderBottom: if @props.draw_base then '1px solid #999'
        #visibility: if @props.opinions.length == 0 then 'hidden'
        userSelect: 'none'

    if @props.enable_selection
      if !browser.is_mobile
        _.extend histogram_props,
          onClick: @onClick
          onMouseMove: @onMouseMove
          onMouseLeave: @onMouseLeave
          onMouseUp: @onMouseUp
          onMouseDown: @onMouseDown
      else 
        _.extend histogram_props,

          onTouchStart: (ev) => 
            curr_time = new Date().getTime()
            # activation by double tap
            if @local.last_tapped_at && curr_time - @local.last_tapped_at < 300
              ev.preventDefault()
              @local.touched = true
              save @local
              @onClick(ev)
            else 
              @local.last_tapped_at = curr_time
              save @local

          onTouchMove: (ev) => ev.preventDefault(); @onMouseMove(ev)
          onTouchEnd: (ev) => 
            curr_time = new Date().getTime()
            # activation by double tap
            if @local.last_tapped_at && curr_time - @local.last_tapped_at < 300          
              ev.preventDefault()
              @onMouseUp(ev)
            else 
              @local.last_tapped_at = curr_time
              save @local

          onTouchCancel: (ev) => ev.preventDefault(); @onMouseUp(ev)

    DIV histogram_props, 

      if @props.draw_base
        @drawHistogramBase()

      if @props.enable_selection
        # A little padding at the top to give some space for selecting
        # opinion regions with lots of people stacked high      
        DIV style: {height: @local.region_selection_vertical_padding}

      # Draw the opinion selection area + region resizing border
      if draw_selection_area
        @drawSelectionArea()

      @drawAvatars()


  drawHistogramBase: -> 
    [SPAN
      style:
        position: 'absolute'
        left: -21
        bottom: -12
        fontSize: 19
        fontWeight: 500
        color: '#999'
      '–'
    SPAN
      style:
        position: 'absolute'
        right: -21
        bottom: -13
        fontSize: 19
        fontWeight: 500
        color: '#999'
      '+']

  drawSelectionArea: -> 
    hist = fetch @props.key
    anchor = hist.selected_opinion_value or @local.mouse_opinion_value
    left = ((anchor + 1)/2 - hist.region_selection_width/2) * @props.width
    base_width = hist.region_selection_width * @props.width
    selection_width = Math.min( \
                        Math.min(base_width, base_width + left), \
                        @props.width - left)
    selection_left = Math.max 0, left

    DIV null,
      if hist.selected_opinions
        DIV 
          className: 'selection_region_resizer'
          style: 
            borderBottom: "3px solid #{focus_blue}"
            height: 15
            width: selection_width
            position: 'absolute'
            left: selection_left
            top: -15
            cursor: 'col-resize'

      DIV 
        style:
          height: @props.height + @local.region_selection_vertical_padding
          position: 'absolute'
          width: selection_width
          backgroundColor: "rgb(246, 247, 249)"
          cursor: 'pointer'
          left: selection_left
          top: 0

        if !hist.selected_opinions
          DIV
            style: css.crossbrowserify
              fontSize: 12
              textAlign: 'center'
              whiteSpace: 'nowrap'
              marginTop: -18
              userSelect: 'none'
              pointerEvents: 'none'

            t('select_these_opinions')

  drawAvatars: -> 
    hist = fetch @props.key

    # Highlighted users are the users whose avatars are colorized and fully 
    # opaque in the histogram. It is based on the current opinion selection and 
    # the highlighted_users state, which can be manipulated by other components. 
    highlighted_users = hist.highlighted_users
    selected_users = if hist.selected_opinion 
                       [hist.selected_opinion] 
                     else 
                       hist.selected_opinions
    if selected_users
      if highlighted_users
        highlighted_users = _.intersection highlighted_users, \
                                          (fetch(o).user for o in selected_users)
      else 
        highlighted_users = (fetch(o).user for o in selected_users)


    # There are a few avatar styles that might be applied depending on state:
    # 1) Regular, for when no user is selected
    regular_avatar_style =
      width: @local.avatar_size
      height: @local.avatar_size
      position: 'absolute'
      cursor: if @props.enable_selection then 'pointer' else 'auto'

    # 2) The style of a selected avatar
    selected_avatar_style = _.extend {}, regular_avatar_style, 
      zIndex: 9
      backgroundColor: focus_blue
    css.crossbrowserify selected_avatar_style
    # 3) The style of an unselected avatar when some other avatar(s) is selected
    unselected_avatar_style = _.extend {}, regular_avatar_style,  
      opacity: .2
    if !browser.is_mobile
      unselected_avatar_style = css.grayscale _.extend unselected_avatar_style
    # 4) The style of the avatar when the histogram is backgrounded 
    #    (e.g. on the crafting page)
    backgrounded_page_avatar_style = _.extend {}, unselected_avatar_style, 
      opacity: if customization('show_histogram_on_crafting') then .1 else 0.0

    # Draw the avatars in the histogram. Placement will be determined later
    # by the physics sim
    DIV 
      ref: 'histo'
      style: 
        height: @props.height
        position: 'relative'
        top: -1
        cursor: if !@props.backgrounded && 
                    @props.enable_selection then 'pointer'

      for opinion in @props.opinions
        user = opinion.user
        fetch(opinion) # subscribe to changes so physics sim will get rerun...

        if @props.backgrounded
          avatar_style = if fetch('/current_user').user == user 
                           _.extend({}, regular_avatar_style, {opacity: .25}) 
                         else 
                           backgrounded_page_avatar_style
        else if highlighted_users
          if _.contains(highlighted_users, opinion.user)   
            avatar_style = selected_avatar_style
          else
            avatar_style = unselected_avatar_style
        else
          avatar_style = regular_avatar_style

        Avatar 
          key: user
          user: user
          hide_tooltip: @props.backgrounded
          style: avatar_style

  onClick: (ev) -> 

    ev.stopPropagation()
    hist = fetch @props.key

    if @props.backgrounded
      if @props.on_click_when_backgrounded
        @props.on_click_when_backgrounded()

    else
      if ev.type == 'touchstart'
        @local.mouse_opinion_value = @getOpinionValueAtFocus(ev)

      is_clicking_user = ev.target.className.indexOf('avatar') != -1

      if is_clicking_user
        user_key = "/user/" + ev.target.getAttribute('id')
                               .substring(7, ev.target.getAttribute('id').length)
        user_opinion = _.findWhere @props.opinions, {user: user_key}
        is_deselection = hist.selected_opinion == user_opinion.key && 
                          !@local.last_selection_via_drag
        if is_deselection
          hist.selected_opinion = null
        else 
          hist.selected_opinion = user_opinion.key
          hist.selected_opinions = null
      else
        max = hist.selected_opinion_value + hist.region_selection_width
        min = hist.selected_opinion_value - hist.region_selection_width
        is_deselection = \
          hist.selected_opinions && 
           !@local.last_selection_via_drag &&
           (!@local.touched || inRange(@local.mouse_opinion_value, min, max))

        if is_deselection
          hist.selected_opinions = null
          if ev.type == 'touchstart'
            @local.mouse_opinion_value = null
        else
          hist.selected_opinion = null
          hist.selected_opinions = @getOpinionsInCurrentRegion()

      has_selection = hist.selected_opinion || hist.selected_opinions
      hist.selected_opinion_value = if !has_selection 
                                      null 
                                    else if !is_clicking_user 
                                      @local.mouse_opinion_value 
                                    else 
                                      user_opinion.stance
      @local.last_selection_via_drag = false

      save hist
      save @local


  getOpinionValueAtFocus: (ev) -> 
    # Calculate the mouse_opinion_value (the slider value about which we determine
    # the selection region) based on the mouse offset within the histogram element.
    h_x = @getDOMNode().getBoundingClientRect().left + window.pageXOffset
    h_w = @getDOMNode().offsetWidth
    m_x = ev.pageX or ev.touches[0].pageX

    translatePixelXToStance m_x - h_x, h_w

  onMouseMove: (ev) -> 
    return if fetch(namespaced_key('slider', @props.proposal)).is_moving

    if @props.enable_selection && !@props.backgrounded
      hist = fetch @props.key
      ev.stopPropagation()

      # handle drag resizing selection area
      if hist.dragging
        h_w = @getDOMNode().offsetWidth
        mouse_x = ev.pageX
        change_in_selection_region = 2 * (mouse_x - @local.mouse_x_of_last_resize) / h_w
        hist.region_selection_width += change_in_selection_region
        hist.region_selection_width = Math.min( 1, Math.max(.03, \
                                                     hist.region_selection_width))
        @local.mouse_x_of_last_resize = mouse_x
        @local.last_selection_via_drag = true
        save @local
        save hist
      else if $(ev.target).closest('.selection_region_resizer').length == 0
        @local.hoving_over_avatar = ev.target.className.indexOf('avatar') != -1
        @local.mouse_opinion_value = @getOpinionValueAtFocus(ev)

        if @local.mouse_opinion_value + hist.region_selection_width >= 1
          @local.mouse_opinion_value = 1 - hist.region_selection_width
        else if @local.mouse_opinion_value - hist.region_selection_width <= -1
          @local.mouse_opinion_value = -1 + hist.region_selection_width
        
        # dynamic selection on drag
        if hist.selected_opinions &&
            @local.mouse_opinion_value # this last conditional is only for touch
                                       # interactions where there is no mechanism 
                                       # for "leaving" the histogram
          hist.selected_opinions = @getOpinionsInCurrentRegion()
          hist.selected_opinion_value = @local.mouse_opinion_value 
          save hist

        save @local

  onMouseLeave: (ev) -> 
    return if fetch(namespaced_key('slider', @props.proposal)).is_moving
    @local.mouse_opinion_value = null
    save @local

    hist = fetch @props.key
    if hist.dragging
      hist.dragging = false
      save hist


  onMouseUp: (ev) -> 
    return if fetch(namespaced_key('slider', @props.proposal)).is_moving
    hist = fetch @props.key   
    
    if hist.dragging
      hist.dragging = false
      save hist

  onMouseDown: (ev) -> 
    return if fetch(namespaced_key('slider', @props.proposal)).is_moving
    ev.stopPropagation()

    hist = fetch @props.key
    if $(ev.target).closest('.selection_region_resizer').length > 0 && 
        hist.selected_opinions && 
        !@local.touched
      hist.dragging = true
      @local.mouse_x_of_last_resize = ev.pageX
      save hist

    return false 
      # The return false prevents text selections
      # of other parts of the page when dragging
      # the selection region around.

  getOpinionsInCurrentRegion : -> 
    # return the opinions whose stance is within +/- region_selection_width 
    # of the moused over area of the histogram
    hist = fetch @props.key
    all_opinions = @props.opinions || []  
    min = @local.mouse_opinion_value - hist.region_selection_width
    max = @local.mouse_opinion_value + hist.region_selection_width
    selected_opinions = (o.key for o in all_opinions when inRange(o.stance, min, max))
    selected_opinions

  physicsSimulation: ->

    # We only need to rerun the sim if the distribution of stances has changed, 
    # or the width/height of the histogram has changed. We round the stance to two 
    # decimals to avoid more frequent recalculations than necessary (one way 
    # this happens is with the server rounding opinion data differently than 
    # the javascript does when moving one's slider)
    simulation_opinion_hash = JSON.stringify _.map(@props.opinions, (o) => 
      Math.round(fetch(o.key).stance * 100) / 100 )

    simulation_opinion_hash += " (#{@props.width}, #{@props.height}, #{@props.width})"

    if @refs && @refs.histo && simulation_opinion_hash != @local.simulation_opinion_hash
      histo = @refs.histo.getDOMNode()

      icons = histo.childNodes

      if icons.length == @props.opinions.length
        opinions = for opinion, i in @props.opinions
          {stance: opinion.stance, icon: icons[i], radius: icons[i].style.width/2}

        positionAvatars(@props.width, @props.height, opinions, @local.avatar_size / 2)
        
        @local.simulation_opinion_hash = simulation_opinion_hash
        save @local

  componentDidMount: ->     
    @physicsSimulation()

  componentDidUpdate: -> 
    @physicsSimulation()


#####
# Calculate node radius based on the largest density of avatars in an 
# area (based on a moving average of # of opinions, mapped across the
# width and height)

calculateAvatarRadius = (width, height, opinions) -> 

  opinions.sort (a,b) -> a.stance - b.stance

  # first, calculate a moving average of the number of opinions
  # across around all possible stances
  window_size = .1
  avg_inc = .01
  moving_avg = []
  idx = 0
  stance = -1.0
  sum = 0

  while stance <= 1.0

    o = idx
    cnt = 0
    while o < opinions.length

      if opinions[o].stance < stance - window_size
        idx = o
      else if opinions[o].stance > stance + window_size
        break
      else 
        cnt += 1

      o += 1

    moving_avg.push cnt
    stance += avg_inc
    sum += cnt

  # second, calculate the densest area of opinions, operationalized
  # as the region with the most opinions amongst all regions of 
  # opinion space that have contiguous above average opinions. 
  dense_regions = []
  avg_of_moving_avg = sum / moving_avg.length

  current_region = []
  for avg, idx in moving_avg
    reset = idx == moving_avg.length - 1
    if avg >= avg_of_moving_avg
      current_region.push idx
    else
      reset = true

    if reset && current_region.length > 0
      dense_regions.push [current_region[0] * avg_inc - 1.0 - window_size , \
                    idx * avg_inc - 1.0 + window_size ]      
      current_region = []

  max_region = null
  max_opinions = 0
  for region in dense_regions
    cnt = 0
    for o in opinions
      if o.stance >= region[0] && \
         o.stance <= region[1] 
        cnt += 1
    if cnt > max_opinions
      max_opinions = cnt
      max_region = region

  # Third, calculate the avatar radius we'll use. It is based on 
  # trying to fill ratio_filled of the densest area of the histogram
  ratio_filled = .5
  if max_opinions > 0 
    effective_width = width * Math.abs(max_region[0] - max_region[1]) / 2
    area_per_avatar = ratio_filled * effective_width * height / max_opinions
    r = Math.sqrt(area_per_avatar) / 2
  else 
    r = Math.sqrt(width * height / opinions.length * ratio_filled) / 2

  r = Math.min(r, width / 2, height / 2)

  r


######
# Uses a d3-based physics simulation to calculate a reasonable layout
# of avatars within a given area.

positionAvatars = (width, height, opinions, r) ->
  width = width || 400
  height = height || 70

  opinions = opinions.slice()
              .sort( (a,b) -> a.stance-b.stance )
  n = opinions.length
  x_force_mult = 2
  y_force_mult = if height <= 100 then 2 else 6
  ticks = 0

  stances = {}

  # Initialize positions of each node
  nodes = d3.range(opinions.length).map (i) ->
    radius = opinions[i].radius || r

    if parseFloat(opinions[i].icon.style.width) != radius * 2
      opinions[i].icon.style.width = opinions[i].icon.style.height = radius * 2 + 'px'

    x_target = (opinions[i].stance + 1)/2 * width
    

    if stances[x_target]
      if x_target > .99
        x_target -= .01 * Math.random() 
      else if x_target < .01
        x_target += .01 * Math.random() 
      else 
        x_target += .01 * ((Math.random() * 2) - 1)


    opinions[i].x_target = x_target
    stances[x_target] = 1

    # Travis: I'm finding that different initial conditions work 
    # better at different scales.
    #   - Give large numbers of avatars some good initial spacing
    #   - Small numbers of avatars can be more precisely placed for quick 
    #     convergence with little churn  
    x = if opinions.length > 10 then radius + (width - 2 * radius) * (i / n) else opinions[i].x_target
    y = if opinions.length == 1 then height - radius else radius + Math.random() * (height - 2 * radius)

    return {
      index: i, 
      radius: radius,
      x: x,
      y: y
    }

  # Called after the simulation stops
  end = ->
    return 
    total_energy = calculate_global_energy()
    console.log('Simulation complete after ' + ticks + ' ticks. ' + 
                'Energy of system could be reduced by at most ' + total_energy + ' by global sort.')

  # One iteration of the simulation
  tick = (e) ->
    some_node_moved = false

    ####
    # Repel colliding nodes
    # A quadtree helps efficiently detect collisions
    q = d3.geom.quadtree(nodes)

    for n in nodes 
      q.visit collide(n)

    #####
    # Apply standard forces
    for o, i in nodes

      # Push node toward its desired x-position
      o.x += e.alpha * (x_force_mult * width  * .001) * (opinions[o.index].x_target - o.x)

      # Push node downwards
      # The last term accelerates unimpeded falling nodes
      o.y += e.alpha * y_force_mult * Math.max(o.y - o.py + 1, 1)

      # Ensure node is still within the bounding box
      o.x = Math.max(o.radius, Math.min(width  - o.radius, o.x))
      o.y = Math.max(o.radius, Math.min(height - o.radius, o.y))

      # Re-position dom element...if it has moved enough      
      if !opinions[i].icon.style.left || Math.abs( parseFloat(opinions[i].icon.style.left) - (o.x - o.radius)) > .1 
        opinions[i].icon.style.left = o.x - o.radius + 'px'
        some_node_moved = true

      if !opinions[i].icon.style.top || Math.abs( parseFloat(opinions[i].icon.style.top) - (o.y - o.radius)) > .1 
        opinions[i].icon.style.top  = o.y - o.radius + 'px'
        some_node_moved = true

    ticks += 1

    # Complete the simulation if we've reached a steady state
    force.stop() if !some_node_moved

  collide = (node) ->

    return (quad, x1, y1, x2, y2) ->
      if quad.leaf && quad.point && quad.point != node
        dx = node.x - quad.point.x
        dy = node.y - quad.point.y
        dist = Math.sqrt(dx * dx + dy * dy)
        combined_r = node.radius + quad.point.radius

        # Transpose two points in the same neighborhood if it would reduce energy of system
        # 10 is not a principled threshold. 
        if energy_reduced_by_swap(node, quad.point) > 10
          swap_position(node, quad.point)          
          dx *= -1
          dy *= -1

        # repel both points equally in opposite directions if they overlap
        if dist < combined_r
          separate_by = if dist == 0 then 1 else ( dist - combined_r ) / dist
          offset_x = dx * separate_by * .5
          offset_y = dy * separate_by * .5

          node.x -= offset_x
          node.y -= offset_y
          quad.point.x += offset_x
          quad.point.y += offset_y


      # Visit subregions if we could possibly have a collision there
      # Travis: I understand what the 16 *does* but not the significance
      #         of the particular value. Does 16 make sense for all
      #         avatar sizes and sizes of the bounding box?
      neighborhood_radius = node.radius + 16
      nx1 = node.x - neighborhood_radius
      nx2 = node.x + neighborhood_radius
      ny1 = node.y - neighborhood_radius
      ny2 = node.y + neighborhood_radius

      return x1 > nx2 || 
              x2 < nx1 ||
              y1 > ny2 ||
              y2 < ny1

  # Check if system energy would be reduced if two nodes' positions would 
  # be swapped. We square the difference in order to favor large differences 
  # for one vs small differences for the pair.
  energy_reduced_by_swap = (p1, p2) ->
    # how much does each point covet the other's location, over their own?
    p1_jealousy = Math.pow(p1.x - opinions[p1.index].x_target, 2) - \
                  Math.pow(p2.x - opinions[p1.index].x_target, 2)
    p2_jealousy = Math.pow(p2.x - opinions[p2.index].x_target, 2) - \
                  Math.pow(p1.x - opinions[p2.index].x_target, 2)

    p1_jealousy + p2_jealousy

  # Swaps the positions of two nodes
  position_props = ['x', 'y', 'px', 'py']
  swap_position = (p1, p2) ->
    for prop in position_props
      swap = p1[prop]
      p1[prop] = p2[prop]
      p2[prop] = swap

  # see https://github.com/mbostock/d3/wiki/Force-Layout for docs
  force = d3.layout.force()
    .nodes(nodes)
    .on("tick", tick)
    .on('end', end)
    .gravity(0)
    .charge(0)
    .chargeDistance(0)
    .start()

  ######################################################
  # The rest of these methods are only used for testing
  ######################################################


  # Calculates the reduction in global energy that a sort would have, 
  # where global energy is the sum across all nodes of the square of their 
  # distance from desired x position. We square the difference in order 
  # to favor large differences for individuals over small differences for
  # many.
  calculate_global_energy = -> 
    energy_unsorted = 0
    energy_sorted = 0
    sorted = global_sort(false)

    for __, i in nodes
      energy_sorted   += Math.pow(sorted[i].x - opinions[sorted[i].index].x_target, 2)
      energy_unsorted += Math.pow( nodes[i].x - opinions[nodes[i].index].x_target , 2)

    return Math.sqrt(energy_unsorted) - Math.sqrt(energy_sorted)

  #####
  # global_sort
  #
  # Given a set of simulated face positions, reassigns avatars to the positions based on 
  # stance to enforce a global ordering. 
  # This method is visually jarring, so using it to sort nodes in place should be 
  # used as little as possible.
  global_sort = (sort_in_place) ->
    sort_in_place = true if !sort_in_place?

    # Create one node list sorted by x position
    x_sorted_nodes = nodes.slice()
                          .sort( (a,b) -> a.x-b.x )
    # ... and another sorted by desired x position
    desired_x_sorted_nodes = nodes.slice()
                  .sort( (a,b) -> opinions[a.index].x_target - opinions[b.index].x_target)

    # Create a new dummy set of nodes optimally arranged
    new_nodes = []
    for __, i in nodes
      new_nodes.push
        # assign the avatar...
        index: desired_x_sorted_nodes[i].index
        radius: desired_x_sorted_nodes[i].radius
        weight: desired_x_sorted_nodes[i].weight
        # ...to a good position
        x: x_sorted_nodes[i].x
        y: x_sorted_nodes[i].y
        px: x_sorted_nodes[i].px
        py: x_sorted_nodes[i].py

    # Walk through nodes and reassign the faces given
    # the optimal assignments discovered earlier. We
    # can't assign nodes=new_nodes because the layout
    # depends on nodes pointing to the same object.
    if sort_in_place
      props = ['index', 'radius', 'x', 'y', 'px', 'py', 'weight']    
      for __, i in nodes
        for __, j in props
          nodes[i][props[j]] = new_nodes[i][props[j]]

    return new_nodes
