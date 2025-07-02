# require './browser_hacks'
# require './histogram_layout'

# # require './histogram_lab'  # for testing only


# # md5 = require './vendor/md5' 

# ##
# # Histogram
# #
# # Controls the display of the users arranged on a histogram. 
# # 
# # The user avatars are arranged imprecisely on the histogram
# # based on the user's opinion, using a layout_params simulation. 
# #
# # The pros and cons can be filtered to specific opinion regions
# # (individual and collective). 
# #
# ##
# # Props
# # 
# #   opinions
# #     The opinions to show in the histogram. 
# #   width, height
# #   enable_individual_selection (default = false)
# #     Whether individual users can be selected on the histogram
# #   enable_range_selection (default = false)
# #     Whether ranges can be selected on the histogram
# #   selection_state (default = @props.histo_key)
# #     The state key at which selection state will be updated
# #   draw_base (default = false)
# #     Whether to draw a base with +/- labels. If a slider is attached,
# #     don't need the labels.
# #   backgrounded (default = false)
# #     If backgrounded, the histogram avatars are dimmed, and interactivity
# #     disabled. 
# #
# ##
# # The interaction rules: 
# #
# # Selection
# #   * Click on a user in the histogram, show that user's opinion:
# #      - Filter decision board points to those included by this user
# #      - Show a second, larger image of the user and their name in
# #         the region between the histogram and decision board
# #   * Click an area of the histogram unoccupied by a user, when 
# #     not already in selection mode, to enter selection mode:
# #      - Show the collective opinions of the users in that region. 
# #         Rerank the points in the decision board accordingly.
# #   * Move the mouse in histogram when in group selection mode:
# #      - selected opinions dynamically updated based on mouse position 
# #      - selection region stays entirely within the histogram 
# #   * Drag the edges of the region selection top edge to resize the selection
# #
# # Deselection
# #   * If a single user is selected, clicking anywhere outside of that 
# #     user's picture in the histogram or opinion area will deselect
# #   * If a region is selected, clicking anywhere except within the 
# #     decision board will deselect the region.
# #
# # Note that for mobile, region resizing is disabled, and the selection 
# # changes on touch move rather than mousemove.
# # 
# ##
# # Selected region background
# #   * A selection region background follows the mouse in the histogram if:
# #      - we're in group selection mode
# #      - we're hovering over the histogram in 
# #   * Show a border at the top if in group selection mode
# #
# # The selection region is imprecise. It defines
# # a selection region based on the real values of the users' opinions,
# # _not_ the imprecise location of the avatar's position on the 
# # histogram. This can cause some confusion as to who will be 
# # highlighted. 
# #
# # Other components can also request that certain users be 
# # highlighted in the histogram, though the pros/cons will 
# # NOT be filtered as a consequence of the highlighting. 
# # This occurs when someone mouses over the inclusion pogs
# # for a point. 
# #
# # State design for histogram:
# #
# # Global state:
# #   selection_opinion
# #      If set, an opinion key for an avatar that was clicked
# #   selected_opinions
# #      Array of opinion keys defining the current set of selected opinions. 
# #   selected_opinion_value
# #      The opinion value around which the current selection is defined  
# #   highlighted_users
# #      Users that other components want to have highlighted in the 
# #      histogram. In the render, this is intersected with the users whose 
# #      opinions are selected to determine which avatars are highlighted. 
# #
# # Local state: 
# #   simulation_opinion_hash
# #      Hash of all opinion stances. Used to determine if the layout_params
# #      simulation needs to be rerun on a rerender.
# #   mouse_opinion_value
# #      Stores the mapped opinion value of the current mouse position
# #      within the histogram. 
# #   avatar_size
# #      The base size of the avatars, as determined by the layout_params 
# #      simulation. This piece of state would be local, but it needs
# #      to be settable from the layout_params simulation.

# # Accessibility notes: 
# #   - histogram itself should be tabbable. Should summarize results. 
# #   - pressing enter should make avatars navigable via tabbing keys. state is @local.navigating_inside
# #   - pressing escape makes avatars unfocusable and returns focus to the histogram.
# #   - histogram should close navigation when it loses focus 
# #   - need to provide instructions, probably in tooltip or aria-describedby.


# # require './vendor/d3.v3.min'
# require './shared'

# # REGION_SELECTION_WIDTH controls the size of the selection region when 
# # hovering over the histogram. It defines the opinion bounds within which 
# # opinions are selected. Opinions = [-1, 1]. REGION_SELECTION_WIDTH is 
# # on this scale. 
# window.REGION_SELECTION_WIDTH = .25

# # Controls the size of the vertical space at the top of 
# # the histogram that gives some space for users to hover over 
# # the most populous areas
# REGION_SELECTION_VERTICAL_PADDING = 30


# window.show_histogram_layout = false


# is_histogram_controlling_region_selection = (key) -> 
#   opinion_views = bus_fetch 'opinion_views'
#   active = opinion_views.active_views
#   originating_histogram = opinion_views.active_views.region_selected?.created_by
  
#   !originating_histogram? || originating_histogram == key

# window.clear_histogram_managed_opinion_views = (opinion_views, field) ->
#   opinion_views ?= bus_fetch 'opinion_views'
#   if field 
#     delete opinion_views.active_views[field]
#   else 
#     delete opinion_views.active_views.single_opinion_selected
#     delete opinion_views.active_views.region_selected
#     delete opinion_views.active_views.point_includers
#   save opinion_views


# window.select_single_opinion = (user_opinion, created_by) ->
#   opinion_views = bus_fetch 'opinion_views'

#   is_deselection = opinion_views.active_views.single_opinion_selected?.opinion == user_opinion.key
#   if is_deselection
#     clear_histogram_managed_opinion_views opinion_views
#   else 
#     opinion_views.active_views.single_opinion_selected =
#       created_by: created_by
#       opinion: user_opinion.key 
#       opinion_value: user_opinion.stance 
#       get_salience: (u, opinion, proposal) =>
#         if (u.key or u) == user_opinion.user
#           1
#         else 
#           .1
#       get_weight: (u, opinion, proposal) =>
#         if (u.key or u) == user_opinion.user
#           1
#         else 
#           .1

#     clear_histogram_managed_opinion_views opinion_views, 'region_selected'



# styles += """
#   .histogram {
#     position: relative;
#     user-select: none;
#     -moz-user-select: none;
#     -webkit-user-select: none;
#     -ms-user-select: none;
#   }
#   .histoavatars-container {
#     contentvisibility: auto; /* enables browsers to not draw expensive histograms in many situations */
#   }
# """

# window.Histogram = ReactiveComponent
#   displayName : 'Histogram'

#   render: -> 
#     subdomain = bus_fetch '/subdomain'

#     loc = bus_fetch 'location'
#     if loc.query_params.show_histogram_layout
#       window.show_histogram_layout = true

#     proposal = bus_fetch @props.proposal

#     opinion_views = bus_fetch 'opinion_views'

#     opinions = @props.opinions

#     if running_timelapse_simulation?
#       opinions = (o for o in opinions when passes_running_timelapse_simulation(o.created_at or o.updated_at))
    

#     {weights, salience, groups} = compose_opinion_views opinions, proposal
#     @weights = weights
#     @salience = salience 
#     @groups = groups
#     @opinions = opinions = get_opinions_for_proposal opinions, proposal, weights
#     @opinions.sort (a,b) -> a.stance - b.stance

#     @props.draw_base_labels ?= true


#     enable_individual_selection = @props.enable_individual_selection && @opinions.length > 0
#     @enable_range_selection = @props.enable_range_selection && opinions.length > 1

#     # whether to show the shaded opinion selection region in the histogram
#     draw_selection_area = @enable_range_selection &&
#                             !opinion_views.active_views.single_opinion_selected && 
#                             !@props.backgrounded &&
#                             (opinion_views.active_views.region_selected || 
#                               (!@local.touched && 
#                                 @local.mouse_opinion_value && 
#                                 !@local.hovering_over_avatar))


#     histo_height = @props.height + REGION_SELECTION_VERTICAL_PADDING
    
#     @id = "histo-#{@local.key.replace(/\//g, '__')}"
#     histogram_props = 
#       id: @id
#       key: 'histogram'
#       tabIndex: if !@props.backgrounded then 0

#       className: 'histogram'
#       'aria-hidden': @props.backgrounded
#       'aria-labelledby': if !@props.backgrounded then "##{proposal.id}-histo-label"
#       'aria-describedby': if !@props.backgrounded then "##{proposal.id}-histo-description"

#       style:
#         width: @props.width
#         height: histo_height


#       onKeyDown: (e) =>
#         if e.which == 32 # SPACE toggles navigation
#           @local.navigating_inside = !@local.navigating_inside 
#           save @local 
#           e.preventDefault() # prevent scroll jumping
#           if @local.navigating_inside
#             ReactDOM.findDOMNode(@).querySelector('.avatar')?.focus()
#           else 
#             ReactDOM.findDOMNode(@).focus()
#         else if e.which == 13 && !@local.navigating_inside # ENTER 
#           @local.navigating_inside = true 
#           ReactDOM.findDOMNode(@).querySelector('.avatar')?.focus()
#           save @local 
#         else if e.which == 27 && @local.navigating_inside
#           @local.navigating_inside = false
#           ReactDOM.findDOMNode(@).focus() 
#           save @local 
#       onBlur: (e) => 
#         setTimeout => 
#           # if the focus isn't still on this histogram, 
#           # then we should reset its navigation

#           if @local.navigating_inside && !$$.closest(document.activeElement, "##{@id}")
#             @local.navigating_inside = false; save @local
#         , 0

#     score = 0
#     for o in opinions 
#       score += o.stance
#     avg = score / opinions.length
#     negative = score < 0
#     score *= -1 if negative
#     score = pad score.toFixed(1),2

#     if avg < -.03
#       exp = "#{(-1 * avg * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", @props.proposal, subdomain)}"
#     else if avg > .03
#       exp = "#{(avg * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", @props.proposal, subdomain)}"
#     else 
#       exp = translator "sliders.feedback-short.neutral", "Neutral"


#     if @enable_range_selection || enable_individual_selection
#       if !browser.is_mobile
#         _.extend histogram_props,
#           onClick: @onClick
#           onMouseMove: @onMouseMove
#           onMouseLeave: @onMouseLeave
#           onMouseDown: @onMouseDown

#       else 
#         _.extend histogram_props,

#           onTouchStart: (ev) => 
#             curr_time = new Date().getTime()
#             # activation by double tap
#             if @local.last_tapped_at && curr_time - @local.last_tapped_at < 300
#               ev.preventDefault()
#               @local.touched = true
#               save @local
#               @onClick(ev)
#             else 
#               @local.last_tapped_at = curr_time
#               save @local

#           onTouchMove: (ev) => ev.preventDefault(); @onMouseMove(ev)
#           onTouchEnd: (ev) => 
#             curr_time = new Date().getTime()
#             # activation by double tap
#             @local.last_tapped_at = curr_time
#             save @local

#     if @props.flip 
#       flip_id = "histogram-#{proposal.key}"

#     histo = DIV histogram_props, 
#       DIV 
#         key: 'accessibility-histo-label'
#         id: "##{proposal.id}-histo-label"
#         className: 'hidden'
        
#         translator 
#           id: "engage.histogram.explanation"
#           num_opinions: opinions.length 
#           "Histogram showing {num_opinions, plural, one {# opinion} other {# opinions}}"

#       DIV 
#         key: 'accessibility-histo-description'
#         id: "##{proposal.id}-histo-description"
#         className: 'hidden'

#         translator 
#           id: "engage.histogram.explanation_extended"
#           num_opinions: opinions.length 
#           avg_score: exp
#           negative_pole: get_slider_label("slider_pole_labels.oppose", @props.proposal, subdomain)
#           positive_pole: get_slider_label("slider_pole_labels.support", @props.proposal, subdomain)

#           """{num_opinions, plural, one {one person's opinion of} other {# people's opinion, with an average of}} {avg_score} 
#              on a spectrum from {negative_pole} to {positive_pole}. 
#              Press ENTER or SPACE to enable tab navigation of each person's opinion, and ESCAPE to exit the navigation.
#           """         



#       # A little padding at the top to give some space for selecting
#       # opinion regions with lots of people stacked high      
#       DIV key: 'vert-padding', style: {height: @local.region_selected_vertical_padding}

#       # Draw the opinion selection area + region resizing border
#       if draw_selection_area
#         @drawSelectionArea()

#       if @props.flip && false
#         FLIPPED 
#           inverseFlipId: flip_id
#           shouldInvert: => @props.flip_state_changed
#           DIV null, 
#             FLIPPED 
#               flipId: flip_id + 'slidergram-avatars'
#               shouldFlip: => @props.flip_state_changed
#               @drawAvatars {histo_height, enable_individual_selection}
#       else 
#         @drawAvatars {histo_height, enable_individual_selection}


#       if @props.draw_base 
#         base = DIV 
#                  className: 'slidergram-base' 
#                  style: 
#                    width: '100%'
#                    height: @props.base_style?.height or 1
#                    backgroundColor: @props.base_style?.color or "#999"
        
#         if @props.flip
#           FLIPPED 
#             inverseFlipId: flip_id
#             shouldInvert: => @props.flip_state_changed
#             DIV null, 
#               FLIPPED 
#                 flipId: flip_id + 'slidergram-base'
#                 shouldFlip: => @props.flip_state_changed
#                 base

#         else 
#           base


#       if @props.draw_base_labels
#         if @props.flip 
#           FLIPPED 
#             inverseFlipId: flip_id
#             shouldInvert: => @props.flip_state_changed

#             DIV null,
#               @drawHistogramLabels(subdomain, proposal)
#         else 
#           @drawHistogramLabels(subdomain, proposal)
    

#     if @props.flip
#       FLIPPED 
#         flipId: flip_id
#         shouldFlip: => @props.flip_state_changed
#         translate: true
#         histo
#     else 
#       histo

#   drawAvatars: ({histo_height, enable_individual_selection}) -> 

#     DIV 
#       className: 'histoavatars-container'
#       key: 'histoavatars'
#       style: 
#         paddingTop: histo_height - @props.height
#         # height: histo_height
#         # backgroundColor: 'red'

#       HistoAvatars
#         histo_key: @props.proposal.key or @props.proposal   
#         weights: @weights
#         salience: @salience
#         groups: @groups
#         enable_individual_selection: enable_individual_selection
#         enable_range_selection: @enable_range_selection
#         height: @props.height 
#         width: @props.width
#         backgrounded: @props.backgrounded
#         opinions: @opinions 
#         navigating_inside: @local.navigating_inside
#         layout_params: @props.layout_params



#   drawHistogramLabels: (subdomain, proposal) -> 

#     subdomain ?= bus_fetch '/subdomain'
#     label_style = @props.label_style or {
#       fontSize: 12
#       fontWeight: 400
#       color: '#555'
#       bottom: -19
#     }

#     negative =  SPAN
#                   key: 'oppose'
#                   style: _.extend {}, label_style,
#                     position: 'absolute'
#                     left: 0

#                   get_slider_label("slider_pole_labels.oppose", @props.proposal, subdomain)

#     positive = 

#       SPAN
#         key: 'support'
#         style: _.extend {}, label_style,
#           position: 'absolute'
#           right: 0

#         get_slider_label("slider_pole_labels.support", @props.proposal, subdomain)

#     if @props.flip 
#       flip_id = "histogram-#{proposal.key}"

#       [
#         FLIPPED
#           key: 'negative'
#           flipId: "histogram-#{proposal.key}-negative-pole"
#           shouldFlip: => @props.flip_state_changed
#           negative
#         FLIPPED
#           key: 'positive'
#           flipId: "histogram-#{proposal.key}-positive-pole"
#           shouldFlip: => @props.flip_state_changed
#           positive
#       ]

#     else 
#       [negative, positive]

#   drawSelectionArea: -> 

#     opinion_views = bus_fetch 'opinion_views'

#     anchor = opinion_views.active_views.single_opinion_selected or @local.mouse_opinion_value
#     left = ((anchor + 1)/2 - REGION_SELECTION_WIDTH/2) * @props.width
#     base_width = REGION_SELECTION_WIDTH * @props.width
#     selection_width = Math.min( \
#                         Math.min(base_width, base_width + left), \
#                         @props.width - left)
#     selection_left = Math.max 0, left


#     return DIV {key: 'selection_label'} if !is_histogram_controlling_region_selection(@props.histo_key) 
#     DIV 
#       key: 'selection_label'
#       style:
#         height: @props.height + REGION_SELECTION_VERTICAL_PADDING
#         position: 'absolute'
#         width: selection_width
#         backgroundColor: "#F7F7F7"
#         cursor: 'pointer'
#         left: selection_left
#         top: -2 #- REGION_SELECTION_VERTICAL_PADDING
#         borderTop: "2px solid"
#         borderTopColor: if opinion_views.active_views.region_selected then focus_color else 'transparent'

#       if !opinion_views.active_views.region_selected
#         DIV
#           style: 
#             fontSize: 12
#             textAlign: 'center'
#             whiteSpace: 'nowrap'
#             marginTop: -3 #-9
#             marginLeft: -4
#             userSelect: 'none'
#             MozUserSelect: 'none'
#             WebkitUserSelect: 'none'
#             msUserSelect: 'none'            
#             pointerEvents: 'none'

#           TRANSLATE "engage.histogram.select_these_opinions", 'highlight opinions'

#   onClick: (ev) -> 

#     ev.stopPropagation()

#     opinion_views = bus_fetch 'opinion_views'

#     single_selection = opinion_views.active_views.single_opinion_selected
#     region_selected = opinion_views.active_views.region_selected

#     if @props.backgrounded
#       if @props.on_click_when_backgrounded
#         @props.on_click_when_backgrounded()

#     else
#       if ev.type == 'touchstart'
#         @local.mouse_opinion_value = @getOpinionValueAtFocus(ev)

#       is_clicking_user = ev.target.classList.contains('avatar')

#       if is_clicking_user
#         user_key = ev.target.getAttribute('data-user')
#         user_opinion = _.findWhere @opinions, {user: user_key}

#         if @weights[user_key] == 0 || @salience[user_key] < 1
#           clear_histogram_managed_opinion_views opinion_views
#         else 
#           select_single_opinion user_opinion, @props.histo_key

#       else
#         max = @local.mouse_opinion_value + REGION_SELECTION_WIDTH
#         min = @local.mouse_opinion_value - REGION_SELECTION_WIDTH

#         is_deselection = \
#           !is_histogram_controlling_region_selection(@props.histo_key) || ( \
#           region_selected && 
#            (!@local.touched || inRange(@local.mouse_opinion_value, min, max)))

#         if is_deselection
#           clear_histogram_managed_opinion_views opinion_views
#           if ev.type == 'touchstart'
#             @local.mouse_opinion_value = null
#         else if @enable_range_selection
#           clear_histogram_managed_opinion_views opinion_views, 'single_opinion_selected'

#           @users_in_region = @getUsersInRegion()
#           opinion_views.active_views.region_selected =
#             created_by: @props.histo_key 
#             opinion_value: @local.mouse_opinion_value
#             get_salience: (u, opinion, proposal) => 
#               if @users_in_region[u.key || u] 
#                 1
#               else
#                 .1

#       save opinion_views
#       save @local

#   getUsersInRegion: ->
#     min = @local.mouse_opinion_value - REGION_SELECTION_WIDTH
#     max = @local.mouse_opinion_value + REGION_SELECTION_WIDTH

#     users_in_region = {}
#     for o in @opinions
#       salient = inRange o.stance, min, max
#       if salient
#         users_in_region[o.user] = true
#     users_in_region

#   getOpinionValueAtFocus: (ev) -> 
#     # Calculate the mouse_opinion_value (the slider value about which we determine
#     # the selection region) based on the mouse offset within the histogram element.
#     h_x = ReactDOM.findDOMNode(@).getBoundingClientRect().left + window.pageXOffset
#     h_w = ReactDOM.findDOMNode(@).offsetWidth
#     m_x = ev.pageX or ev.touches[0].pageX

#     translatePixelXToStance m_x - h_x, h_w

#   onMouseMove: (ev) ->     

#     return if bus_fetch(namespaced_key('slider', @props.proposal)).is_moving  || \
#               @props.backgrounded || !@enable_range_selection || \
#               !is_histogram_controlling_region_selection(@props.histo_key)

#     ev.stopPropagation()

#     @local.hovering_over_avatar = ev.target.className.indexOf('avatar') != -1
#     @local.mouse_opinion_value = @getOpinionValueAtFocus(ev)

#     at_pole = false
#     if @local.mouse_opinion_value + REGION_SELECTION_WIDTH >= 1
#       @local.mouse_opinion_value = 1 - REGION_SELECTION_WIDTH
#       at_pole = true 
#     else if @local.mouse_opinion_value - REGION_SELECTION_WIDTH <= -1
#       @local.mouse_opinion_value = -1 + REGION_SELECTION_WIDTH
#       at_pole = true
    
#     # dynamic selection on drag
#     opinion_views = bus_fetch 'opinion_views'
#     region_selected = opinion_views.active_views.region_selected    
#     if region_selected && @local.mouse_opinion_value
#                          # this last conditional is only for touch
#                          # interactions where there is no mechanism 
#                          # for "leaving" the histogram
#       mouse_sensitivity = 25
#       if at_pole || Math.round(@local.mouse_opinion_value * mouse_sensitivity) != Math.round(region_selected.opinion_value * mouse_sensitivity)
#         region_selected.opinion_value = @local.mouse_opinion_value 

#         @users_in_region = @getUsersInRegion()        
#         save opinion_views

#     save @local

#   onMouseDown: (ev) -> 
#     return if bus_fetch(namespaced_key('slider', @props.proposal)).is_moving
#     ev.stopPropagation()
#     return false 
#       # The return false prevents text selections
#       # of other parts of the page when dragging
#       # the selection region around.


#   onMouseLeave: (ev) ->     
#     return if bus_fetch(namespaced_key('slider', @props.proposal)).is_moving

#     opinion_views = bus_fetch 'opinion_views'
#     active = opinion_views.active_views
#     originating_histogram = (active.single_opinion_selected or active.region_selected)?.created_by == @props.histo_key

#     return if originating_histogram

#     @local.mouse_opinion_value = null
#     save @local









# window.styles += """
#   .histo_avatar.avatar {
#     cursor: pointer;
#     position: absolute;
#     /* top: 0;
#     left: 0; */
#     transform-origin: 0 0;
#   }
#   img.histo_avatar.avatar {
#     z-index: 1;
#   }
# """



# $$.add_delegated_listener document.body, 'keydown', '.avatar[data-opinion]', (e) ->
#   if e.which == 13 || e.which == 32 # ENTER or SPACE 
#     user_opinion = bus_fetch e.target.getAttribute 'data-opinion'
#     select_single_opinion user_opinion, 'keydown'


# # Draw the avatars in the histogram. Placement is determined by the physics sim
# HistoAvatars = ReactiveComponent 
#   displayName: 'HistoAvatars'

#   histocache_key: -> # based on variables that could alter the layout
#     key = """#{JSON.stringify( (Math.round(bus_fetch(o.key).stance * 100) for o in @props.opinions) )} #{JSON.stringify(@props.weights)} #{JSON.stringify(@props.groups)} (#{@props.width}, #{@props.height})"""
#     md5 key

#   getFillRatio: -> 
#     if @props.layout_params?.fill_ratio
#       @props.layout_params.fill_ratio
#     else if @isMultiWeighedHistogram()
#       .75
#     else 
#       1

#   isMultiWeighedHistogram: -> 
#     multi_weighed = false
#     previous = null  

#     for k,v of @props.weights 
#       if previous != null && v != previous 
#         multi_weighed = true 
#         break 
#       previous = v

#     multi_weighed

#   render: ->
#     users = bus_fetch '/users'

#     histocache_key = @histocache_key()
#     if !@local.avatar_sizes?[histocache_key]
#       @local.avatar_sizes ?= {}
#       radius = calculateAvatarRadius @props.width, @props.height, @props.opinions, @props.weights, 
#                         fill_ratio: @getFillRatio()
#       @local.avatar_sizes[histocache_key] = 2 * radius

#     @avatar_size = @local.avatar_sizes[histocache_key]
    

#     histocache = @local.histocache?[histocache_key]
    
#     if !histocache
#       histocache = @local.histocache?[@last_key] # try old one if current one temporarily doesn't exist yet


#     @last_key = histocache_key


#     DIV 
#       id: @props.histocache_key
#       key: @props.histo_key or @local.key
#       ref: 'histo'
#       'data-receive-viewport-visibility-updates': 2
#       'data-component': @local.key      
#       style: 
#         height: @props.height
#         position: 'relative'
#         # top: -1
#         cursor: if !@props.backgrounded && 
#                     @enable_range_selection then 'pointer'

#       DIV null,
#         if @local.in_viewport && users.users && histocache

#           base_avatar_diameter = 70 # @avatar_size 

#           # There are a few avatar styles that might be applied depending on state:
#           # Regular, for when no user is selected
#           regular_avatar_style =
#             width: base_avatar_diameter
#             height: base_avatar_diameter

#           if !@props.enable_individual_selection
#             regular_avatar_style.cursor = 'auto'

#           opinion_views = bus_fetch 'opinion_views'  

#           groups = get_user_groups_from_views @props.groups 
#           has_groups = !!groups
#           if has_groups
#             colors = get_color_for_groups groups 


#           if @props.flip
#             shouldFlip = => @props.flip_state_changed

#           for opinion, idx in @props.opinions
          

#             user = bus_fetch opinion.user
#             o = bus_fetch(opinion) # subscribe to changes so physics sim will get rerun...

#             # sub_creation = new Date(bus_fetch('/subdomain').created_at).getTime()
#             # creation = new Date(o.created_at).getTime()
#             # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

#             className = 'histo_avatar'
            
#             salience = if @props.backgrounded then 0.1 else @props.salience[user.key]

#             if salience < 1
#               avatar_style = _.extend({}, regular_avatar_style, {opacity: salience, cursor: 'default'})  

#             else
#               avatar_style = _.extend {}, regular_avatar_style

#             if has_groups && @props.groups[user.key]?
#               if @props.groups[user.key].length == 1
#                 group = @props.groups[user.key][0]
#                 avatar_style.backgroundColor = colors[group]
#               else 
#                 gcolors = []
#                 for group in @props.groups[user.key]
#                   gcolors.push colors[group]
#                 gradient = ""
#                 size = 1 / gcolors.length / 8
#                 for gcolor,idx in gcolors
#                   gradient += ", #{gcolor} #{100 * idx * size}%, #{gcolor} #{100 * (idx + 1) * size}%"

#                 avatar_style.background = "repeating-linear-gradient(45deg #{gradient})"


#             pos = histocache?.positions?[user.key]
#             if pos 
#               custom_size = 2 * pos[2] != base_avatar_diameter

#               avatar_style = _.extend {}, avatar_style

#               if pos 
#                 avatar_style.transform = "translate(#{pos[0]}px, #{pos[1]}px)"

#                 if pos[2] && custom_size
#                   avatar_style.transform = "#{avatar_style.transform} scale(#{2 * pos[2] / base_avatar_diameter})"

#                   # avatar_style.width = avatar_style.height = 2 * pos[2]

#             else 
#               continue

#             avatar user,
#               key: idx
#               'data-opinion': opinion.key or opinion
#               focusable: @props.navigating_inside && salience == 1
#               hide_popover: @props.backgrounded || salience < 1
#               className: className
#               # alt: "<user>: #{alt}"
#               anonymous: customization('anonymize_everything')
#               style: avatar_style
#               set_bg_color: true
#               custom_bg_color: avatar_style.background || avatar_style.backgroundColor

#   PhysicsSimulation: ->
#     proposal = bus_fetch @props.proposal

#     # We only need to rerun the sim if the distribution of stances has changed, 
#     # or the width/height of the histogram has changed. We round the stance to two 
#     # decimals to avoid more frequent recalculations than necessary (one way 
#     # this happens is with the server rounding opinion data differently than 
#     # the javascript does when moving one's slider)
#     histocache_key = @last_key
    
#     if histocache_key not of (@local.histocache or {}) && @current_request != histocache_key

#       @current_request = histocache_key

#       opinions = ({stance: o.stance, user: o.user} for o in @props.opinions)
      

#       if @isMultiWeighedHistogram()
#         layout_params = _.defaults {}, (@props.layout_params or {}), 
#           fill_ratio: @getFillRatio()
#           show_histogram_layout: show_histogram_layout
#           cleanup_overlap: 2
#           jostle: 0
#           rando_order: 0
#           topple_towers: .05
#           density_modified_jostle: 0

#       else 
#         layout_params = _.defaults {}, (@props.layout_params or {}), 
#           fill_ratio: 1
#           show_histogram_layout: show_histogram_layout
#           cleanup_overlap: 1.95
#           jostle: .4
#           rando_order: .1
#           topple_towers: .05
#           density_modified_jostle: 1

#       has_groups = Object.keys(@props.groups).length > 0
#       delegate_layout_task
#         task: 'layoutAvatars'
#         histo: @local.key
#         k: histocache_key
#         r: @avatar_size / 2
#         w: @props.width or 400
#         h: @props.height or 70
#         o: opinions
#         weights: @props.weights
#         groups: if has_groups then @props.groups
#         all_groups: if has_groups then get_user_groups_from_views(@props.groups)
#         layout_params: layout_params



  
#   componentDidMount: ->   
#     @PhysicsSimulation()
#     schedule_viewport_position_check()

#   componentDidUpdate: -> 
#     @PhysicsSimulation()




# num_layout_workers = 4
# num_layout_tasks_delegated = 0
# window.delegate_layout_task = (opts) -> 
#   after_loaded = ->
#     histo_layout_worker = histo_layout_workers[num_layout_tasks_delegated % num_layout_workers]  
#     histo_layout_worker.postMessage opts
#     num_layout_tasks_delegated += 1

#   if window.histo_layout_workers
#     after_loaded()
#   else 
#     intv = setInterval ->
#       if window.histo_layout_workers
#         after_loaded()
#         clearInterval intv
#       configure_histo_layout_web_worker()
#     , 20


# configure_histo_layout_web_worker = ->

#   if !window.histo_layout_workers && arest.cache['/application']?.web_worker
#     window.histo_layout_workers = (new Worker(arest.cache['/application'].web_worker) for i in [0..num_layout_workers - 1])

#     onmessage = (e) ->
#       {opts, positions} = e.data 

#       local = bus_fetch opts.histo
#       histocache_key = opts.k 
      
#       local.histocache ?= {} 
#       local.histocache[histocache_key] = 
#         hash: histocache_key
#         positions: positions

#       save local

#     for worker in histo_layout_workers
#       worker.onmessage = onmessage



