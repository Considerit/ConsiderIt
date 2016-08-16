##
# Slider
#
# A generic slider. A slider has a base and a handle that can be moved. 
# Supports movement by touch, mouse, and click events. 
#
# State
#
#  - value (default = -1.0)
#    The relative location of the handle along the slider base. Depending on the 
#    'polarized' prop, will either be in [0, 1] or [-1, 1].
#
#  - has_moved (default = false)
#    Whether the user has moved the slider handle
#
#  - is_moving (default = false)
#    Whether the handle is currently being moved
#
# Props
#
#  - key
#    Where this slider will store state. 
#
#  - width
#    Width of the slider base (and containing element)
#
#  - base_height (default = 6)
#    Height of the slider base
# 
#  - base_color (default is a mid gray)
#    Color of the slider base
#
#  - base_endpoint (default is 'square')
#    Style with which to render the end of either side of the slider base. 
#    Currently supported values include:
#       square: flat endpoints
#       sharp: arrow endpoints that don't extend above or below the base
#    If you pass a string, that value will apply to both endpoints. 
#    If you pass an array of two strings, those will apply to the left and
#    right endpoints respectively. 
#    
#  - polarized (default = false)
#    If true, the slider is polarized, and value will vary from [-1.0, 1.0].
#    If false, the value will be on [0.0, 1.0].
#
#  - draw_helpers (default = false)
#    If true, two angle brackets will be drawn on either side of the slider 
#    handle if the user has not yet moved the slider. 
#
#  - handle (default = slider_handle.flat)
#    A function that will draw the handle itself. Most likely a selection
#    from window.slider_handle (defined later in this file)
#
#  - handle_height (default = 6)
#    Height of the slider handle
#
#  - handle_props
#    Any special properties you want to pass onto the handle function
# 
#  - handle_style
#    styles to apply to the handle wrapper
#
#  - respond_to_click (default = true)
#    Whether the slider handle should update based on a click somewhere
#    along the slider base. 
#
#  - onMouseDownCallback(ev)
#    Called after the slider is finished processing a mousedown or its
#    touch equivalent.
#
#  - onMouseUpCallback(ev)
#    Called after the slider is finished processing a mouseup or its
#    touch equivalent.
#
#  - onMouseMoveCallback(ev)
#    Called after the slider is finished processing a mousemove or its
#    touch equivalent.
#
#  - onClickCallback(ev)
#    Called after the slider is finished processing a click or tap on
#    the slider base. 



require './shared'

window.Slider = ReactiveComponent
  displayName: 'Slider'

  getDefaultProps : -> 
    return {
      handle_height: 6
      base_height: 6
      base_endpoint: 'square'
      base_color: 'rgb(160, 160, 160)'
      polarized: false
      draw_helpers: false
      respond_to_click: true
    }

  render : ->

    slider = fetch @props.key

    if !@props.draw_handle?
      @props.draw_handle = true

    # initialize
    if !slider.value?
      _.defaults slider,
        value: if @props.polarized then -1.0 else 0
        has_moved : false
        is_moving : false
      save slider

    ####
    # Define slider layout
    slider_style = _.defaults {}, (@props.slider_style || {}),
      width: @props.width
      height: Math.max @props.base_height, @props.handle_height
      position: 'relative'

    DIV 
      className: 'slider'
      style : slider_style

      @drawSliderBase()
      if @props.draw_handle
        @drawSliderHandle()


  drawSliderBase: -> 
    slider = fetch @props.key

    slider_base_style = 
      width: @props.width
      height: @props.base_height
      backgroundColor: @props.base_color
      position: 'absolute'


    if typeof(@props.base_endpoint) == 'string'
      endpoints = [@props.base_endpoint, @props.base_endpoint]
    else
      endpoints = @props.base_endpoint

    DIV 
      ref: 'base'
      style : slider_base_style
      onClick: @handleMouseClick

      # Draw the endpoints on either side of the base
      for endpoint, idx in endpoints
        continue if endpoint == 'square'

        if endpoint == 'sharp'
          DIV 
            key: "endpoint-#{idx}"
            style: 
              position: 'absolute'
              left: if idx == 0 then -5
              right: if idx == 1 then -5
              width: 5
              height: slider_base_style.height
              backgroundColor: slider_base_style.backgroundColor

            DIV
              style: cssTriangle \
                       (if idx == 0 then 'left' else 'right'), \
                       slider_base_style.backgroundColor, 12, 6,               
                          position: 'absolute'
                          left: if idx == 0 then -12
                          right: if idx == 1 then -12

      if @props.regions
        d =  @props.width / (@props.regions.length)

        sty = 
          color: '#BDBDBD'
          fontSize: 14

        for region, idx in @props.regions
          w = sizeWhenRendered region.abbrev, sty
          DIV 
            style: _.extend {}, sty,
              color: '#BDBDBD'
              fontSize: 14
              position: 'absolute'
              left: (idx + .5) * d - w.width / 2
              top: 4

            region.abbrev


  drawSliderHandle: -> 
    handle_width = handle_height = @props.handle_height

    slider = fetch @props.key

    sliderHandle = @props.handle or slider_handle.flat

    DIV 
      className: 'the_handle' 
      onMouseUp: @handleMouseUp
      onTouchEnd: @handleMouseUp
      onTouchCancel: @handleMouseUp

      onMouseDown: @handleMouseDown
      onTouchStart: @handleMouseDown

      onTouchMove: @handleMouseMove

      style: css.crossbrowserify _.extend (@props.handle_style || {}), 
        width: handle_width
        height: handle_height
        top: if @props.offset then 0 else -(handle_height - @props.base_height) / 2
        position: 'relative'
        marginLeft: -handle_width / 2
        zIndex: 10
        left: if @props.polarized
                @props.width * (slider.value + 1) / 2
              else 
                @props.width * slider.value

      sliderHandle _.extend (@props.handle_props || {}),
        value: if @props.polarized then (slider.value + 1) / 2 else slider.value
        handle_height: handle_height
        handle_width: handle_width

      if @props.draw_helpers
        for support in [true, false]
          DIV 
            style: 
              right: if support then -15
              left: if !support then -15
              position: 'absolute'
              top: 4
              color: focus_blue
              fontSize: 12
              pointerEvents: 'none'
            if support then '>' else '<'   


  # Kick off sliding 
  handleMouseDown: (e) -> 
    el = @getDOMNode()
    
    e.preventDefault()

    # Initiate dragging
    slider = fetch @props.key
    slider.is_moving = true
    save slider

    # adjust for starting location - offset
    @local.starting_adjustment = (parseInt($(e.currentTarget)[0].style.left, 10) || 0) - \
                                 (e.clientX or e.touches[0].clientX)
    save @local

    @props.onMouseDownCallback(e) if @props.onMouseDownCallback

    $(window).on "mousemove.slider", @handleMouseMove
    $(window).on "mouseup.slider", @handleMouseUp

  # While sliding
  handleMouseMove: (e) ->
    e.preventDefault() # prevents text selection of surrounding elements

    slider = fetch @props.key

    clientX = e.clientX or e.touches[0].clientX

    # Update position
    x = clientX + @local.starting_adjustment
    x = if x < 0
          0
        else if x > @props.width
          @props.width
        else
          x

    slider.has_moved = true

    # normalize position of handle into slider value
    slider.value = x / @props.width
    if @props.polarized
      slider.value = slider.value * 2 - 1


    slider.value = Math.round(slider.value * 10000) / 10000
    save slider

    @props.onMouseMoveCallback(e) if @props.onMouseMoveCallback

  # Stop sliding
  handleMouseUp: (e) ->
    # Don't do anything if we're not actually dragging. We only hit this logic
    # if there is some delay in removing the event handlers.
    slider = fetch @props.key

    return if !slider.is_moving

    e.preventDefault()

    # Turn off dragging
    slider.is_moving = false
    save slider

    @props.onMouseUpCallback(e) if @props.onMouseUpCallback

    $(window).off ".slider" # Remove event handlers

  handleMouseClick: (e) -> 
    if @props.respond_to_click
      e.preventDefault() # prevents text selection of surrounding elements

      clientX = e.clientX or e.touches[0].clientX

      val = (clientX - $(@refs.base.getDOMNode()).offset().left) / @props.width
      if val < 0 
        val = 0
      if val > 1
        val = 1

      if @props.polarized
        val = val * 2 - 1

      slider = fetch @props.key
      slider.has_moved = true

      slider.value = Math.round(val * 10000) / 10000

      save slider

      @props.onClickCallback(e) if @props.onClickCallback



####
# Slider handles
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

window.slider_handle ||= {}

slider_handle.face = (props) -> 

  SVG
    height: props.handle_height
    width: props.handle_width
    viewBox: "-2 -1 104 104"
    style: 
      pointerEvents: 'none'
      position: 'absolute'
      top: 0

    DEFS null,
      svg.innerbevel
        id: 'handle-innerbevel'
        shadows: [{color: 'black', opacity: 1.0, dx: 0, dy: -3, stdDeviation: 3}, \
                  {color: 'white', opacity: .25, dx: 0, dy:  3, stdDeviation: 3}]        

    CIRCLE
      fill: props.color
      stroke: props.color
      cx: 50
      cy: 50
      r: 50

    G null,
      
      CIRCLE
        fill: props.color
        filter: "url(#handle-innerbevel)"

        cx: 50
        cy: 50
        r: 50

      if props.detail
        G null,
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

slider_handle.triangley = (props) ->
  svg_props = 
    height: props.handle_height
    width: props.handle_width
    viewBox: "0 0 21 18"
    style: 
      pointerEvents: 'none'
      position: 'absolute'
      top: 0
      zIndex: 10

  SVG svg_props,
    DEFS null, 
      FILTER 
        id: "triangley_filter"
        x: "-50%" 
        y: "-50%" 
        width: "200%" 
        height: "200%" 
        filterUnits: "objectBoundingBox" 

        FEOFFSET 
          dx: "0" 
          dy: "1" 
          'in': "SourceAlpha" 
          result: "shadowOffsetOuter1"

        FEGAUSSIANBLUR 
          stdDeviation: "0.5" 
          'in': "shadowOffsetOuter1" 
          result: "shadowBlurOuter1"

        FECOLORMATRIX 
          values: "0 0 0 0 0   0 0 0 0 0   0 0 0 0 0  0 0 0 0.16479563 0" 
          'in': "shadowBlurOuter1" 
          type: "matrix" 
          result: "shadowMatrixOuter1"

        FEOFFSET
          dx: "0"
          dy: "-1"
          'in': "SourceAlpha"
          result: "shadowOffsetInner1"

        FEGAUSSIANBLUR
          stdDeviation: "1" 
          'in': "shadowOffsetInner1" 
          result: "shadowBlurInner1"

        FECOMPOSITE
          'in': "shadowBlurInner1" 
          in2: "SourceAlpha" 
          operator: "arithmetic" 
          k2: "-1" 
          k3: "1" 
          result: "shadowInnerInner1"

        FECOLORMATRIX
          values: "0 0 0 0 0   0 0 0 0 0   0 0 0 0 0  0 0 0 0.5 0" 
          'in': "shadowInnerInner1" 
          type: "matrix" 
          result: "shadowMatrixInner1"

        FEMERGE null, 
          FEMERGENODE 'in': "shadowMatrixOuter1"
          FEMERGENODE 'in': "SourceGraphic"
          FEMERGENODE 'in': "shadowMatrixInner1"

    G 
      stroke: "none" 
      strokeWidth: "0" 
      fill: focus_blue 
      fillRule: "evenodd"

      PATH 
        d: "M1,6 L20,6 L20,16 L1,16 L1,6 Z M10.5,0 L20,6 L1,6 L10.5,0 Z"
        fill: focus_blue
        filter: "url(#triangley_filter)" 


slider_handle.flat = (props) -> 
  svg_props = 
    height: props.handle_height
    width: props.handle_width
    viewBox: "-2 -1 104 104"
    style: 
      pointerEvents: 'none'
      position: 'absolute'
      top: 0
      zIndex: 10

  SVG svg_props,

    DEFS null,

      CLIPPATH
        id: 'slider-avatar-clip'
        CIRCLE
          cx: 50
          cy: 50
          r: 48

      # svg.innerbevel
      #   id: 'handle-innerbevel'
      #   shadows: [{color: 'black', opacity: 1, dx: 0, dy: -3, stdDeviation: 3}, \
      #             {color: 'white', opacity:  .25, dx:  0, dy: 3, stdDeviation: 3}]        

    CIRCLE
      fill: props.color
      stroke: props.color
      #filter: 'url(#handle-innerbevel)'
      cx: 50
      cy: 50
      r: 50

    if props.use_face
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
