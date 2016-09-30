require './browser_hacks'
md5 = require './vendor/md5' 

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
#
# Accessibility notes: 
#   - histogram itself should be tabbable. Should summarize results. 
#   - pressing enter should make avatars navigable via tabbing keys. state is @local.navigating_inside
#   - pressing escape makes avatars unfocusable and returns focus to the histogram.
#   - histogram should close navigation when it loses focus 
#   - need to provide instructions, probably in tooltip or aria-describedby.


require './vendor/d3.v3.min'
require './shared'

window.Histogram = ReactiveComponent
  displayName : 'Histogram'

  render: -> 
    hist = fetch @props.key
    filter_out = fetch 'filtered'

    dirtied = false 
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
      dirtied = true 

    avatar_radius = calculateAvatarRadius(@props.width, @props.height, @props.opinions)

    if @local.avatar_size != avatar_radius * 2
      @local.avatar_size = avatar_radius * 2
      save @local
      dirtied = true 

    # extraction from @try_histocache
    proposal = fetch(@props.proposal)
    histocache_key = @histocache_key()
    if proposal.histocache?[histocache_key]
      if histocache_key != @local.histocache?.hash
        @local.histocache =
          hash: histocache_key 
          positions: proposal.histocache[histocache_key]
        save @local 
        dirtied = true 

    @local.dirty == dirtied

    return SPAN null if dirtied

    if !@props.draw_base 
      @props.draw_base_labels = false 
    else if !@props.draw_base_labels?
      @props.draw_base_labels = true

    @props.enable_selection &&= @props.opinions.length > 0

    # Controls the size of the vertical space at the top of 
    # the histogram that gives some space for users to hover over 
    # the most populous areas
    region_selection_vertical_padding = if @props.enable_selection then 30 else 0
    if @local.region_selection_vertical_padding != region_selection_vertical_padding
       @local.region_selection_vertical_padding = region_selection_vertical_padding

    # whether to show the shaded opinion selection region in the histogram
    draw_selection_area = @props.enable_selection &&
                            !hist.selected_opinion && 
                            !@props.backgrounded &&
                            (hist.selected_opinions || 
                              (!@local.touched && 
                                @local.mouse_opinion_value && 
                                !@local.hoving_over_avatar))

    histogram_props = 
      tabIndex: if !@props.backgrounded then 0

      className: 'histogram'
      'aria-hidden': @props.backgrounded
      'aria-labelledby': if !@props.backgrounded then "##{proposal.id}-histo-label"
      'aria-describedby': if !@props.backgrounded then "##{proposal.id}-histo-description"

      style: css.crossbrowserify
        width: @props.width
        height: @props.height + @local.region_selection_vertical_padding
        position: 'relative'
        borderBottom: if @props.draw_base then '1px solid #999'
        #visibility: if @props.opinions.length == 0 then 'hidden'
        userSelect: 'none'
      onKeyDown: (e) =>
        if e.which == 32 # SPACE toggles navigation
          @local.navigating_inside = !@local.navigating_inside 
          save @local 
          e.preventDefault() # prevent scroll jumping
          if @local.navigating_inside
            @refs["avatar-0"]?.getDOMNode().focus()
          else 
            @getDOMNode().focus()
        else if e.which == 13 && !@local.navigating_inside # ENTER 
          @local.navigating_inside = true 
          @refs["avatar-0"]?.getDOMNode().focus()
          save @local 
        else if e.which == 27 && @local.navigating_inside
          @local.navigating_inside = false
          @getDOMNode().focus() 
          save @local 
      onBlur: (e) => 
        setTimeout => 
          # if the focus isn't still on this histogram, 
          # then we should reset its navigation
          if @local.navigating_inside && $(document.activeElement).closest(@getDOMNode()).length == 0
            @local.navigating_inside = false; save @local
        , 0

    score = 0
    filter_out = fetch 'filtered'
    opinions = (o for o in @props.opinions when !filter_out.users?[o.user])
    for o in opinions 
      score += o.stance
    avg = score / opinions.length
    negative = score < 0
    score *= -1 if negative
    score = pad score.toFixed(1),2

    if avg < -.03
      exp = "#{(-1 * avg * 100).toFixed(0)}% #{customization("slider_pole_labels.oppose", @props.proposal)}"
    else if avg > .03
      exp = "#{(avg * 100).toFixed(0)}% #{customization("slider_pole_labels.support", @props.proposal)}"
    else 
      exp = "neutral"


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
      DIV 
        id: "##{proposal.id}-histo-label"
        style: 
          position: 'absolute'
          left: -999999999999
        "Histogram showing #{opinions.length} opinions"

      DIV 
        id: "##{proposal.id}-histo-description"
        style: 
          position: 'absolute'
          left: -999999999999
        """#{opinions.length} people's opinion, with an average of #{exp} on a spectrum from #{customization("slider_pole_labels.oppose", @props.proposal)} to #{customization("slider_pole_labels.support", @props.proposal)}. 
           Press ENTER or SPACE to enable tab navigation of each person's opinion, and ESCAPE to exit the navigation.
        """         

      if @props.draw_base_labels
        @drawHistogramBase()

      if @props.enable_selection
        # A little padding at the top to give some space for selecting
        # opinion regions with lots of people stacked high      
        DIV style: {height: @local.region_selection_vertical_padding}

      # Draw the opinion selection area + region resizing border
      if draw_selection_area
        @drawSelectionArea()



      HistoAvatars
        highlighted_users: hist.highlighted_users
        selected_opinion: hist.selected_opinion 
        selected_opinions: hist.selected_opinions
        avatar_size: @local.avatar_size 
        enable_selection: @props.enable_selection
        proposal: @props.proposal
        height: @props.height 
        backgrounded: @props.backgrounded
        opinions: @props.opinions 
        histocache: @local.histocache
        histocache_key: @histocache_key()
        navigating_inside: @local.navigating_inside



  drawHistogramBase: -> 
    [SPAN
      style:
        position: 'absolute'
        left: 0
        bottom: -21
        fontSize: 14
        fontWeight: 400
        color: '#999'
      customization("slider_pole_labels.oppose", @props.proposal)
    SPAN
      style:
        position: 'absolute'
        right: 0
        bottom: -21
        fontSize: 14
        fontWeight: 400
        color: '#999'
      customization("slider_pole_labels.support", @props.proposal)
    ]

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
        user_key = ev.target.getAttribute('data-user')
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


  histocache_key: -> 
    filter_out = fetch 'filtered'
    opinions = (o for o in @props.opinions when !(filter_out.users?[o.user]))

    key = JSON.stringify _.map(opinions, (o) => 
            Math.round(fetch(o.key).stance * 100) / 100 )
    key += " (#{@props.width}, #{@props.height}, #{@props.width})"
    md5 key

  try_histocache : -> 
    proposal = fetch(@props.proposal)
    histocache_key = @histocache_key()

    if proposal.histocache?[histocache_key]
      if histocache_key != @local.histocache?.hash
        @local.histocache =
          hash: histocache_key 
          positions: proposal.histocache[histocache_key]

        save @local
      return true 
      
    false

  physicsSimulation: ->
    filter_out = fetch 'filtered'
    proposal = fetch @props.proposal
    return if !proposal.histocache?

    # We only need to rerun the sim if the distribution of stances has changed, 
    # or the width/height of the histogram has changed. We round the stance to two 
    # decimals to avoid more frequent recalculations than necessary (one way 
    # this happens is with the server rounding opinion data differently than 
    # the javascript does when moving one's slider)
    histocache_key = @histocache_key()
    
    if @try_histocache()
      noop = 1
    else if !@local.dirty && histocache_key != @local.histocache?.hash && @current_request != histocache_key

      filtered_opinions = (o for o in @props.opinions when !(filter_out.users?[o.user]))

      opinions = for opinion, i in filtered_opinions
        {stance: opinion.stance, user: opinion.user}
      
      setTimeout => 
        if @isMounted()
          layoutAvatars 
            k: histocache_key
            w: @props.width
            h: @props.height
            o: opinions
            r: @local.avatar_size / 2
            abort: => 
              abort = !@isMounted() || @current_request != histocache_key
              abort

            done: (positions) =>   
              return if !@isMounted()
              if Object.keys(positions).length != 0 && @current_request == histocache_key
                @local.histocaches = 
                  hash: histocache_key
                  positions: positions

                save @local

                proposal.histocache[histocache_key] = positions

                # save to server
                save
                  key: "/histogram/proposal/#{fetch(@props.proposal).id}/#{histocache_key}"
                  positions: positions
      , 1

    @current_request = histocache_key




  componentDidMount: ->   
    @physicsSimulation()

  componentDidUpdate: -> 
    @physicsSimulation()


HistoAvatars = ReactiveComponent 
  displayName: 'HistoAvatars'

  render: ->
    filter_out = fetch 'filtered'    

    # Highlighted users are the users whose avatars are colorized and fully 
    # opaque in the histogram. It is based on the current opinion selection and 
    # the highlighted_users state, which can be manipulated by other components. 
    highlighted_users = @props.highlighted_users
    selected_users = if @props.selected_opinion 
                       [@props.selected_opinion] 
                     else 
                       @props.selected_opinions
    if selected_users
      if highlighted_users
        highlighted_users = _.intersection highlighted_users, \
                                          (fetch(o).user for o in selected_users)
      else 
        highlighted_users = (fetch(o).user for o in selected_users)


    # There are a few avatar styles that might be applied depending on state:
    # 1) Regular, for when no user is selected
    regular_avatar_style =
      width: @props.avatar_size
      height: @props.avatar_size
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
    # if !browser.is_mobile
    #   unselected_avatar_style = css.grayscale _.extend unselected_avatar_style
    # 4) The style of the avatar when the histogram is backgrounded 
    #    (e.g. on the crafting page)
    backgrounded_page_avatar_style = _.extend {}, unselected_avatar_style, 
      opacity: if customization('show_histogram_on_crafting', @props.proposal) then .1 else 0.0

    # Draw the avatars in the histogram. Placement will be determined later
    # by the physics sim
    DIV 
      key: @props.histocache_key
      ref: 'histo'
      style: 
        height: @props.height
        position: 'relative'
        top: -1
        cursor: if !@props.backgrounded && 
                    @props.enable_selection then 'pointer'

      for opinion, idx in @props.opinions
        user = opinion.user

        if filter_out.users?[user]
          continue

        o = fetch(opinion) # subscribe to changes so physics sim will get rerun...

        # sub_creation = new Date(fetch('/subdomain').created_at).getTime()
        # creation = new Date(o.created_at).getTime()
        # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

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

        pos = @props.histocache?.positions?[(user.key or user).split('/user/')[1]]
        # Avatar 
        #   key: user
        #   user: user
        #   hide_tooltip: @props.backgrounded
        #   style: _.extend {}, avatar_style, 
        #     left: pos?[0]
        #     top: pos?[1]
        #     # opacity: opacity

        stance = opinion.stance 
        if stance < -.03
          exp = " is #{(-1 * stance * 100).toFixed(0)}% #{customization("slider_pole_labels.oppose", @props.proposal)}"
        else if stance > .03
          exp = " is #{(stance * 100).toFixed(0)}% #{customization("slider_pole_labels.support", @props.proposal)}"
        else 
          exp = " is neutral"

        avatar user,
          ref: "avatar-#{idx}"
          focusable: @props.navigating_inside && !@props.backgrounded 
          hide_tooltip: @props.backgrounded
          alt: "<user>#{exp}"
          style: _.extend {}, avatar_style, 
            left: pos?[0]
            top: pos?[1]
            # opacity: opacity




######
# Uses a d3-based physics simulation to calculate a reasonable layout
# of avatars within a given area.

layoutAvatars = (opts) -> 
  histo_queue.push opts 
  if !histo_running
    histo_run_next_job()

histo_queue = []
histo_running = null 
histo_run_next_job = (completed) -> 
  if histo_running == completed 
    histo_running = null

  if !histo_running && histo_queue.length > 0
    histo_running = histo_queue.shift()

    positionAvatars histo_running


positionAvatars = (opts) -> 

  # Check if system energy would be reduced if two nodes' positions would 
  # be swapped. We square the difference in order to favor large differences 
  # for one vs small differences for the pair.
  energy_reduced_by_swap = (p1, p2) ->
    # how much does each point covet the other's location, over their own?
    p1_jealousy = (p1.x - p1.x_target) * (p1.x - p1.x_target) - \
                  (p2.x - p1.x_target) * (p2.x - p1.x_target)
    p2_jealousy = (p2.x - p2.x_target) * (p2.x - p2.x_target) - \
                  (p1.x - p2.x_target) * (p1.x - p2.x_target) 
    p1_jealousy + p2_jealousy

  # Swaps the positions of two avatars
  swap_position = (p1, p2) ->
    swap_x = p1.x; swap_y = p1.y
    p1.x = p2.x; p1.y = p2.y
    p2.x = swap_x; p2.y = swap_y 

  # One iteration of the simulation
  tick = (alpha) ->
    stable = true

    ####
    # Repel colliding nodes
    # A quadtree helps efficiently detect collisions
    q = d3.geom.quadtree(nodes)

    for n in nodes 
      q.visit collide(n, alpha)

    for o, i in nodes
      o.px = o.x
      o.py = o.y

      # Push node toward its desired x-position
      o.x += alpha * (x_force_mult * width  * .001) * (o.x_target - o.x)

      # Push node downwards
      o.y += alpha * y_force_mult

      # Ensure node is still within the bounding box
      if o.x < o.radius
        o.x = o.radius
      else if o.x > width - o.radius
        o.x = width - o.radius

      if o.y < o.radius
        o.y = o.radius
      else if o.y > height - o.radius
        o.y = height - o.radius

      dx = Math.abs(o.py - o.y)
      dy = Math.abs(o.px - o.x) > .1

      if stable && Math.sqrt(dx * dx + dy * dy) > 1
        stable = false

    # Complete the simulation if we've reached a steady state
    stable

  collide = (p1, alpha) ->

    return (quad, x1, y1, x2, y2) ->
      p2 = quad.point
      if quad.leaf && p2 && p2 != p1
        dx = Math.abs (p1.x - p2.x)
        dy = Math.abs (p1.y - p2.y)
        dist = Math.sqrt(dx * dx + dy * dy)
        combined_r = p1.radius + p2.radius

        # Transpose two points in the same neighborhood if it would reduce 
        # energy of system
        if energy_reduced_by_swap(p1, p2) > 0
          swap_position(p1, p2)          

        # repel both points equally in opposite directions if they overlap
        if dist < combined_r
          separate_by = if dist == 0 then 1 else ( combined_r - dist ) / combined_r
          offset_x = (combined_r - dx) * separate_by
          offset_y = (combined_r - dy) * separate_by

          if p1.x < p2.x 
            p1.x -= offset_x / 2
            p2.x += offset_x / 2
          else 
            p2.x -= offset_x / 2
            p1.x += offset_x / 2

          if p1.y < p2.y           
            p1.y -= offset_y / 2
            p2.y += offset_y / 2
          else 
            p2.y -= offset_y / 2
            p1.y += offset_y / 2

      # Visit subregions if we could possibly have a collision there
      neighborhood_radius = p1.radius
      nx1 = p1.x - neighborhood_radius
      nx2 = p1.x + neighborhood_radius
      ny1 = p1.y - neighborhood_radius
      ny2 = p1.y + neighborhood_radius

      return x1 > nx2 || 
              x2 < nx1 ||
              y1 > ny2 ||
              y2 < ny1



  ##############
  # Initialize positions of each node
  targets = {}
  opinions = opts.o.slice()
  width = opts.w || 400
  height = opts.h || 70
  r = calculateAvatarRadius width, height, opinions

  nodes = opinions.map (o, i) ->
    x_target = (o.stance + 1) / 2 * width

    if targets[x_target]
      if x_target > .98
        x_target -= .1 * Math.random() 
      else if x_target < .02
        x_target += .1 * Math.random() 

    targets[x_target] = 1

    x = x_target
    y = height - r

    return {
      index: i
      radius: r
      x: x
      y: y
      x_target: x_target
    }

  ###########
  # run the simulation
  stable = false
  alpha = .8
  decay = .8
  min_alpha = 0.0000001
  x_force_mult = 2
  y_force_mult = 2

  total_ticks = 0

  while true
    stable = tick alpha
    alpha *= decay
    total_ticks += 1

    stable ||= alpha <= min_alpha

    aborted = opts.abort?()
    break if stable || aborted


  if !aborted
    positions = {}
    for o, i in nodes
      positions[parseInt(opinions[i].user.split('/user/')[1])] = \
        [Math.round((o.x - o.radius) * 10) / 10, Math.round((o.y - o.radius) * 10) / 10]

    opts.done?(positions)

  histo_run_next_job(opts)



#####
# Calculate node radius based on the largest density of avatars in an 
# area (based on a moving average of # of opinions, mapped across the
# width and height)

calculateAvatarRadius = (width, height, opinions) -> 
  filter_out = fetch 'filtered'
  if filter_out.users 
    opinions = (o for o in opinions when !(filter_out.users?[o.user]))

  opinions.sort (a,b) -> a.stance - b.stance

  # first, calculate a moving average of the number of opinions
  # across around all possible stances
  window_size = .3
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

