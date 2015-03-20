##
# Slider
#
# Manages the slider and the UI elements attached to it. Specifically: 
#   - a slider base
#   - labels for the poles of the slider
#   - a draggable slider handle
#   - feedback description about the current opinion
#
# TODO:
#   - better documentation

require './customizations'
require './shared'

window.Slider = ReactiveComponent
  displayName: 'Slider'

  render : ->

    slider = fetch @props.key
    your_opinion = fetch @props.your_opinion

    # initialize
    if !slider.initialized
      _.defaults slider,
        initialized: true
        has_moved : false
        is_moving : false
        stance : null      
      save slider

    # Update the slider position when the server gets back to us
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

    DIV 
      className: 'slider'
      style : slider_style

      # Draw the pole labels of the slider
      @drawPoleLabels()

      # Draw the base of the slider
      @drawSliderBase()

      if @props.focused && @props.enabled
        @drawFeedback()

      if @props.enabled
        @drawSliderHandle()

  drawPoleLabels: -> 
    slider = fetch @props.key

    if !slider.docked
      for pole_label, idx in @props.pole_labels
        [main_text, sub_text] = pole_label
        w = widthWhenRendered pole_label, {fontSize: 30}
        DIV 
          key: main_text
          style: 
            position: 'absolute'
            fontSize: 30
            top: -20
            pointerEvents: 'none'
            left: if idx == 0 then -(w + 55)
            right: if idx == 1 then -(w + 55)

          main_text

          DIV 
            key: "pole_#{sub_text}_sub"
            style: 
              fontSize: 14
              textAlign: 'center'

            sub_text

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

  drawSliderBase: -> 
    slider = fetch @props.key

    slider_base_style = 
      width: @props.width
      height: 6
      backgroundColor: '#BBBFC7'
      position: 'absolute'

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

  drawFeedback: -> 
    slider = fetch @props.key

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
      style: feedback_style
      slider_feedback

  drawSliderHandle: -> 
    slider = fetch @props.key
    DIV 
      className: 'the_handle' 
      onMouseUp: @handleMouseUp
      onTouchEnd: @handleMouseUp
      onTouchCancel: @handleMouseUp

      onMouseDown: @handleMouseDown
      onTouchStart: @handleMouseDown

      onTouchMove: @handleMouseMove
      style: css.crossbrowserify
        width: SLIDER_HANDLE_SIZE
        height: SLIDER_HANDLE_SIZE
        transition: "transform #{TRANSITION_SPEED}ms"
        transform: "scale(#{if !@props.focused || slider.docked then 1 else 2.5})"
        visibility: if @props.backgrounded then 'hidden'
        top: -9
        position: 'relative'
        marginLeft: -SLIDER_HANDLE_SIZE / 2
        zIndex: 10
        left: slider.clientX


      customization('slider_handle')
        value: (slider.stance + 1) / 2
        detail: @props.focused

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

    your_opinion = fetch @props.your_opinion
    
    # Clicking on the slider handle should transition us between 
    # crafting <=> results. We should also transition to crafting 
    # when we've been dragging on the results page. 
    if @props.additionalOnMouseUp
      @props.additionalOnMouseUp e

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

    clientX = if e.clientX?
                e.clientX
              else
                e.touches[0].clientX

    # Update position
    slider.clientX = slider.startX + clientX - slider.offsetX
    slider.clientX = 0 if slider.clientX < 0
    slider.clientX = @props.width if slider.clientX > @props.width
    slider.has_moved = true

    # convert position of handle to a slider value on [1, -1]
    slider.stance = translatePixelXToStance(slider.clientX, @props.width)

    save slider



####
# Slider handles
#
# All slider handles should respect the SLIDER_HANDLE_SIZE width/height.
# 
# Slider handles will be passed a props object with:
# 
# value: 
#    ranging from [0, 1] representing a position on the slider. This can 
#    be used to change the visualization if desired. But the slider handle
#    doesn't have to worry about positioning itself according to the value. 
#
# detail: 
#    Whether the handle should show the more intricate details. 
#

if !window.slider_handles
  window.slider_handles = {}

slider_handles.face = (props) -> 

  SVG
    height: SLIDER_HANDLE_SIZE
    width: SLIDER_HANDLE_SIZE
    viewBox: "-2 -1 104 104"
    style: 
      pointerEvents: 'none'

    DEFS null,
      svg.innerbevel
        id: 'handle-innerbevel'
        shadows: [{color: 'black', opacity: 1, dx: 0, dy: -3, stdDeviation: 3}, \
                  {color: 'white', opacity:  .25, dx:  0, dy: 3, stdDeviation: 3}]        

    CIRCLE
      fill: focus_blue
      stroke: focus_blue
      cx: 50
      cy: 50
      r: 50

    if props.detail
      G null,
        
        CIRCLE
          fill: focus_blue
          filter: "url(#handle-innerbevel)"

          cx: 50
          cy: 50
          r: 50

        # brows
        for is_left in [true, false]
          # support: closer to center line
          # oppose: larger eyes, closer to the edge

          direction = if is_left then -1 else 1
          bw = 15
          bh = 2
          x = 50 + direction * ( 28 + 4 * (1 - props.value)) - if is_left then 0 else bw
          y = 28 - 4 * (1 - props.value)
          RECT
            x: x
            y: y
            width: bw
            height: bh
            transform: "rotate(#{ direction * (5 + 30 * Math.abs(.5 - props.value))} #{x + (if is_left then bw else 0)} #{y + bh})"
            fill: 'white'

        # eyes
        for is_left in [true, false]
          # support: closer to center line, further down
          # oppose: farther out, raised

          direction = if is_left then -1 else 1
          CIRCLE
            cx: 50 + direction * ( 13 + 6 * (1 - props.value))
            cy: 39
            r: 3 #+ 1.6 * (1 - props.value)
            fill: 'white'

        # mouth
        do =>
          frowniness = 5
          mw = 40
          my = 65

          [x1, y1] = [50 - mw / 2, my + frowniness * (1-props.value)]
          [x2, y2] = [50 + mw / 2, y1]

          [qx1, qy1] = [50, my + .5 * frowniness + 2 * frowniness * (2 * props.value - 1)]

          PATH
            stroke: 'white'
            fill: focus_blue
            strokeWidth: 3 
            d: """
              M #{x1} #{y1}
              Q #{qx1} #{qy1}
                #{x2} #{y2}
            """


slider_handles.flat = (props) -> 

  SVG
    height: SLIDER_HANDLE_SIZE
    width: SLIDER_HANDLE_SIZE
    viewBox: "-2 -1 104 104"
    style: 
      pointerEvents: 'none'

    DEFS null,

      CLIPPATH
        id: 'slider-avatar-clip'
        CIRCLE
          cx: 50
          cy: 50
          r: 48

      svg.innerbevel
        id: 'handle-innerbevel'
        shadows: [{color: 'black', opacity: 1, dx: 0, dy: -3, stdDeviation: 3}, \
                  {color: 'white', opacity:  .25, dx:  0, dy: 3, stdDeviation: 3}]        

    CIRCLE
      fill: focus_blue
      stroke: focus_blue
      filter: 'url(#handle-innerbevel)'
      cx: 50
      cy: 50
      r: 50

    do =>
      user = fetch(fetch('/current_user').user)

      if user.avatar_file_name
        IMAGE
          'xlink:href': avatarUrl user, 'large'
          x: 2
          y: 2

          width: 96
          height: 96

          clipPath: 'url(#slider-avatar-clip)'





styles += """
#{css.grab_cursor('.the_handle')}
"""