
##
# Slider
# Manages the slider and the UI elements attached to it. Specifically: 
#   - a slider base
#   - labels for the poles of the slider
#   - a draggable slider handle
#   - feedback description about the current opinion
#
window.Slider = ReactiveComponent
  displayName: 'Slider'

  render : ->

    slider = fetch(@props.key)
    hist = fetch('histogram')

    # initialize
    if !slider.initialized
      _.defaults slider,
        initialized: true
        has_moved : false
        is_moving : false
        stance : null      
      save slider

    # Update the slider position when the server gets back to us
    your_opinion = fetch(@proposal.your_opinion)
    if slider.stance != your_opinion.stance and !slider.is_moving
      slider.stance = your_opinion.stance
      slider.clientX = @props.width * (slider.stance / 2 + .5)
      if your_opinion.stance
        slider.has_moved = true
      save(slider)

    ####
    # Define slider layout
    slider_style = 
      position: 'relative'
      left: - (@props.width - BODY_WIDTH) / 2
      width: @props.width
      height: SLIDER_HANDLE_SIZE

    if @props.backgrounded
      css.grayscale slider_style

    ####
    # Define slider base
    slider_base_style = 
      width: @props.width
      height: 6
      backgroundColor: '#BBBFC7'
      position: 'absolute'


    ####
    # Define slider handle

    # Check whether the user has permission to opine, which affects whether a 
    # slider handle is shown. 
    if your_opinion.published
      can_opine = permit 'update opinion', @proposal, your_opinion
    else
      can_opine = permit 'publish opinion', @proposal

    enable_opining = !(hist.selected_opinions || hist.selected_opinion) &&
                      (can_opine not in [Permission.DISABLED, \
                                         Permission.INSUFFICIENT_PRIVILEGES] || 
                      your_opinion.published )

    draw_handle = enable_opining
    if draw_handle

      handle_style =
        boxShadow: "0px 1px 0px black, " + \
                   "inset 0 1px 2px rgba(255,255,255, .4), " + \
                   "0px 0px 0px 1px #{focus_blue}"            
        backgroundColor: focus_blue      
        left: slider.clientX
        zIndex: 10
        borderRadius: '50%'
        width: SLIDER_HANDLE_SIZE
        height: SLIDER_HANDLE_SIZE
        marginLeft: -SLIDER_HANDLE_SIZE / 2
        top: -9
        position: 'relative'
        visibility: if @props.backgrounded then 'hidden'

        transition: "transform #{TRANSITION_SPEED}ms"
        transform: "scale(#{if !@props.focused || slider.docked then 1 else 2.5})"


      face_style = 
        position: 'absolute'
        pointerEvents: 'none'
        borderRadius: '50%'

      eye_size = .8 + .2 * Math.abs(slider.stance)
      eye_style = _.extend {}, face_style,
        backgroundColor: 'white'
        top: 6
        width: 3
        height: 3
        transform: "scale(#{eye_size}, #{eye_size})"

      mouth_scale_y = .4 * slider.stance
      mouth_y = if Math.abs(mouth_scale_y) < .08 
                  (if mouth_scale_y >= 0 then 1 else -1) * .08 
                else 
                  mouth_scale_y
      mouth_style = _.extend {}, face_style,
        bottom: -1
        width: SLIDER_HANDLE_SIZE - 4
        left: 2
        height: SLIDER_HANDLE_SIZE - 4
        boxShadow: '3px 3px 0 0 white'
        transform: 
          "scale(#{.4 + .3 * Math.abs(slider.stance)}, #{mouth_y}) " + \
          "translate(0, #{-2 - 5 * Math.abs(slider.stance)}px) " + \
          "rotate(45deg)"


    ####
    # Define slider feedback
    draw_feedback = @props.focused && draw_handle
    
    if draw_feedback
      slider_feedback = 
        if !slider.has_moved 
          'Slide Your Overall Opinion' 
        else if isNeutralOpinion(slider.stance)
          "You are Undecided"
        else 
          degree = Math.abs(slider.stance)
          strength_of_opinion = if degree > .999
                                  "Fully "
                                else if degree > .5
                                  "Firmly "
                                else
                                  "Slightly " 

          valence = customization "slider_pole_labels.individual." + \
                                  if slider.stance > 0 then 'support' else 'oppose'

          "You #{strength_of_opinion} #{valence}"

      feedback_style = 
        pointerEvents: 'none' 
        fontSize: 30
        fontWeight: 700
        color: focus_blue
        visibility: if @props.backgrounded then 'hidden'

      # Keep feedback centered over handle, but keep within the bounds of 
      # the slider region when the slider is in an extreme position. 
      feedback_left = @props.width * (slider.stance/2 + .5)
      feedback_width = widthWhenRendered(slider_feedback, feedback_style) + 10

      if slider.docked 
        if slider.stance > 0
          feedback_left = Math.min(@props.width - feedback_width/2, feedback_left)
        else
          feedback_left = Math.max(feedback_width/2, feedback_left)

      _.extend feedback_style, 
        position: 'absolute'      
        top: if slider.docked then -57 else -80      
        left: feedback_left
        marginLeft: -feedback_width / 2
        width: feedback_width


    DIV 
      className: 'slider'
      style : slider_style

      # Draw the pole labels of the slider      
      if !slider.docked
        for pole_label, idx in @props.pole_labels
          w = widthWhenRendered pole_label, {fontSize: 30}
          DIV 
            key: pole_label
            style: 
              position: 'absolute'
              fontSize: 30
              top: -20
              pointerEvents: 'none'
              left: if idx == 0 then -(w + 55)
              right: if idx == 1 then -(w + 55)

            pole_label
      else
        for pole_label, idx in @props.pole_labels
          DIV 
            key: "small-#{pole_label}"
            style: 
              position: 'absolute'
              fontSize: 20
              top: -12
              pointerEvents: 'none'
              left: if idx == 0 then -15
              right: if idx == 1 then -20

            if idx == 0 then '–' else '+'

      # Draw the base of the slider
      DIV 
        style : slider_base_style

        if !slider.docked

          for support in [true, false]
            DIV 
              key: "slider-base-#{support}"
              style: 
                position: 'absolute'
                left: if support then -5
                right: if !support then -5
                width: 5
                height: slider_base_style.height
                backgroundColor: slider_base_style.backgroundColor

              DIV
                style: cssTriangle \
                         (if support then 'left' else 'right'), \
                         slider_base_style.backgroundColor, 12, 6,               
                            position: 'absolute'
                            left: if support then -12
                            right: if !support then -12

      if draw_feedback
        DIV 
          style: feedback_style
          slider_feedback

      if draw_handle
        DIV 
          className: 'the_handle' 
          onMouseUp: @handleMouseUp
          onTouchEnd: @handleMouseUp
          onTouchCancel: @handleMouseUp

          onMouseDown: @handleMouseDown
          onTouchStart: @handleMouseDown

          onTouchMove: @handleMouseMove
          style: css.crossbrowserify handle_style

          if @props.focused
           [DIV 
              style: css.crossbrowserify(mouth_style)
            DIV 
              style: css.crossbrowserify(_.defaults({left: 6}, eye_style))
            DIV 
              style: css.crossbrowserify(_.defaults({right: 6}, eye_style ))
           ]

          if @props.focused && !slider.has_moved
            for support in [true, false]
              DIV 
                style: 
                  right: if support then -15
                  left: if !support then -15
                  position: 'absolute'
                  top: 3
                  color: focus_blue
                  fontSize: 12              
                if support then '>' else '<'



  # Kick off sliding 
  handleMouseDown: (e) -> 
    el = @getDOMNode()
    # Dragging has to start by dragging the slider handle
    return if !$(e.target).is('.the_handle')

    e.preventDefault()

    # Initiate dragging
    slider = fetch(@props.key)
    slider.is_moving = true
    slider.offsetX = e.clientX or e.touches[0].clientX

    slider.startX = parseInt($(e.target)[0].style.left, 10) || 0
    save slider

    $(window).on "mousemove.slider", @handleMouseMove
    $(window).on "mouseup.slider", @handleMouseUp

  # Stop sliding
  handleMouseUp: (e) ->
    # Don't do anything if we're not actually dragging. We only hit this logic
    # if there is some delay in removing the event handlers.
    slider = fetch @props.key

    return if !slider.is_moving

    e.preventDefault()

    your_opinion = fetch(@proposal.your_opinion)
    
    # Clicking on the slider handle should transition us between 
    # crafting <=> results. We should also transition to crafting 
    # when we've been dragging on the results page. 
    if slider.stance == your_opinion.stance || !@props.focused
      new_page = if get_proposal_mode() == 'results' then 'crafting' else 'results'
      updateProposalMode new_page, 'click_slider'
      e.stopPropagation()

    # We save the slider's position to the server only on mouse-up.
    # This way you can drag it with good performance.
    if your_opinion.stance != slider.stance
      your_opinion.stance = slider.stance
      save your_opinion
      window.writeToLog 
        what: 'move slider'
        details: {stance: slider.stance}

    # Turn off dragging
    slider.is_moving = false
    save slider

    $(window).off ".slider" # Remove event handlers

  # While sliding
  handleMouseMove: (e) ->
    e.preventDefault() # prevents text selection of surrounding elements

    slider = fetch(@props.key)

    clientX = e.clientX or e.touches[0].clientX

    # Update position
    slider.clientX = slider.startX + clientX - slider.offsetX
    slider.clientX = 0 if slider.clientX < 0
    slider.clientX = @props.width if slider.clientX > @props.width
    slider.has_moved = true

    # convert position of handle to a slider value on [1, -1]
    slider.stance = translatePixelXToStance(slider.clientX, @props.width)

    save slider


styles += """
#{css.grab_cursor('.the_handle')}
"""