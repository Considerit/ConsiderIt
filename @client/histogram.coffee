require './browser_hacks'
# md5 = require './vendor/md5' 

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
#   enable_individual_selection (default = false)
#     Whether individual users can be selected on the histogram
#   enable_range_selection (default = false)
#     Whether ranges can be selected on the histogram
#   selection_state (default = @props.key)
#     The statebus key at which selection state will be updated
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
#   highlighted_users
#      Users that other components want to have highlighted in the 
#      histogram. In the render, this is intersected with the users whose 
#      opinions are selected to determine which avatars are highlighted. 
#
# Local state: 
#   simulation_opinion_hash
#      Hash of all opinion stances. Used to determine if the physics
#      simulation needs to be rerun on a rerender.
#   mouse_opinion_value
#      Stores the mapped opinion value of the current mouse position
#      within the histogram. 
#   avatar_size
#      The base size of the avatars, as determined by the physics 
#      simulation. This piece of state would be local, but it needs
#      to be settable from the physics simulation.

# Accessibility notes: 
#   - histogram itself should be tabbable. Should summarize results. 
#   - pressing enter should make avatars navigable via tabbing keys. state is @local.navigating_inside
#   - pressing escape makes avatars unfocusable and returns focus to the histogram.
#   - histogram should close navigation when it loses focus 
#   - need to provide instructions, probably in tooltip or aria-describedby.


# require './vendor/d3.v3.min'
require './shared'

# REGION_SELECTION_WIDTH controls the size of the selection region when 
# hovering over the histogram. It defines the opinion bounds within which 
# opinions are selected. Opinions = [-1, 1]. REGION_SELECTION_WIDTH is 
# on this scale. 
REGION_SELECTION_WIDTH = .25

# Controls the size of the vertical space at the top of 
# the histogram that gives some space for users to hover over 
# the most populous areas
REGION_SELECTION_VERTICAL_PADDING = 30

window.reset_selection_state = (state) ->
  hist = fetch state
  _.extend hist,
    initialized: true
    highlighted_users : null
    
    selected_opinion : null
    selected_opinions : null 
      # use null instead of [] because an empty selection of []
      # is treated differently than no selection whatsoever
    selected_opinion_value : null
    originating_histogram : null
  save hist


ENABLE_SERVER_HISTOCACHE = false 

window.Histogram = ReactiveComponent
  displayName : 'Histogram'

  get_hist_state: -> fetch (@props.selection_state or @props.key)

  render: -> 
    hist = @get_hist_state()

    dirtied = false 
    if !hist.initialized
      reset_selection_state(hist)
      dirtied = true 

    avatar_radius = calculateAvatarRadius(@props.width, @props.height, @props.opinions)

    if @local.avatar_size != avatar_radius * 2
      @local.avatar_size = avatar_radius * 2
      save @local
      dirtied = true 

    # extraction from @try_histocache
    proposal = fetch(@props.proposal)
    histocache_key = @histocache_key()
    if ENABLE_SERVER_HISTOCACHE && proposal.histocache?[histocache_key]
      if histocache_key != @local.histocache?.hash
        @local.histocache =
          hash: histocache_key 
          positions: proposal.histocache[histocache_key]
        save @local 
        dirtied = true 

    @local.dirty == dirtied

    if !@props.draw_base_labels?
      @props.draw_base_labels = true

    filter_out = fetch 'filtered'
    opinions = (o for o in @props.opinions when filter_out.enable_comparison || !filter_out.users?[o.user])

    @props.enable_individual_selection &&= opinions.length > 0
    @props.enable_range_selection &&= opinions.length > 1
    @props.enable_range_selection &&= (!filter_out.current_filter || filter_out.current_filter.label != 'just you')

    # whether to show the shaded opinion selection region in the histogram
    draw_selection_area = @props.enable_range_selection &&
                            !hist.selected_opinion && 
                            !@props.backgrounded &&
                            (hist.selected_opinions || 
                              (!@local.touched && 
                                @local.mouse_opinion_value && 
                                !@local.hoving_over_avatar))
    histo_height = @props.height + (if true || @props.enable_range_selection then REGION_SELECTION_VERTICAL_PADDING else 0)
    histogram_props = 
      tabIndex: if !@props.backgrounded then 0

      className: 'histogram'
      'aria-hidden': @props.backgrounded
      'aria-labelledby': if !@props.backgrounded then "##{proposal.id}-histo-label"
      'aria-describedby': if !@props.backgrounded then "##{proposal.id}-histo-description"

      style: css.crossbrowserify
        width: @props.width
        height: histo_height
        position: 'relative'
        borderBottom: if @props.draw_base then @props.base_style or "1px solid #999"
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
    for o in opinions 
      score += o.stance
    avg = score / opinions.length
    negative = score < 0
    score *= -1 if negative
    score = pad score.toFixed(1),2

    if avg < -.03
      exp = "#{(-1 * avg * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", @props.proposal)}"
    else if avg > .03
      exp = "#{(avg * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", @props.proposal)}"
    else 
      exp = translator "engage.slider_feedback.neutral", "Neutral"


    if @props.enable_range_selection || @props.enable_individual_selection
      if !browser.is_mobile
        _.extend histogram_props,
          onClick: @onClick
          onMouseMove: @onMouseMove
          onMouseLeave: @onMouseLeave
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
            @local.last_tapped_at = curr_time
            save @local

    DIV histogram_props, 
      DIV 
        id: "##{proposal.id}-histo-label"
        className: 'hidden'
        
        TRANSLATE 
          id: "engage.histogram.explanation"
          num_opinions: opinions.length 
          "Histogram showing {num_opinions, plural, one {# opinion} other {# opinions}}"

      DIV 
        id: "##{proposal.id}-histo-description"
        className: 'hidden'

        TRANSLATE 
          id: "engage.histogram.explanation_extended"
          num_opinions: opinions.length 
          avg_score: exp
          negative_pole: get_slider_label("slider_pole_labels.oppose", @props.proposal)
          positive_pole: get_slider_label("slider_pole_labels.support", @props.proposal)

          """{num_opinions, plural, one {one person's opinion of} other {# people's opinion, with an average of}} {avg_score} 
             on a spectrum from {negative_pole} to {positive_pole}. 
             Press ENTER or SPACE to enable tab navigation of each person's opinion, and ESCAPE to exit the navigation.
          """         

      if @props.draw_base_labels
        @drawHistogramLabels()

      if true || @props.enable_range_selection
        # A little padding at the top to give some space for selecting
        # opinion regions with lots of people stacked high      
        DIV style: {height: @local.region_selection_vertical_padding}

      # Draw the opinion selection area + region resizing border
      if draw_selection_area
        @drawSelectionArea()



      DIV 
        style: 
          paddingTop: histo_height - @props.height 

        HistoAvatars
          dirtied: dirtied
          highlighted_users: hist.highlighted_users
          selected_opinion: hist.selected_opinion 
          selected_opinions: hist.selected_opinions
          avatar_size: @local.avatar_size 
          enable_individual_selection: @props.enable_individual_selection
          enable_range_selection: @props.enable_range_selection
          proposal: @props.proposal
          height: @props.height 
          backgrounded: @props.backgrounded
          opinions: @props.opinions 
          histocache: @local.histocache
          histocache_key: @histocache_key()
          navigating_inside: @local.navigating_inside



  drawHistogramLabels: -> 
    label_style = @props.label_style or {
      fontSize: 12
      fontWeight: 400
      color: '#999'
      bottom: -19
    }

    [SPAN
      style: _.extend {}, label_style,
        position: 'absolute'
        left: 0

      get_slider_label("slider_pole_labels.oppose", @props.proposal)
    SPAN
      style: _.extend {}, label_style,
        position: 'absolute'
        right: 0

      get_slider_label("slider_pole_labels.support", @props.proposal)
    ]

  drawSelectionArea: -> 
    hist = @get_hist_state()
    anchor = hist.selected_opinion_value or @local.mouse_opinion_value
    left = ((anchor + 1)/2 - REGION_SELECTION_WIDTH/2) * @props.width
    base_width = REGION_SELECTION_WIDTH * @props.width
    selection_width = Math.min( \
                        Math.min(base_width, base_width + left), \
                        @props.width - left)
    selection_left = Math.max 0, left

    return DIV null if hist.originating_histogram && hist.originating_histogram != @props.key

    DIV 
      style:
        height: @props.height + REGION_SELECTION_VERTICAL_PADDING
        position: 'absolute'
        width: selection_width
        backgroundColor: "rgb(246, 247, 249)"
        cursor: 'pointer'
        left: selection_left
        top: -2 #- REGION_SELECTION_VERTICAL_PADDING
        borderTop: "2px solid"
        borderTopColor: if hist.selected_opinions then focus_color() else 'transparent'

      if !hist.selected_opinions
        DIV
          style: css.crossbrowserify
            fontSize: 12
            textAlign: 'center'
            whiteSpace: 'nowrap'
            marginTop: -3 #-9
            marginLeft: -4
            userSelect: 'none'
            pointerEvents: 'none'

          TRANSLATE "engage.histogram.select_these_opinions", 'highlight opinions'

  onClick: (ev) -> 

    ev.stopPropagation()
    hist = @get_hist_state()

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

        is_deselection = (hist.selected_opinion == user_opinion.key || fetch('filtered').users?[user_key]) 
        if is_deselection
          reset_selection_state(hist)
        else 
          hist.selected_opinion = user_opinion.key
          hist.selected_opinions = null
      else
        max = hist.selected_opinion_value + REGION_SELECTION_WIDTH
        min = hist.selected_opinion_value - REGION_SELECTION_WIDTH
        is_deselection = \
          (hist.originating_histogram && hist.originating_histogram != @props.key) || ( \
          hist.selected_opinions && 
           (!@local.touched || inRange(@local.mouse_opinion_value, min, max)))

        if is_deselection
          reset_selection_state(hist)
          if ev.type == 'touchstart'
            @local.mouse_opinion_value = null
        else if @props.enable_range_selection
          hist.selected_opinion = null
          hist.selected_opinions = @getOpinionsInCurrentRegion()
          hist.originating_histogram = @props.key

      has_selection = hist.selected_opinion || hist.selected_opinions
      hist.selected_opinion_value = if !has_selection 
                                      null 
                                    else if !is_clicking_user 
                                      @local.mouse_opinion_value 
                                    else 
                                      user_opinion.stance

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

    return if fetch(namespaced_key('slider', @props.proposal)).is_moving  || \
              @props.backgrounded || !@props.enable_range_selection

    hist = @get_hist_state()    
    return if hist.originating_histogram && hist.originating_histogram != @props.key


    ev.stopPropagation()

    @local.hoving_over_avatar = ev.target.className.indexOf('avatar') != -1
    @local.mouse_opinion_value = @getOpinionValueAtFocus(ev)

    if @local.mouse_opinion_value + REGION_SELECTION_WIDTH >= 1
      @local.mouse_opinion_value = 1 - REGION_SELECTION_WIDTH
    else if @local.mouse_opinion_value - REGION_SELECTION_WIDTH <= -1
      @local.mouse_opinion_value = -1 + REGION_SELECTION_WIDTH
    
    # dynamic selection on drag
    if hist.selected_opinions &&
        @local.mouse_opinion_value # this last conditional is only for touch
                                   # interactions where there is no mechanism 
                                   # for "leaving" the histogram
      hist.selected_opinions = @getOpinionsInCurrentRegion()
      hist.selected_opinion_value = @local.mouse_opinion_value 
      save hist

    save @local

  onMouseDown: (ev) -> 
    return if fetch(namespaced_key('slider', @props.proposal)).is_moving
    ev.stopPropagation()
    return false 
      # The return false prevents text selections
      # of other parts of the page when dragging
      # the selection region around.


  onMouseLeave: (ev) -> 
    hist = @get_hist_state() 

    return if fetch(namespaced_key('slider', @props.proposal)).is_moving || \
              (hist.originating_histogram && hist.originating_histogram != @props.key)
    @local.mouse_opinion_value = null
    save @local


  getOpinionsInCurrentRegion : -> 
    # return the opinions whose stance is within +/- REGION_SELECTION_WIDTH 
    # of the moused over area of the histogram

    hist = @get_hist_state()
    all_opinions = @props.opinions || []  
    min = @local.mouse_opinion_value - REGION_SELECTION_WIDTH
    max = @local.mouse_opinion_value + REGION_SELECTION_WIDTH
    selected_opinions = (o.key for o in all_opinions when inRange(o.stance, min, max))
    selected_opinions


  histocache_key: -> 
    filter_out = fetch 'filtered'
    opinions = (o for o in @props.opinions when filter_out.enable_comparison || !(filter_out.users?[o.user]))

    key = JSON.stringify _.map(opinions, (o) => 
            Math.round(fetch(o.key).stance * 100) / 100 )
    key += " (#{@props.width}, #{@props.height})"
    md5 key

  try_histocache : -> 
    return false if !ENABLE_SERVER_HISTOCACHE
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

    # We only need to rerun the sim if the distribution of stances has changed, 
    # or the width/height of the histogram has changed. We round the stance to two 
    # decimals to avoid more frequent recalculations than necessary (one way 
    # this happens is with the server rounding opinion data differently than 
    # the javascript does when moving one's slider)
    histocache_key = @histocache_key()
    
    if @try_histocache()
      noop = 1
    else if !@local.dirty && histocache_key != @local.histocache?.hash && @current_request != histocache_key

      filtered_opinions = (o for o in @props.opinions when filter_out.enable_comparison || !(filter_out.users?[o.user]))

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
                @local.histocache = 
                  hash: histocache_key
                  positions: positions

                save @local

                if ENABLE_SERVER_HISTOCACHE
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
      cursor: if @props.enable_individual_selection then 'pointer' else 'auto'

    # 2) The style of a selected avatar
    selected_avatar_style = _.extend {}, regular_avatar_style, 
      zIndex: 9
      backgroundColor: focus_color()
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
                    @props.enable_range_selection then 'pointer'

      for opinion, idx in @props.opinions
        user = opinion.user

        backgrounded = filter_out.users?[user]
        if backgrounded && !filter_out.enable_comparison
          continue

        o = fetch(opinion) # subscribe to changes so physics sim will get rerun...

        # sub_creation = new Date(fetch('/subdomain').created_at).getTime()
        # creation = new Date(o.created_at).getTime()
        # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

        if backgrounded || @props.backgrounded
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

        pos = @props.histocache?.positions?[(user.key or user).substring(6)]
        # Avatar 
        #   key: user
        #   user: user
        #   hide_tooltip: @props.backgrounded
        #   style: _.extend {}, avatar_style, 
        #     left: pos?[0]
        #     top: pos?[1]
        #     # opacity: opacity

        stance = opinion.stance 
        if stance > .01
          alt = "#{(stance * 100).toFixed(0)}%"
        else if stance < -.01
          alt = "– #{(stance * -100).toFixed(0)}%"
        else 
          alt = translator "engage.histogram.user_is_neutral", "is neutral"

        if opinion.explanation
          paragraphs = safe_string(opinion.explanation).split(/(?:\r?\n)/g)
          alt += "<div style='margin-top: 12px; max-width:400px'>Their explanation:<div style='padding:4px 12px'>"

          for paragraph in paragraphs
            alt += "<p style='font-style:italic'>#{paragraph}</p>"
          alt += '</div></div>'

        avatar user,
          ref: "avatar-#{idx}"
          focusable: @props.navigating_inside && !@props.backgrounded && !backgrounded
          hide_tooltip: @props.backgrounded || backgrounded
          alt: "<user>: #{alt}"
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
      collisions += 1

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

  write_positions = -> 
    positions = {}
    for o, i in nodes
      positions[parseInt(opinions[i].user.substring(6))] = \
        [Math.round((o.x - o.radius) * 10) / 10, Math.round((o.y - o.radius) * 10) / 10]

    opts.done?(positions)

  ##############
  # Initialize positions of each node
  targets = {}
  opinions = opts.o.slice()
  width = opts.w or 400
  height = opts.h or 70
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
  collisions = 0 

  loc = fetch 'location'
  if loc.query_params.show_histogram_physics
    iterate = => 
      stable = tick alpha
      alpha *= decay
      total_ticks += 1

      console.log "Tick: #{total_ticks} Collisions: #{collisions}"
      collisions = 0

      stable ||= alpha <= min_alpha

      if !aborted
        write_positions()

      aborted = opts.abort?()
      if stable || aborted
        histo_run_next_job(opts)
      else 
        setTimeout iterate, loc.query_params.show_histogram_physics or 100
    iterate()

  else 
    while true
      stable = tick alpha
      alpha *= decay
      total_ticks += 1

      stable ||= alpha <= min_alpha

      aborted = opts.abort?()
      break if stable || aborted


    if !aborted
      write_positions()

    histo_run_next_job(opts)



#####
# Calculate node radius based on the largest density of avatars in an 
# area (based on a moving average of # of opinions, mapped across the
# width and height)

calculateAvatarRadius = (width, height, opinions) -> 
  filter_out = fetch 'filtered'
  if filter_out.users && !filter_out.enable_comparison
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

