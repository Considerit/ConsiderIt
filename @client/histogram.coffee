require './browser_hacks'
require './histogram_layout'
require './histogram_lab'
# md5 = require './vendor/md5' 

##
# Histogram
#
# Controls the display of the users arranged on a histogram. 
# 
# The user avatars are arranged imprecisely on the histogram
# based on the user's opinion, using a layout_params simulation. 
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
#      Hash of all opinion stances. Used to determine if the layout_params
#      simulation needs to be rerun on a rerender.
#   mouse_opinion_value
#      Stores the mapped opinion value of the current mouse position
#      within the histogram. 
#   avatar_size
#      The base size of the avatars, as determined by the layout_params 
#      simulation. This piece of state would be local, but it needs
#      to be settable from the layout_params simulation.

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


window.show_histogram_physics = false

window.Histogram = ReactiveComponent
  displayName : 'Histogram'

  get_hist_state: -> fetch (@props.selection_state or @props.key)

  render: -> 

    loc = fetch 'location'
    if loc.query_params.show_histogram_physics
      window.show_histogram_physics = true

    hist = @get_hist_state()

    dirtied = false 
    if !hist.initialized
      reset_selection_state(hist)
      dirtied = true 


    # extraction from @try_histocache
    proposal = fetch(@props.proposal)
    histocache_key = @histocache_key()
    if @last_key != histocache_key
      @weights ?= {}
      for o in @props.opinions when !@weights[o.user]?
        @weights[o.user] = 1 # Math.floor(Math.random() * 50 + 1)

      avatar_radius = calculateAvatarRadius @props.width, @props.height, @props.opinions, @weights,
                        fill_ratio: @props.layout_params?.fill_ratio or 1

      if @local.avatar_size != avatar_radius * 2
        @local.avatar_size = avatar_radius * 2
        save @local
        dirtied = true 

      @last_key = histocache_key
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
    if @weights
      key += JSON.stringify(@weights)
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

  PhysicsSimulation: ->
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
      
      # use a less cpu intensive layout for mobile browsers
      layout_params = _.defaults {}, (@props.layout_params or {}), 
        engine: if browser.is_mobile then 'tile' else 'matterjs'
        initial_layout: if browser.is_mobile then 'packed-tile' else 'tiled-with-wiggle'
        fill_ratio: 1
        show_histogram_physics: show_histogram_physics
        motionSleepThreshold: .005
        motionSleepThresholdIncrement: .000025
        enable_boosting: false
        wake_every_x_ticks: 9999
        global_swap_every_x_ticks: 150
        reduce_sleep_threshold_if_little_movement: true 
        sleep_reduction_exponent: .5
        cleanup_layout_every_x_ticks: 50
        x_force_mult: .008
        gravity_scale: .000012
        restack_top: false 
        final_cleanup_stability: .5
        change_cleanup_stability: -0.2
        cleanup_stability: .9
        cleanup_when_percent_sleeping: .4
        end_sleep_percent: .75
        filter_to_inflections_and_flats: true
        cleanup_overlap: 1.8
        cascade_instability: true


      setTimeout =>
        if @isMounted()
          layoutAvatars
            running_state: @props.key 
            k: histocache_key
            r: @local.avatar_size / 2
            w: @props.width or 400
            h: @props.height or 70
            o: opinions.slice()
            weights: @weights
            layout_params: layout_params
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
      , 0

    @current_request = histocache_key

  componentDidMount: ->   
    @PhysicsSimulation()

  componentDidUpdate: -> 
    @PhysicsSimulation()


window.styles += """
  .histo_avatar.avatar {
    position: absolute;
    cursor: pointer;
  }
  img.histo_avatar.avatar {
    z-index: 1;
  }
  .histo_avatar.avatar.selected {
    z-index: 9;
    background-color: #{focus_color()};
  }
  .histo_avatar.avatar.not_selected {
    opacity: .2;
  }
"""

HistoAvatars = ReactiveComponent 
  displayName: 'HistoAvatars'

  render: ->
    filter_out = fetch 'filtered'    
    users = fetch '/users'
    return SPAN null if !users.users

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

    base_avatar_diameter = @props.avatar_size

    # There are a few avatar styles that might be applied depending on state:
    # 1) Regular, for when no user is selected
    regular_avatar_style =
      width: base_avatar_diameter
      height: base_avatar_diameter
      cursor: if !@props.enable_individual_selection then 'auto'

    # 2) The style of a selected avatar
    selected_avatar_style = regular_avatar_style

    # 3) The style of an unselected avatar when some other avatar(s) is selected
    unselected_avatar_style = regular_avatar_style

    # 4) The style of the avatar when the histogram is backgrounded 
    #    (e.g. on the crafting page)
    backgrounded_page_avatar_style = _.extend {}, unselected_avatar_style, 
      opacity: if customization('show_histogram_on_crafting', @props.proposal) then .1 else 0.0

    # Draw the avatars in the histogram. Placement is determined by the physics sim
    users = {}
    colors = getNiceRandomHues 14

    DIV 
      id: @props.histocache_key
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

        users[opinion.user.key or opinion.user] = opinion

        backgrounded = filter_out.users?[user]
        if backgrounded && !filter_out.enable_comparison
          continue

        o = fetch(opinion) # subscribe to changes so physics sim will get rerun...

        # sub_creation = new Date(fetch('/subdomain').created_at).getTime()
        # creation = new Date(o.created_at).getTime()
        # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

        className = 'histo_avatar'
        if backgrounded || @props.backgrounded
          avatar_style = if fetch('/current_user').user == user 
                           _.extend({}, regular_avatar_style, {opacity: .25}) 
                         else 
                           backgrounded_page_avatar_style
        else if highlighted_users
          if _.contains(highlighted_users, opinion.user)   
            avatar_style = selected_avatar_style
            className += " selected"
          else
            avatar_style = unselected_avatar_style
            className += " not_selected"
        else
          avatar_style = regular_avatar_style

        pos = @props.histocache?.positions?[(user.key or user).substring(6)]

        if pos 
          custom_size = 2 * pos[2] != base_avatar_diameter

          avatar_style = _.extend {}, avatar_style

          avatar_style.left = pos?[0]
          avatar_style.top = pos?[1]


          if pos[2] && custom_size
            avatar_style.width = avatar_style.height = 2 * pos[2]
        else 
          continue


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
          className: className
          alt: "<user>: #{alt} #{pos[3]?.toFixed(3)}"
          anonymous: true
          style: _.extend {}, avatar_style,
            # backgroundColor: '#999'

            border: "2px solid #{if pos[2] then '#999' else 'orange'}"
            # border: "2px solid #{if pos[3] < .7 && pos[3] > .5 then 'red' else if pos[3] <= .5 then 'red' else '#999'}"
            # border: "1px solid #{hsv2rgb(1 - (pos[3] or .5) * .8, .5, .5)}" # #{if pos[3] <= .5 then 'red' else '#999'}"
            # backgroundColor: "#{hsv2rgb(pos[3] or .3, 1 - pos[3] or .5, .5)}" # #{if pos[3] <= .5 then 'red' else '#999'}"
            # backgroundColor: "#{hsv2rgb(colors[Math.round(pos[2])], .5, .5)}" # #{if pos[3] <= .5 then 'red' else '#999'}"





