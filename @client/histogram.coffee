require './browser_hacks'
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
      avatar_radius = calculateAvatarRadius(@props.width, @props.height, @props.opinions, {fill_ratio: @props.layout_params?.fill_ratio or 1})

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
            w: @props.width
            h: @props.height
            o: opinions
            r: @local.avatar_size / 2
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
      cursor: if !@props.enable_individual_selection then 'auto'

    # 2) The style of a selected avatar
    selected_avatar_style = regular_avatar_style

    # 3) The style of an unselected avatar when some other avatar(s) is selected
    unselected_avatar_style = regular_avatar_style

    # 4) The style of the avatar when the histogram is backgrounded 
    #    (e.g. on the crafting page)
    backgrounded_page_avatar_style = _.extend {}, unselected_avatar_style, 
      opacity: if customization('show_histogram_on_crafting', @props.proposal) then .1 else 0.0

    # Draw the avatars in the histogram. Placement will be determined later
    # by the physics sim


    users = {}
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
        continue if !pos


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
            left: pos?[0]
            top: pos?[1]
            # border: "2px solid #{if pos[2] then '#999' else 'orange'}"
            # border: "2px solid #{if pos[3] < .7 && pos[3] > .5 then 'red' else if pos[3] <= .5 then 'red' else '#999'}"
            #border: "1px solid #{hsv2rgb(1 - pos[3] * .8, .5, .5)}" # #{if pos[3] <= .5 then 'red' else '#999'}"
            backgroundColor: "#{hsv2rgb(pos[3] or .3, 1 - pos[3] or .5, .5)}" # #{if pos[3] <= .5 then 'red' else '#999'}"




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

    if histo_running.layout_params.engine == 'matterjs'
      positionAvatarsWithMatterJS histo_running
    else if histo_running.layout_params.engine == 'd3'
      positionAvatarsWithD3 histo_running
    else 
      positionAvatarsWithJustLayout histo_running 



initialize_positions = (opts) -> 
  targets = {}
  opinions = opts.o.slice()
  width = opts.w or 400
  height = opts.h or 70
  layout_params = opts.layout_params
  r = opts.r

  if layout_params.initial_layout == 'classic_at_top' 
    nodes = classic_layout(opinions, width, height, r, targets, at_top: true)
  else if layout_params.initial_layout == 'classic_at_bottom'
    nodes = classic_layout(opinions, width, height, r, targets, at_top: false)
  else if layout_params.initial_layout == 'tiled' || !layout_params.initial_layout
    nodes = tiled_layout(opinions, width, height, r, targets) 
  else if layout_params.initial_layout == 'tiled-with-wiggle'
    nodes = tiled_layout(opinions, width, height, r, targets, wiggle: 1) 
  else if layout_params.initial_layout == 'tiled-with-wiggle-2'
    nodes = tiled_layout(opinions, width, height, r, targets, wiggle: .5) 

  else if layout_params.initial_layout == 'packed-tile'
    nodes = packed_tiled_layout(opinions, width, height, r, targets, wiggle: false) 


  {nodes, targets, opinions, width, height, r}


classic_layout = (opinions, width, height, r, targets, {at_top}) -> 
  opinions.map (o, i) ->
    x_target = (o.stance + 1) / 2 * width

    if targets[x_target]
      if x_target > .98
        x_target -= .1 * Math.random() 
      else if x_target < .02
        x_target += .1 * Math.random() 

    targets[x_target] = 1

    x = x_target
    if at_top
      y = r
    else 
      y = height - r

    return {
      index: i
      radius: r
      x: x
      y: y
      x_target: x_target
    }

tiled_layout = (opinions, width, height, r, targets, params) -> 
  MAX_DISTURBANCE = 1 * width # how far away from its target is an opinion allowed to start?
  laid_out = []
  return laid_out if opinions.length == 0 

  wiggle = params?.wiggle

  find_split = (start, end, iterations) ->
    halfway = Math.round((end - start) / 2) + start
    if iterations > 4
      return halfway

    if opinions[start].stance < 0 && opinions[halfway].stance < 0
      return find_split(halfway, end, iterations + 1)
    else 
      return find_split(start, halfway, iterations + 1)

  split_idx = find_split(0, opinions.length - 1, 0)
  num_cols = Math.round(width / (2 * r))
  num_rows = Math.round(height / (2 * r))
  grid = []
  current_row = []

  col = 0 
  while col < num_cols
    grid[col] = []
    current_row[col] = 0
    row = 0 
    while row < num_rows
      grid[col][row] = 0
      row +=1
    col += 1

  idx = 0 
  while idx < split_idx
    x_target = (opinions[idx].stance + 1) / 2 * width

    target_col = Math.round( (opinions[idx].stance + 1) / 2 * num_cols   )

    if target_col >= num_cols
      target_col = num_cols - 1
    else if target_col < 0 
      target_col = 0 

    col = target_col

    # find a good position for this node
    assigned = false 
    cnt_in_target = grid[target_col][0]
    while (col - target_col) * 2 * r < MAX_DISTURBANCE && col < num_cols
      if grid[col][current_row[col]] < cnt_in_target
        row = current_row[col]
        assigned = true 
        break
      col += 1

    if !assigned
      col = target_col 
      row = 0 

    grid[col][row] += 1
    if row == num_rows - 1
      current_row[col] = 0
    else 
      current_row[col] += 1

    x = col * 2 * r + r
    y = height - (row * 2 * r) - r

    laid_out.push {
      index: idx
      radius: r
      x: x
      y: y
      x_target: x_target
    }
    idx += 1

  idx = opinions.length - 1
  while idx >= split_idx
    x_target = (opinions[idx].stance + 1) / 2 * width

    target_col = Math.round( (opinions[idx].stance + 1) / 2 * num_cols   ) - 1

    if target_col >= num_cols
      target_col = num_cols - 1
    else if target_col < 0 
      target_col = 0 

    col = target_col

    # find a good position for this node
    assigned = false 
    cnt_in_target = grid[target_col][0]
    while (target_col - col) * 2 * r < MAX_DISTURBANCE && col >= 0 
      if grid[col][current_row[col]] < cnt_in_target
        row = current_row[col]
        assigned = true 
        break
      col -= 1

    if !assigned
      col = target_col 
      row = 0 

    grid[col][row] += 1
    if row == num_rows - 1
      current_row[col] = 0
    else 
      current_row[col] += 1

    x = col * 2 * r + r
    y = height - (row * 2 * r) - r

    laid_out.push {
      index: idx
      radius: r
      x: x
      y: y
      x_target: x_target
    }
    idx -= 1

  if wiggle
    for n in laid_out
      n.x += (Math.random() - .5) * r * wiggle
      # n.y += (Math.random() - .5) * r
      if n.x + r > width 
        n.x = width - r 
      else if n.x < r 
        n.x = r 
      if n.y + r > height
        n.y = height - r 
      else if n.y < r
        n.y = r 


  laid_out.sort (a,b) -> a.index - b.index
  laid_out

# packed_tiled_layout
# Calculated initial position of each avatar by laying them out in a grid as close to their 
# intended position as possible, starting from the poles and working to the middle.
# This is "packed" because it leverages the avatars being circles to make each column 
# less than 2*r wide. Each cicle only needs to have their centroid 2*r away from each other one,
# so if we alternate the initial y position of each column by r, we can actually use spacing
# r + (sqrt(2) * r) / 2 rather than 2*r. This may sound like a small improvement, but the asthetics
# are quite profound. 
# Note: I changed to packing the row_height, rather than col_width, but same principles apply
packed_tiled_layout = (opinions, width, height, r, targets, params) -> 
  MAX_DISTURBANCE = 1 * width # how far away from its target is an opinion allowed to start?
  laid_out = []
  return laid_out if opinions.length == 0 

  wiggle = params?.wiggle

  find_split = (start, end, iterations) ->
    halfway = Math.round((end - start) / 2) + start
    if iterations > 4
      return halfway

    if opinions[start].stance < 0 && opinions[halfway].stance < 0
      return find_split(halfway, end, iterations + 1)
    else 
      return find_split(start, halfway, iterations + 1)

  split_idx = find_split(0, opinions.length - 1, 0)

  col_width = 2 * r
  row_height = r + (r * Math.sqrt(2)) / 2
  num_cols = Math.round(width / col_width)
  num_rows = Math.round(height / row_height)  # -.5 * r is to accommodate the avg offset for packing (0 vs r)
  grid = []
  current_row = []

  col = 0 
  while col < num_cols
    grid[col] = []
    current_row[col] = 0
    row = 0 
    while row < num_rows
      grid[col][row] = 0
      row +=1
    col += 1


  for negative_pole in [true, false]
    idx = if negative_pole then 0 else opinions.length - 1

    while (negative_pole && idx < split_idx) || (!negative_pole && idx >= split_idx)
      adjusted_stance = (opinions[idx].stance + 1) / 2
      x_target = adjusted_stance * width
      target_col = Math.round( adjusted_stance * num_cols  ) 

      if !negative_pole
        target_col -= 1

      if target_col >= num_cols
        target_col = num_cols - 1
      else if target_col < 0 
        target_col = 0

      col = target_col

      # find a good position for this node
      assigned = false 
      cnt_in_target = grid[target_col][0]

      if negative_pole
        while (col - target_col) * 2 * r < MAX_DISTURBANCE && col < num_cols
          if grid[col][current_row[col]] < cnt_in_target
            row = current_row[col]
            assigned = true 
            break
          col += 1
      else 
        while (target_col - col) * 2 * r < MAX_DISTURBANCE && col >= 0 
          if grid[col][current_row[col]] < cnt_in_target
            row = current_row[col]
            assigned = true 
            break
          col -= 1

      if !assigned
        col = target_col 
        row = 0 

      grid[col][row] += 1
      if row == num_rows - 1
        current_row[col] = 0
      else 
        current_row[col] += 1

      x = col * col_width + r
      y = height - (row * row_height) - r
      if row % 2 == 1
        # offset for packing
        if x_target < 0
          x -= r 
        else 
          x += r

      laid_out.push {
        index: idx
        radius: r
        x: x
        y: y
        x_target: x_target
      }

      if negative_pole
        idx += 1
      else 
        idx -= 1


  

  if wiggle
    for n in laid_out
      n.x += (Math.random() - .5) * r
      # n.y += (Math.random() - .5) * r
      if n.x + r > width 
        n.x = width - r 
      else if n.x < r 
        n.x = r 
      if n.y + r > height
        n.y = height - r 
      else if n.y < r
        n.y = r 


  laid_out.sort (a,b) -> a.index - b.index
  laid_out


#####
# Physics engine for reasonable layout of avatars within area
#

positionAvatarsWithJustLayout = (opts) -> 
  {nodes, targets, opinions, width, height, r} = initialize_positions opts

  positions = {}
  for n in nodes
    r = n.radius
    i = n.index 
    positions[parseInt(opinions[i].user.substring(6))] = \
      [Math.round((n.x - r) * 10) / 10, Math.round((n.y - r) * 10) / 10]

  opts.done?(positions)
  histo_run_next_job(opts)



positionAvatarsWithMatterJS = (opts) -> 
  Events = Matter.Events
  Engine = Matter.Engine
  init = initialize_positions opts
  width = init.width 
  height = init.height 
  opinions = init.opinions

  layout_params = opts.layout_params

  # create engine
  engine = Engine.create()
  engine.enableSleeping = true
  
  #############
  # add walls
  wall = 1000
  wall_params = { isStatic: true, render: strokeStyle: 'transparent' }
  Matter.Composite.add engine.world, [ 
    # top
    Matter.Bodies.rectangle(  width / 2, -wall / 2, 2 * width, wall, wall_params)
    # bottom
    Matter.Bodies.rectangle(  width / 2, height + wall / 2, 2 * width + wall / 2, wall, wall_params)
    # right
    Matter.Bodies.rectangle(  width + wall / 2, height / 2, wall, 2 * height + wall, wall_params)
    # left
    Matter.Bodies.rectangle(  -wall / 2, height / 2, wall, 2 * height + wall, wall_params)
  ]
  #############

  ############
  # Initialize avatar positions
  bodies = []
  params = 
    density: layout_params.density or .1 # significantly heavier than default so they don't overlap as much
    sleepThreshold: layout_params.sleepThreshold or 60 # This is the default
    restitution: layout_params.restitution or 0 # Don't bounce off of each other
    friction: layout_params.friction or .001
    frictionStatic: layout_params.frictionStatic or .3
    frictionAir: layout_params.frictionAir or 0

  for n in init.nodes 
    bd = Matter.Bodies.circle n.x, n.y, init.r, params
    #b = Matter.Bodies.polygon(n.x, n.y, 4, r, params)
    _.extend bd, n
    bodies.push bd 

    bd.before_sleep = 
      x: bd.position.x 
      y: bd.position.y

    bd.original_sleep_threshold = bd.sleepThreshold

  # sort so we can optimize by knowing that bodies are ordered by x_target
  bodies.sort (a,b) -> a.x_target - b.x_target

  Matter.Composite.add engine.world, bodies
  ################




  # Swap the positions and velocities of two avatars if a swap would be worth it
  attempt_swap = (a,b) -> 
    current_distance = Math.abs(a.position.x - a.x_target) + Math.abs(b.position.x - b.x_target)
    swapped_distance = Math.abs(b.position.x - a.x_target) +  Math.abs(a.position.x - b.x_target)

    if current_distance - swapped_distance < .01 && Math.abs(a.position.x - b.position.x) < 1
      return false 

    if a.isSleeping
      Matter.Sleeping.set(a, false)
    if b.isSleeping
      Matter.Sleeping.set(b, false)

    # swap positions
    tmpx = a.position.x
    tmpy = a.position.y

    Matter.Body.setPosition a, b.position
    Matter.Body.setPosition b, 
      x: tmpx
      y: tmpy

    # swap velocity y and zero velocity x
    tmpy = a.velocity.y

    Matter.Body.setVelocity a, 
      x: 0
      y: b.velocity.y
    Matter.Body.setVelocity b, 
      x: 0
      y: tmpy

    a.sleepCounter = 0 
    b.sleepCounter = 0

    a.moved_insignificantly_after_sleep = 0 
    b.moved_insignificantly_after_sleep = 0   

    true


  Events.on engine, "collisionStart", (ev) ->

    for pair in ev.pairs
      a = pair.bodyA
      b = pair.bodyB 

      continue if a.isStatic || b.isStatic

      if (a.position.x < b.position.x && a.x_target > b.x_target) || \
         (a.position.x > b.position.x && a.x_target < b.x_target) 

        attempt_swap(a, b)      



  motionSleepThreshold = layout_params.motionSleepThreshold or .01  
  Matter.Sleeping._motionSleepThreshold = motionSleepThreshold                                               
                                              # The ease at which bodies fall asleep based on their motion. 
                                              # Much lower than default (.08) b/c otherwise the avatars are 
                                              # too soporific and suspended in air
  motionSleepThresholdIncrement = layout_params.motionSleepThresholdIncrement or .00001 
                                              # Each tick, we make it slightly easier for bodies to fall asleep. This is like 
                                              # faux simulated annealing to bring the layout to an end faster.   
  
  wake_every_x_ticks = layout_params.wake_every_x_ticks
  global_swap_every_x_ticks = layout_params.global_swap_every_x_ticks
  total_ticks = 0
  total_sleeping = 0 

  runner = Matter.Runner.create()
  try_swap = 0
  did_swap = 0
  no_swap = 0 


  histo_layout_explorer_options = fetch('histo_layout_explorer_options')



  sweep_all_for_position_swaps = ->
    for body, i in bodies 
      for body2,j in bodies when i < j
        # bodies is ordered by x_target, so we know body.x_target <= body2.x_target
        if body.position.x > body2.position.x && body.x_target != body2.x_target
          attempt_swap(body, body2)

  write_positions = -> 
    positions = {}
    for body in bodies
      o = body.position
      r = body.radius
      i = body.index 
      positions[parseInt(opinions[i].user.substring(6))] = \
        [Math.round((o.x - r) * 10) / 10, Math.round((o.y - r) * 10) / 10, body.isSleeping, body.stability]

    opts.done?(positions)


  _requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame \
                                || window.mozRequestAnimationFrame || window.msRequestAnimationFrame \
                                || (callback) -> 
                                      setTimeout -> 
                                        callback Matter.Common.now()
                                      , 1000 / 60

  #####################
  # How stable is this body?
  # We'll consider the angles of any bodies or edges this body is touching, if any. 
  # The greatest stability is when the maximum angle between touch points in the lower 
  # half circle is just under PI / 2. The worst -- free fall -- is when there are no touch points
  # in the lower half circle, which is simply PI. If the body is resting on the surface,
  # the max angle is PI / 2. Thus stability = 1 - (max_arc - best ) / best, which
  # is 0 for free fall and 1 for resting comfortably. 
  calc_stability = (body, blacklist = {}) -> 
    x = Math.round body.position.x
    y = Math.round body.position.y
    r = body.radius

    # resting on the ground
    return 1 if y + r + 1 >= height 

    if neighbors_last_set != total_ticks
      find_neighbors()

    stabilizing_neighbors = (angle for [other_idx, angle] in body.neighbors when angle < Math.PI && angle > 0 && !blacklist[other_idx])

    # body in freefall
    return 0 if stabilizing_neighbors.length == 0 

    # find the neighbor most centrally below the body
    most_stable = 2 * Math.PI
    for angle in stabilizing_neighbors
      if Math.abs(Math.PI / 2 - angle) < most_stable
        most_stable = angle

    stabilizing_neighbors.sort()

    neighbors = body.neighbors
    if x <= r
      neighbors = neighbors.slice()
      neighbors.unshift ['left edge', Math.PI]
    else if x >= width - r
      neighbors = neighbors.slice()
      neighbors.unshift ['right edge', 0]

    # search for a counterbalancing body. A counterbalancing body will be within π radians on the lower half circle formed
    # from the most stable angle
    for n in neighbors when !blacklist[n[0]]
      n_angle = n[1]
      angle_between = n_angle - most_stable
      if (most_stable < Math.PI / 2 && angle_between > 0 && angle_between < Math.PI) || \
         (most_stable > Math.PI / 2 && angle_between < 0 && angle_between > -Math.PI)
        return 1 # has counterbalancing stabilizing body
    

    # The below will be 1 if there's a stabilizing body directly under it, 
    # and 0 if there's one almost directly to its side
    deviation_from_stable = Math.abs(most_stable - Math.PI / 2)
    1 - deviation_from_stable / (Math.PI / 2)


  evaluate_body_position = (body, occupancy_map) ->

    occupancy_map ?= build_occupancy_map()

    ####################
    # How truthful is the location based on the user's intended position?
    dist = Math.abs(body.position.x - body.x_target)
    dist /= width 

    truth = Math.pow 1 - dist, 2
    body.truth = truth

    ####################
    # How visible? Is it covered up at all?
    r = body.radius
    mask = avatar_mask[r]
    x = Math.round body.position.x
    y = Math.round body.position.y

    left = x - r 
    top = y - r
    overlapped_pixels = 0 
    total_pixels = 0 
    for row in [0..2 * r]
      for col in [0..2 * r]
        if mask[row * 2 * r + col] > 0
          pixel = occupancy_map[(top + row) * width + (left + col)]
          total_pixels += 1
          if pixel > 1
            overlapped_pixels += 1

    percent_visible = 1 - overlapped_pixels / total_pixels
    body.visibility = percent_visible


    body.stability = calc_stability body



    #####################
    # How much space below?
    row = y + r + 2 # +2 instead of +1 to give a little grace
    col = x         # considering the imprecise rounding when
                    # translating into pixel space
    space_below = 0 
    while true 
      break if row >= height 
      pixel = occupancy_map[row * width + col]

      break if pixel > 0  
      space_below += 1
      row += 1

    # We'll levy a much greater penalty for space if this body could simply
    # have been moved straight down
    if space_below > 1                                  
      could_free_fall = true
      row = y + r + 2 # +2 instead of +1 to give a little grace

      for ccol in [col - r .. col + r]
        continue if ccol < 0 || ccol >= width
        could_free_fall &&= occupancy_map[row * width + ccol] == 0
        break if !could_free_fall

      if could_free_fall
        space_below = Math.pow space_below, 3

    body.space_below = space_below

  evaluate_layout = ->
    occupancy_map = build_occupancy_map()


    # judge truth by the *least* well positioned avatar
    truth = 1

    # judge visibility by the *most* hidden avatar
    visibility = 1

    # Judge how stability the layout is based on the sum of the space below the *middle* of each body
    stability = 0

    for body in bodies 
      evaluate_body_position body, occupancy_map

      if body.truth < truth
        truth = body.truth

      if body.visibility < visibility
        visibility = body.visibility

      if body.stability?
        stability += Math.pow body.stability, 2 # body.space_below

    stability /= bodies.length 
    _.extend running_state, {truth, visibility, stability}

    global_running_state[layout_params.param_hash].truth += truth
    global_running_state[layout_params.param_hash].visibility += visibility
    global_running_state[layout_params.param_hash].stability += stability
    global_running_state[layout_params.param_hash].cnt += 1    


  # Instead of laboriously computing the stability of all possible positions for unstable
  # bodies to be moved to, we exploit the shape of the lower most openings to heuristically 
  # eliminate unstable positions. Because the avatars are circles, unstable positions are 
  # those where the y position of an opening is rising or falling (putting something on top
  # at those places would be slippery). So we filter them out by identifying positive (going 
  # from decreasing to increasing) and negative (vice versa) inflection points. These roughly
  # correspond to a stable position resting on top of a body, and nestled in between two 
  # bodies. Flat areas are also stable. 
  Math.dist = (a,b) -> 
    Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))

  filter_openings = (openings, target_radius, filter_to_inflections_and_flats) ->

    radius = target_radius or init.radius

    # Find the first opening from bottom up in each col. These are candidate
    # stable positions to move an unstable body.
    flattened_openings = [] 
    for col in [0..width]
      opening_this_col = 0
      
      for row in [height - 1..0 - 1] by -1
        if row <= height - radius && col >= radius && col <= width - radius && openings[ row * width + col ] == 0 
          opening_this_col = row 
          break 

      flattened_openings.push opening_this_col

    if !filter_to_inflections_and_flats
      return flattened_openings

    candidates = []
    r_long = Math.round(radius * layout_params.cleanup_overlap) - 1
    dist = Math.round(radius/2) - 1
    for i in [0..width]
      y = flattened_openings[i]
      y_prev = flattened_openings[i-dist]
      y_next = flattened_openings[i+dist]
      hypo_pos =
        y: y + r_long
        x: i
      if (!y_next? || ((hypo_pos.y < y) == ( hypo_pos.y < y_next) && Math.dist(hypo_pos, {x: i+dist, y: y_next}) >= r_long)) && \
         (!y_prev? || ((hypo_pos.y < y) == ( hypo_pos.y < y_prev) && Math.dist(hypo_pos, {x: i-dist, y: y_prev}) >= r_long)) 
         
        candidates.push y
      else 
        candidates.push 0 

    return candidates


  _cascade_instability = (body, instabilities, cleanup_stability) ->
    instabilities[body.index] = 1

    if layout_params.cascade_instability 
      for n in body.neighbors 
        nb = bodies[n[0]]
        continue if instabilities[nb.index]
        if calc_stability(nb, instabilities) < cleanup_stability
          _cascade_instability nb, instabilities, cleanup_stability


  get_unstable_bodies = (cleanup_stability) ->
    instabilities = {}
    for body in bodies 
      if calc_stability(body) < cleanup_stability
        _cascade_instability body, instabilities, cleanup_stability

    unstable = (bodies[k] for k,v of instabilities when v == 1)
    positive = (b for b in unstable when b.x_target <= width)
    negative = (b for b in unstable when b.x_target > width)

    positive.sort (a,b) -> b.x_target - a.x_target
    negative.sort (a,b) -> a.x_target - b.x_target
    negative.concat positive

  get_highest_bodies = ->
    highest = []
    for body in bodies 
      continue if body.position.y >= height - body.radius
      has_body_on_top = false
      for n in body.neighbors
        if n[1] > Math.PI * 1.1
          has_body_on_top = true 
          break
      if !has_body_on_top
        highest.push body 

    highest


  cleanup_overlap = layout_params.cleanup_overlap or 2
  cleanup_layout = (cleanup_stability) ->
    cleanup_stability = cleanup_stability or layout_params.cleanup_stability or .7

    self_available = no_self_available = self_should_be_available = below_self = above_self = 0 

    if layout_params.verbose
      running_state.cleanup ?= []
    current_cleanup = []

    iterations = 0 
    exhausted_prime = !layout_params.filter_to_inflections_and_flats 

    openings = build_openings()
    while true 
      # openings = build_openings()
      num_changed = 0

      unstable_bodies = get_unstable_bodies(cleanup_stability)

      if layout_params.restack_top && unstable_bodies.length > 0 && iterations < 1
        unstable_bodies = unstable_bodies.concat get_highest_bodies()

      # this is unneeded except in testing
      if layout_params.verbose && histo_layout_explorer_options.show_explorer
        occupancy = build_occupancy_map()

      # remove these unstable bodies from the map so that its position within the current 
      # body might be selected 
      for body, i in unstable_bodies
        imprint_body_on_map openings, body, -1, Math.round(body.radius * cleanup_overlap) - 1

        if layout_params.verbose && histo_layout_explorer_options.show_explorer
          imprint_body_on_map occupancy, body, -1, body.radius

      for body, i in unstable_bodies
        r = body.radius
        x = Math.round(body.position.x)
        y = Math.round(body.position.y)
        x_target = Math.round(body.x_target)

        move_within = Math.round width * .125
        bounds = [x_target - move_within, x_target + move_within]
        if bounds[0] > x
          bounds[0] = x         # allow it to stay in the same row, even though it 
        else if bounds[1] < x   # is targetting a ways away
          bounds[1] = x 

        options = filter_openings openings, body.radius, !exhausted_prime
        candidates = []
        for col in [bounds[0]..bounds[1]]
          continue if col < r || col >= width - r 
          if options[col] > 0
            score = Math.log(options[col] + 1) / Math.abs( (body.x_target - col) / width )
            candidates.push [col, options[col], score]
        #########

        candidates.sort (a,b) -> b[2] - a[2]

        top_candidate = candidates[0]
        if top_candidate && (top_candidate[0] != x || top_candidate[1] != y)
          # wake it up and set a new position
          if body.isSleeping
            Matter.Sleeping.set(body, false)
          body.sleepCounter = 0
          body.moved_insignificantly_after_sleep = 0 

          Matter.Body.setPosition body, {x: top_candidate[0], y: top_candidate[1]}

          if layout_params.verbose && histo_layout_explorer_options.show_explorer
            current_cleanup.push 
              body: JSON.parse JSON.stringify {position: body.position, radius: body.radius, x_target: body.x_target, index: body.index}
              from: {x, y}
              to: {x: body.position.x, y: body.position.y}
              candidates: candidates
              openings: JSON.parse JSON.stringify openings # build_openings()
              occupancy: JSON.parse JSON.stringify occupancy 
              prime_positions: JSON.parse JSON.stringify options
              unstable_bodies: JSON.parse JSON.stringify ({index: b.index, position: b.position, radius: b.radius} for b in unstable_bodies)
              bodies: ({neighbors: b.neighbors, position: b.position, radius: b.radius, index: b.index} for b in bodies)

          num_changed += 1

        imprint_body_on_map openings, body, 1, Math.round(body.radius * cleanup_overlap) - 1
        if layout_params.verbose && histo_layout_explorer_options.show_explorer
          imprint_body_on_map occupancy, body, 1, r


      # console.log "Changed #{num_changed} positions"
      if num_changed == 0 || iterations > 100
        if exhausted_prime   
          # console.log "Done!", {iterations, unstable_bodies, candidates}  
          break
        else 
          exhausted_prime = true
          iterations = 0 

      find_neighbors()
      iterations += 1
    if layout_params.verbose && current_cleanup.length > 0
      running_state.cleanup.push current_cleanup


  # Returns array representing a 2d width x height map of which pixels are occupied
  # by avatars. Each cell has the number of avatars occupying that space.
  avatar_mask = {} # keys are radii  
  circle_adjustment = {} # keys are radii
  build_occupancy_map = (r_mult = 1) -> 
    size = width * height 
    occupancy_map = new Int32Array width * height 
    
    for body in bodies
      if r_mult > 1
        r = Math.round(body.radius * r_mult) - 1
      else 
        r = body.radius

      # build a mask for the square around the body that shows which pixels
      # in the square are covered by the circle
      mask = avatar_mask[r]
      if !mask
        mask = avatar_mask[r] = new Int32Array 4 * r * r
        col = row = 0 
        while row < 2 * r
          while col < 2 * r
            if Math.sqrt( ( r - .5 - row) * ( r - .5 - row ) + ( r - .5 - col ) * ( r - .5 - col ) ) < r
              mask[ row * 2 * r + col ] = 1    # the .5 in the distance calculation is to move to the true center of the circle
            col += 1
          row += 1
          col = 0

      imprint_body_on_map occupancy_map, body, 1, r 

    occupancy_map

  imprint_body_on_map = (occupancy_map, body, increment = 1, radius = null, v) ->
    # imprint the body's mask on the occupancy map
    # get the start offset of the occupancy map at which to start imprinting
    r = Math.round(radius or body.radius)
    x = Math.round body.position.x 
    y = Math.round body.position.y
    mask = avatar_mask[r]    
    row = y - r 
    col = x - r
    mask_row = mask_col = 0 
    while mask_row < 2 * r
      offset_row = row + mask_row 
      
      if offset_row >= 0 && offset_row < height
        while mask_col < 2 * r
          offset_col = col + mask_col 

          if offset_col > 0 && offset_col < width && mask[ mask_row * 2 * r + mask_col ]
            # imprint
            occupancy_map[offset_row * width + offset_col] += increment
            # console.log "Set #{offset_row * width + offset_col} to #{occupancy_map[offset_row * width + offset_col]}"

          mask_col += 1


      mask_row += 1
      mask_col = 0

  # An opening is a place where a body could move. Computed using the occupancy map, just doubling 
  # the radius of all bodies. Any entry in the occupancy map that remains zero is free. 
  # Then scan through and set as a valid spot to move to. 
  build_openings = ->
    build_occupancy_map(cleanup_overlap)  



  # Determines which bodies are adjacent to a body. For each body, sets the angle {0, 360º} which represents 
  # the angle at which the body is touched by the other body. 
  # 0 is the right, 90º is the middle bottom, 180º is the left, 270º is the middle top.
  # 
  # epsilon is a little extra that will help bodies that are *almost* touching to be considered touching.

  a90  = Math.PI / 2
  a180 = Math.PI
  a270 = 3 * Math.PI / 2
  a360 = 2 * Math.PI
  neighbors_last_set = -1
  find_neighbors = (epsilon = 1) -> 
    n = bodies.length

    for body in bodies 
      body.neighbors = []

    i = 0 
    while i < n 
      j = i + 1
      a = bodies[i]

      while j < n     
        b = bodies[j]

        if b.position.y < a.position.y || (b.position.y == a.position.y && a.position.x > b.position.x) 
          aa = bodies[j]; bb = bodies[i] # make sure a is always at least as high as b; for ease in computing angles
        else 
          aa = bodies[i]; bb = bodies[j]

        a_x = aa.position.x; a_y = aa.position.y 
        b_x = bb.position.x; b_y = bb.position.y
        a_r = aa.radius; b_r = bb.radius

        dist = Math.sqrt (a_x - b_x) * (a_x - b_x) + (a_y - b_y) * (a_y - b_y)
        if dist <= a_r + b_r + epsilon

          if a_y == b_y 
            a_angle = 0
            b_angle = a180
          else if a_x == b_x 
            a_angle = a90
            b_angle = a270
          else 
            angle = Math.atan( Math.abs(a_x - b_x) / Math.abs(a_y - b_y) )
            if a_x < b_x
              a_angle = a90 - angle
              b_angle = a180 + (a90 - angle)
            else 
              a_angle = a90 + angle
              b_angle = a360 - (a90 - angle)

          aa.neighbors.push [bb.index, a_angle]
          bb.neighbors.push [aa.index, b_angle]

        j += 1
      i += 1

    neighbors_last_set = total_ticks


  ############################
  # Each time step, move each avatar toward its desired x-target. 
  # The default gravity in the layout_params engine is also enabled, so 
  # each avatar also has a downwards force applied. 

  engine.world.gravity.scale = layout_params.gravity_scale or .000012  
                                        # much less gravity than default (.001); if it is too high, 
                                        # avatars are compacted on top of each other.
  
  x_force_mult = layout_params.x_force_mult or .006
  beforeTick = ->
    
    for body in bodies 
      continue if body.isStatic || body.isSleeping

      # Move the avatar toward the target with force proportional 
      # to its distance away from it. 
      dist_to_target = body.x_target - body.position.x
      
      x_push = dist_to_target * x_force_mult

      ################
      # Attempted optimization: if the avatar strings together a series of unblocked 
      # movements, boost their speed, as it suggests they may be unimpeded. 
      # Helps especially with convergence on histograms with few avatars. 
      if layout_params.enable_boosting
        body.last_push ?= x_push
        boostable = Math.abs(dist_to_target + body.last_push - body.last_dist_target) < .0000000000001
        # console.log boostable, Math.abs(dist_to_target + body.last_push - body.last_dist_target)
        if boostable 
          if body.boost_streak > 0
            # console.log "boosted"
            x_push = x_push * body.boost_streak
          body.boost_streak += 1
        else 
          x_push = x_push
          body.boost_streak = 0 
        body.last_push = x_push
        body.last_dist_target = dist_to_target
      ################

      # Apply the push toward the desired x-target
      Matter.Body.translate body, {x: x_push, y: 0}




  ticks_since_last_cleanup = 100
  current_cleanup_stability = layout_params.cleanup_stability
  afterTick = (ev) ->

    Matter.Sleeping._motionSleepThreshold += motionSleepThresholdIncrement 

    total_sleeping = 0 
    for body,i in bodies 
      x = body.position.x 
      y = body.position.y
      x_target = body.x_target

      # Don't let bodies fall through the bottom
      if y > height 
        Matter.Body.setPosition body, {x: x, y: height}
        y = height

      ##############
      # wake bodies up periodically to see if space opened up for them while they were sleeping
      if wake_every_x_ticks && total_ticks % wake_every_x_ticks == wake_every_x_ticks - 1
        if body.isSleeping

          # Check how much this body moved since the last time it was woke. If it didn't move much,
          # then put it to sleep quicker this time.
          if layout_params.reduce_sleep_threshold_if_little_movement
            reduction_exponent = layout_params.sleep_reduction_exponent or .7 
            body.moved_insignificantly_after_sleep ?= 0
            if body.before_sleep
              xs = body.position.x 
              xy = body.position.y
              dist = Math.sqrt( (x-xs) * (x-xs) + (y-xy) * (y-xy)  )
              if dist < .00000001
                body.moved_insignificantly_after_sleep += 1
              else if body.moved_insignificantly_after_sleep > 0
                body.moved_insignificantly_after_sleep = 0

            body.sleepThreshold = body.original_sleep_threshold * Math.pow(reduction_exponent, (1 + body.moved_insignificantly_after_sleep))

            body.before_sleep = 
              x: x
              y: y

          Matter.Sleeping.set(body, false)

          # Give it a little nudge down after it awakens
          body.force.y += 2 * body.mass * engine.world.gravity.y * engine.world.gravity.scale
      ##########################


      if body.isSleeping 
        total_sleeping += 1


    #############################
    # Swap positions when advantageous. Don't do it every tick for performance reasons, as this is n^2.
    global_position_swap = global_swap_every_x_ticks && total_ticks % global_swap_every_x_ticks == global_swap_every_x_ticks - 1 
    if global_position_swap
      sweep_all_for_position_swaps()
    ##########

    if layout_params.cleanup_layout_every_x_ticks
      if total_sleeping > bodies.length * layout_params.cleanup_when_percent_sleeping && ticks_since_last_cleanup > layout_params.cleanup_layout_every_x_ticks        
        
        if current_cleanup_stability > 0
          cleanup_layout(current_cleanup_stability)
          if layout_params.change_cleanup_stability?
            current_cleanup_stability += layout_params.change_cleanup_stability
          if global_swap_every_x_ticks
            sweep_all_for_position_swaps()      
        ticks_since_last_cleanup = 0 
      else 
        ticks_since_last_cleanup += 1

    # stop when all the avatars are sleeping or we've given up 
    done = total_ticks > 2000 || total_sleeping / bodies.length >= layout_params.end_sleep_percent

    done ||= opts.abort?()

    if done

      if layout_params.cleanup_layout_every_x_ticks
        if layout_params.final_cleanup_stability 
          current_cleanup_stability = layout_params.final_cleanup_stability

        if current_cleanup_stability > 0
          cleanup_layout(current_cleanup_stability)

      if global_swap_every_x_ticks
        sweep_all_for_position_swaps()

      Matter.Runner.stop(runner)
      runner.enabled = false

    total_ticks += 1

  Matter.Runner.run = (runner, engine) ->

    update_verbose = (tick_time) ->
      running_state.layout_time ?= 0 
      running_state.layout_time += tick_time
      global_running_state[layout_params.param_hash].tick_time += tick_time

      find_neighbors()
      evaluate_layout()
      running_state.occupancy_map = build_occupancy_map()
      running_state.openings = build_openings()
      running_state.bodies = ( {index: b.index, position: b.position, radius: b.radius, neighbors: b.neighbors} for b in bodies )
      running_state.ticks = total_ticks
      _.extend running_state, 
        '%_sleeping': "#{(100 * total_sleeping / bodies.length).toFixed(1)}%"
        ticks: total_ticks

      save running_state
      save global_running_state


    after_run = ->
      write_positions()
      histo_run_next_job(opts)

    if layout_params.show_histogram_physics
      renderer = (time) -> 
        runner.frameRequestId = _requestAnimationFrame(renderer)

        if time && runner.enabled
          if layout_params.verbose
            t0 = performance.now()

          beforeTick()
          Engine.update(engine)
          afterTick()

          if layout_params.verbose
            update_verbose performance.now() - t0

          write_positions()

        if !runner.enabled
          after_run()

      renderer()

    else 
      setTimeout ->

        if layout_params.verbose
          t0 = performance.now()

        # console.profile(opts.running_state)
        while runner.enabled 
          beforeTick()
          Engine.update(engine)
          afterTick()
        # console.profileEnd(opts.running_state)

        if layout_params.verbose
          update_verbose performance.now() - t0

        after_run()
      , 0

    runner


  if layout_params.verbose
    # console.profile(running_state.key)

    running_state = fetch opts.running_state
    global_running_state = fetch 'histo-timing'

    global_running_state[layout_params.param_hash] ?=
      tick_time: 0 
      truth: 0
      visibility: 0
      stability: 0
      cnt: 0

  Matter.Runner.run runner, engine




#####
# Calculate node radius based on the largest density of avatars in an 
# area (based on a moving average of # of opinions, mapped across the
# width and height)
calculateAvatarRadius = (width, height, opinions, {fill_ratio}) -> 

  fill_ratio ?= .25

  filter_out = fetch 'filtered'
  if filter_out.users && !filter_out.enable_comparison
    opinions = (o for o in opinions when !(filter_out.users?[o.user]))

  opinions.sort (a,b) -> a.stance - b.stance

  # find most dense region of opinions
  window_size = .05
  avg_inc = .025
  max_opinions = 0
  idx = 0
  stance = -1.0 

  while stance <= 1.0 + window_size

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

    if cnt > max_opinions
      max_opinions = cnt 

    stance += avg_inc


  # Calculate the avatar radius we'll use. It is based on 
  # trying to fill fill_ratio of the densest area of the histogram
  if max_opinions > 0 
    effective_width = width * 2 * window_size
    area_per_avatar = fill_ratio * effective_width * height / max_opinions
    r = Math.sqrt(area_per_avatar) / 2

  else 
    r = Math.sqrt(width * height / opinions.length * fill_ratio) / 2

  r = Math.min(r, width / 2, height / 2)

  Math.round r















######
# Uses a d3-based layout_params simulation to calculate a reasonable layout
# of avatars within a given area.
positionAvatarsWithD3 = (opts) -> 

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
    setTimeout ->
      positions = {}
      for o, i in nodes
        positions[parseInt(opinions[i].user.substring(6))] = \
          [Math.round((o.x - o.radius) * 10) / 10, Math.round((o.y - o.radius) * 10) / 10, false, o.stability]

      opts.done?(positions)

  {nodes, targets, opinions, width, height, r} = initialize_positions opts
  bodies = nodes 
  layout_params = opts.layout_params

  ###########
  # run the simulation
  stable = false
  alpha = layout_params.alpha or .8
  decay = layout_params.decay or .8
  min_alpha = layout_params.min_alpha or 0.0000001
  x_force_mult = layout_params.x_force_mult or 2
  y_force_mult = layout_params.y_force_mult or 2

  total_ticks = 0
  collisions = 0 

  if layout_params.verbose
    # console.profile(running_state.key)

    running_state = fetch opts.running_state
    global_running_state = fetch 'histo-timing'

    global_running_state[layout_params.param_hash] ?=
      tick_time: 0 
      truth: 0
      visibility: 0
      stability: 0
      cnt: 0


  update_verbose = (tick_time) ->
    running_state.layout_time ?= 0 
    running_state.layout_time += tick_time
    global_running_state[layout_params.param_hash].tick_time += tick_time
    global_running_state[layout_params.param_hash].cnt += 1

    running_state.ticks = total_ticks
    _.extend running_state, 
      ticks: total_ticks

    save running_state
    save global_running_state

  after_run = ->
    write_positions()
    histo_run_next_job(opts)

  if opts.layout_params?.show_histogram_physics

    _requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame \
                                  || window.mozRequestAnimationFrame || window.msRequestAnimationFrame \
                                  || (callback) -> 
                                        setTimeout -> 
                                          callback()
                                        , 1000 / 60

    iterate = => 
      if layout_params.verbose
        t0 = performance.now()

      stable = tick alpha

      alpha *= decay
      total_ticks += 1

      # console.log "Tick: #{total_ticks} Collisions: #{collisions}"
      collisions = 0

      stable ||= alpha <= min_alpha


      if layout_params.verbose
        update_verbose performance.now() - t0

      aborted = opts.abort?()
      if stable || aborted
        # console.profileEnd(opts.running_state)
        after_run()

      else 
        write_positions()
        _requestAnimationFrame iterate


    iterate()

  else 

    if layout_params.verbose
      t0 = performance.now()

    while true
      stable = tick alpha
      alpha *= decay
      total_ticks += 1

      stable ||= alpha <= min_alpha

      aborted = opts.abort?()
      break if stable || aborted

    if layout_params.verbose
      update_verbose performance.now() - t0

    after_run()



