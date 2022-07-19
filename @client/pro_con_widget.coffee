

window.ProConWidget = ReactiveComponent
  displayName: 'ProConWidget'

  render: -> 
    proposal = fetch @props.proposal
    return DIV null if !customization('discussion_enabled', proposal)

    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')
    
    your_opinion = proposal.your_opinion
    if your_opinion.key
      fetch your_opinion

    if your_opinion.published
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    opinion_views = fetch 'opinion_views'
    has_selection = opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected

    enable_opining = can_opine != Permission.INSUFFICIENT_PRIVILEGES && 
                      (can_opine != Permission.DISABLED || your_opinion.published ) && 
                      # !has_selection &&
                      !(!current_user.logged_in && '*' not in proposal.roles.participant)


    register_dependency = fetch(namespaced_key('slider', proposal)).value 
                             # to keep bubble mouth in sync with slider

    mode = get_proposal_mode()

    points = get_points(proposal)

    if get_selected_point() && !@local.show_all_points
      @local.show_all_points = true 
      save @local
    
    show_all_points = @local.show_all_points || points.length < 5 || has_selection

    # A number of elements controlled by other components are absolutely 
    # positioned within the reasons region (e.g. discussions, decision
    # board, new point). We need to set a minheight that is large enough to 
    # encompass these elements. 
    adjustments = fetch('reasons_height_adjustment')
    minheight = 100 + (adjustments.opinion_region_height || 0)
    if get_selected_point()
      minheight += adjustments.open_point_height
    if adjustments.edit_point_height
      minheight += adjustments.edit_point_height


    draw_handle = @props.draw_handle

    decision_board_style = 
      padding: '0 125px'
    # decision_board_style =
    #   borderRadius: 16
    #   borderStyle: 'dashed'
    #   borderWidth: 3
    #   borderColor: focus_color()
    #   transition: if @last_proposal_mode != get_proposal_mode() || @transitioning  
    #                 "transform #{TRANSITION_SPEED}ms, " + \
    #                 "width #{TRANSITION_SPEED}ms, " + \
    #                 "min-height #{TRANSITION_SPEED}ms"
    #               else
    #                 'none'

    # if mode == 'results'
    #   _.extend decision_board_style,
    #     borderColor: 'transparent'

    wrapper_width = POINT_WIDTH() + 125 * 2
    slider = fetch(namespaced_key('slider', proposal))

    if get_proposal_mode() == 'results' && !has_selection
      give_opinion_button_width = 232
      give_opinion_style = 
        backgroundColor: focus_color()
        display: 'block'
        color: 'white'
        padding: '.25em 18px'
        margin: 0
        fontSize: 16
        width: give_opinion_button_width
        borderRadius: 16
        boxShadow: 'none'
        position: 'absolute'
        left: give_opinion_button_width / -2 + (wrapper_width - PROPOSAL_HISTO_WIDTH()) / 2 + translateStanceToPixelX(slider.value, PROPOSAL_HISTO_WIDTH())
        top: -16
        zIndex: 1
    else 
      give_opinion_style =
        visibility: 'hidden'
        display: 'none'

    if !show_all_points
      _.extend decision_board_style, 
        overflowY: 'hidden'  
        overflowX: 'auto' 
        height: 500

    DIV 
      style: 
        position: 'relative'
        top: -8

      #reasons
      SECTION 
        className:'reasons_region'
        style : 
          width: wrapper_width
          minHeight: if show_all_points then minheight     
          position: 'relative'
          paddingBottom: '4em' #padding instead of margin for docking
          margin: "#{if draw_handle then '24px' else '0'} auto 0 auto"

        H2
          className: 'hidden'

          translator
            id: "engage.reasons_section_explanation"
            'Why people think what they do about the proposal'


        # SliderBubblemouth()

        # Border + bubblemouth that is shown when there is a histogram selection
        GroupSelectionRegion proposal: proposal

        # only shown during results, but needs to be present always for animation
        BUTTON
          className: 'give_opinion_button btn'
          style: give_opinion_style
          onClick: => 
            if get_proposal_mode() == 'results' 

              if your_opinion.published
                can_opine = permit 'update opinion', proposal, your_opinion
              else
                can_opine = permit 'publish opinion', proposal

              if can_opine > 0
                updateProposalMode('crafting', 'give_opinion_button')
                $('.the_handle')[0].focus()
              else
                # trigger authentication
                reset_key 'auth',
                  form: 'create account'
                  goal: 'To participate, please introduce yourself.'
                  after: =>
                    updateProposalMode('crafting', 'give_opinion_button')
                    $('.the_handle')[0].focus()

          # if !current_user.logged_in
          #   translator 
          #     id: "engage.log_in_to_give_your_opinion_button"
          #     'Log in to Give your Opinion'

          if proposal.your_opinion
            translator 
              id: "engage.update_your_opinion_button"
              'Update your Opinion'
          else 
            translator 
              id: "engage.give_your_opinion_button"
              'Give your Opinion'

        DIV
          'aria-live': 'polite'
          key: 'body' 
          className:'decision_board_body'
          style: css.crossbrowserify decision_board_style

          Points
            proposal: @props.proposal
            points: points

      if !show_all_points
        BUTTON 
          style: 
            backgroundColor: "#eee"
            padding: '12px 0'
            fontSize: 24
            textAlign: 'center'
            textDecoration: 'underline'
            border: 'none'
            #border: '1px solid rgba(0,0,0,.5)'                
            cursor: 'pointer'
            display: 'block'
            width: POINT_WIDTH() + 18 * 2 + 100 * 2
            margin: 'auto'
            position: 'relative'
            zIndex: 1

          onClick: => 
            @local.show_all_points = true 
            save @local
          onKeyPress: (e) => 
            if e.which in [13,32]
              @local.show_all_points = true 
              save @local

          TRANSLATE
            id: "engage.show_all_thoughts"
            "Show All Reasons"


Points = ReactiveComponent
  displayName: 'Points'

  render: -> 
    points = (fetch(pnt) for pnt in @props.points)

    mode = get_proposal_mode()

    your_points = @data()
    proposal = fetch @props.proposal


    if @props.points_editable && !@local.editing_points?
      _.extend @local,
        editing_points : []
        adding_new_point : false
      save @local


    get_heading = => 
      point_labels = customization("point_labels", proposal)

      heading = point_labels["#{mode}_header"]
      heading_t = translator
                    id: "point_labels.header_#{mode}.#{heading}"
                    key: if point_labels.translate then "/translations" else "/translations/#{fetch('/subdomain').name}"
                    heading

      heading_t

    heading = get_heading()



    SECTION 
      style: _.defaults (@props.style or {}),
        width: POINT_WIDTH()
        paddingTop: 28
        position: 'relative'

      H3 
        ref: 'point_list_heading'
        id: @local.key.replace('/','-')
        className: 'points_heading_label'
        style: 
          width: POINT_WIDTH()
          fontWeight: 700
          color: if mode == 'crafting' then focus_color()
          fontSize: 36          
          textAlign: 'center'
          marginTop: 7
        heading

      if mode == 'crafting'

        DIV 
          style: 
            display: 'none'
            fontSize: 12
            
            color: '#013470'
            padding: "0px 8px 0px 12px"

          """What factors underly your opinion? Each factor below has a slider. 
             Drag a slider to the right to consider it a pro, and to the left as a con. 
             The further you slide a factor, the more importance you give it in moving 
             your overall opinion in that direction. Keeping it in the middle means 
             it didn’t move you one way or the other. Add new factors as needed to 
             substantiate your opinion."""


      MagicList
        key: 'points_list'
        items: points
        duration: 500
        list_props:  
          style: 
            marginTop: 36
          'aria-labelledby': @local.key.replace('/','-')
        dummy: @props.points_editable
        dummy2: @local.editing_points

        for point in points
          if @props.points_editable && \
             point.key in @local.editing_points && \
             !browser.is_mobile
            EditPoint 
              point: point.key
              fresh: false
              valence: @props.valence
              your_points_key: @props.reasons_key
          else
            Point
              key: point.key
              point: point.key
              your_points_key: @props.reasons_key


      if @props.points_editable && permit('create point', proposal) > 0 
        @drawAddNewPoint()


stored_points_order = {}
get_points = (proposal, sort_field) ->
  points = fetch("/page/#{proposal.slug}").points or []
  sort_key = "sorted-points-#{proposal.key}"
  
  sort = fetch 'sort_points'
  if !sort.name
    set_sort(sort.key)  
    _.extend sort, sort_options[0]

  return sorted_proposals(points, sort_key, false, sort.key) or []


  opinions = get_opinions_for_proposal null, proposal

  # Filter down to the points included in the selected opinions, if set. 
  opinion_views = fetch('opinion_views')
  if opinion_views.active_views.single_opinion_selected
    opinions = [opinion_views.active_views.single_opinion_selected.opinion] 
    filtered = true
  else if opinion_views.active_views.region_selected || (key for key,view of opinion_views.active_views when view.view_type == 'filter' && key != 'just_you').length > 0
    {weights, salience, groups} = compose_opinion_views opinions, proposal
    opinions = (o for o in opinions when salience[o.user.key or o.user] == 1)
    filtered = true



  # order points by resonance to users in view.    
  point_inclusions_per_point = {} # map of points to including users
  _.each opinions, (opinion_key) =>
    opinion = fetch(opinion_key)
    if opinion.point_inclusions
      for point in opinion.point_inclusions
        point_inclusions_per_point[point] ||= 0
        point_inclusions_per_point[point] += 1

  # try enforce k=2-anonymity for hidden points
  # if opinions.length < 2
  #   for point,inclusions of point_inclusions_per_point
  #     if fetch(point).hide_name
  #       delete point_inclusions_per_point[point]

  # # really ugly, but if we're hovering over point includers, turning on the point includer filter, 
  # # the points will automatically re-sort, causing flickering, unless we some how undo the auto 
  # # sorting caused by the point includer filter
  # active_views = _.without Object.keys(opinion_views.active_views), 'point_includers'
  # sort_key = JSON.stringify {proposal:proposal.key, valence, sort_field, views: active_views, pnts: (pnt.key for pnt in points)}
  # if sort_key of stored_points_order && opinion_views.active_views.point_includers
  #   points = stored_points_order[sort_key]
  # else 

  points = (pnt for pnt in points when (pnt.key of point_inclusions_per_point) || (TWO_COL() && pnt.key in included_points))

  # Sort points based on resonance with selected users, or custom sort_field
  sort = (pnt) ->
    if filtered
      -point_inclusions_per_point[pnt.key] 
    else
      -pnt[sort_field]

  points = _.sortBy points, sort
  stored_points_order[sort_key] = points

  points





SliderBubblemouth = ReactiveComponent
  displayName: 'SliderBubblemouth'

  render : -> 

    slider = fetch(@props.slider_key)
    db = fetch('decision_board')

    w = 34
    h = 24
    stroke_width = 11

    if @props.render_large 
      transform = "translate(0, -4px) scale(1,.7)"
      fill = 'white'
    else 
      transform = "translate(0, -25px) scale(.5,.5) "
      fill = focus_color()

    if @props.dashed
      dash = "25, 10"
    else
      dash = "none"

    DIV 
      key: 'slider_bubblemouth'
      style: css.crossbrowserify
        left: @props.left or 10 + translateStanceToPixelX slider.value, DECISION_BOARD_WIDTH() - w - 20
        top: -h + 8 # +10 is because of the decision board translating down 18, 3 is for its border
        position: 'absolute'
        width: w
        height: h 
        zIndex: 10
        transition: "transform #{TRANSITION_SPEED}ms"
        transform: transform

      Bubblemouth 
        apex_xfrac: (slider.value + 1) / 2
        width: w
        height: h
        fill: fill
        stroke: focus_color()
        stroke_width: if @props.render_large then stroke_width else 0
        dash_array: dash


####
# GroupSelectionRegion
#
# Draws a border around the selected opinion(s)
# Shows a bubble mouth for selected opinions or 
# a user name + avatar display if we've selected
# an individual opinion.
GroupSelectionRegion = ReactiveComponent
  displayName: 'GroupSelectionRegion'

  render : -> 

    proposal = fetch @props.proposal
    opinion_views = fetch 'opinion_views'
    single_opinion_selected = opinion_views.active_views.single_opinion_selected
    region_selected = opinion_views.active_views.region_selected
    has_histogram_focus = single_opinion_selected || region_selected
    
    mode = get_proposal_mode()

    wrapper_width = POINT_WIDTH() + 125 * 2

    # draw a bubble mouth
    w = 36; h = 24

    margin = wrapper_width - PROPOSAL_HISTO_WIDTH()

    if region_selected
      stance = region_selected.opinion_value
      left = translateStanceToPixelX(1 / 0.75 * stance, PROPOSAL_HISTO_WIDTH()) + margin / 2 - w / 2
    else if single_opinion_selected
      avatar_in_histo = document.querySelector("[data-opinion='#{single_opinion_selected.opinion}'")
      left = margin / 2 + avatar_in_histo.getBoundingClientRect().left - avatar_in_histo.parentElement.getBoundingClientRect().left
    else
      slider = fetch(namespaced_key('slider', proposal))
      left = (wrapper_width - PROPOSAL_HISTO_WIDTH()) / 2 + translateStanceToPixelX slider.value, PROPOSAL_HISTO_WIDTH() - w

    color = if !has_histogram_focus && mode != 'crafting' then 'transparent' else if get_selected_point() then '#eee' else focus_color()
    DIV 
      style: 
        width: wrapper_width
        border: "3px #{if mode == 'crafting' then 'dashed' else 'solid'} #{ color }"
        height: '100%'
        position: 'absolute'
        borderRadius: 16
        marginLeft: -wrapper_width / 2
        left: '50%'
        top: 4 #18


      SliderBubblemouth
        slider_key: namespaced_key('slider', proposal)
        left: left 
        dashed: mode == 'crafting'
        render_large: mode == 'crafting' || has_histogram_focus
      # DIV 
      #   style: cssTriangle 'top', \
      #                      (if get_selected_point() then '#eee' else focus_color()), \
      #                      w, h,               
      #                         position: 'relative'
      #                         top: -26
      #                         left: left

      #   DIV
      #     style: cssTriangle 'top', 'white', w - 1, h - 1,
      #       position: 'relative'
      #       left: -(w - 2)/2
      #       top: 6


      if single_opinion_selected
        # display a name for the selected opinion

        avatar_height = avatar_in_histo.offsetHeight

        name_style = 
          fontSize: 30
          fontWeight: 600

        user = fetch(fetch(single_opinion_selected.opinion).user)
        name = user.name or anonymous_label()
        title = "#{name}'#{if name[name.length - 1] != 's' then 's' else ''} Opinion"
        name_width = widthWhenRendered(title, name_style)
        DIV
          style: _.extend name_style,
            position: 'absolute'
            top: -(avatar_height + 172)
            color: focus_color()
            left: Math.min(wrapper_width - name_width - 10, Math.max(0, left - name_width / 2))
          title 




# adapted from https://medium.com/developers-writing/animating-the-unanimatable-1346a5aab3cd
window.MagicList = ReactiveComponent 
  displayName: 'MagicList'
  render: ->
    UL (@props.list_props or {}), 
      for chld in @props.children
        chld.ref = chld.key
        # console.log chld, chld.key, chld.ref
        chld

  componentWillReceiveProps: ->
    @local.positions ?= {}
    for child in @props.children when child.key

      node = @getDOMNode().querySelector("[data-key=\"#{child.key}\"]")
      box = node.getBoundingClientRect()
      @local.positions[child.key] = box

      node.style.transition = ''

  componentDidUpdate: (previousProps) ->
    console.log 'did update', @local.positions
    for child in previousProps.children
      # TODO: deal with added and removed items
      continue if child.entering || child.leaving || !child.key || child.key not of @local.positions

      do (child) =>

        node = @getDOMNode().querySelector("[data-key=\"#{child.key}\"]")
        if node 
          new_box = node.getBoundingClientRect()
          old_box = @local.positions[child.key]

          
          deltaX = old_box.left - new_box.left 
          deltaY = old_box.top  - new_box.top

          if deltaX != 0 || deltaY != 0
            console.log "transitioning", deltaX, deltaY
            # node.animate([
            #   { transform: "translate(#{deltaX}px, #{deltaY}px)"},
            #   { transform: "translate(0,0)"}
            # ], {
            #   duration: @props.duration
            # })

            # Before the DOM paints, Invert it to its old position
            node.style.transform = "translate(#{deltaX}px, #{deltaY}px)"
            # Ensure it inverts it immediately
            node.style.transition = 'transform 0s' 

            requestAnimationFrame =>
              # # Before the DOM paints, Invert it to its old position
              # node.style.transform = "translate(#{deltaX}px, #{deltaY}px)"
              # # Ensure it inverts it immediately
              # node.style.transition = 'transform 0s' 

              requestAnimationFrame =>
                # In order to get the animation to play, we'll need to wait for
                # the 'invert' animation frame to finish, so that its inverted
                # position has propagated to the DOM.
                # Then, we just remove the transform, reverting it to its natural
                # state, and apply a transition so it does so smoothly.
                node.style.transform  = ''
                node.style.transition = "transform #{@props.duration or 500}ms ease-in-out 300ms"

