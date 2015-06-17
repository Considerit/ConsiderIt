######
# OpinionSlider
#
# Manages the slider as connected to an opinion. The main slider in Considerit. 
#   - labels for the poles of the slider
#   - feedback description about the current opinion
#   - creates a Slider instance
#
# TODO:
#   - better documentation
#   - refactor the code in light of extracting Slider

require './slider'
require './shared'
require './customizations'

window.OpinionSlider = ReactiveComponent
  displayName: 'OpinionSlider'

  render : ->
    slider = fetch @props.key
    hist = fetch namespaced_key('histogram', @proposal)

    your_opinion = fetch @props.your_opinion

    hist_selection = hist.selected_opinions || hist.selected_opinion

    # Update the slider value when the server gets back to us
    if slider.value != your_opinion.stance && !slider.has_moved 
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider

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
      className: 'opinion_slider'
      style : slider_style

      # Draw the pole labels of the slider
      @drawPoleLabels()

      if (@props.focused || TWO_COL) && @props.permitted
        @drawFeedback() 

      Slider
        key: @props.key
        width: @props.width
        handle_height: SLIDER_HANDLE_SIZE
        base_height: 6
        base_color: if @props.focused 
                      'rgb(175, 215, 255)' 
                    else 
                      'rgb(200, 200, 200)'
        base_endpoint: if slider.docked then 'square' else 'sharp'
        polarized: true
        draw_helpers: @props.focused && !slider.has_moved
        handle: if @props.backgrounded 
                  slider_handle.flat 
                else 
                  customization('slider_handle', @proposal)
        handle_props: 
          color: if @props.backgrounded then '#ccc' else focus_blue
          detail: @props.focused
        handle_style: 
          transition: "transform #{TRANSITION_SPEED}ms"
          transform: "scale(#{if !@props.focused || slider.docked then 1 else 2.5})"
          visibility: if hist_selection || !@props.permitted then 'hidden'
        onMouseUpCallback: @handleMouseUp
        respond_to_click: false


  drawPoleLabels: ->
    slider = fetch @props.key

    if !slider.docked
      for pole_label, idx in @props.pole_labels
        [main_text, sub_text] = pole_label

        w = Math.max( widthWhenRendered(main_text, {fontSize: 30}), \
                      widthWhenRendered(sub_text, {fontSize: 14}))
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
          key: "small-#{pole_label[0]}"
          style: 
            position: 'absolute'
            fontSize: 20
            top: -12
            pointerEvents: 'none'
            left: if idx == 0 then -15
            right: if idx == 1 then -20

          if idx == 0 then '–' else '+'

  drawFeedback: -> 
    slider = fetch @props.key

    slider_feedback = 
      if !slider.has_moved 
        'Slide Your Overall Opinion' 
      else if !customization('show_slider_feedback', @proposal)
        ""
      else if isNeutralOpinion slider.value
        "You are Undecided"
      else 
        degree = Math.abs slider.value
        strength_of_opinion = if degree > .999
                                "Fully "
                              else if degree > .5
                                "Firmly "
                              else
                                "Slightly " 

        valence = customization "slider_pole_labels.individual." + \
                                (if slider.value > 0 then 'support' else 'oppose'), \
                                @proposal

        "You #{strength_of_opinion} #{valence}"

    feedback_style = 
      pointerEvents: 'none' 
      fontSize: if TWO_COL then 22 else 30
      fontWeight: if !TWO_COL then 700
      color: if @props.backgrounded then '#eee' else focus_blue
      #visibility: if @props.backgrounded then 'hidden'

    # Keep feedback centered over handle, but keep within the bounds of 
    # the slider region when the slider is in an extreme position. 
    feedback_left = @props.width * (slider.value / 2 + .5)
    feedback_width = widthWhenRendered(slider_feedback, feedback_style) + 10

    if slider.docked 
      if slider.value > 0
        feedback_left = Math.min(@props.width - feedback_width/2, feedback_left)
      else
        feedback_left = Math.max(feedback_width/2, feedback_left)

    _.extend feedback_style, 
      position: 'absolute'      
      top: if slider.docked then -57 else if !TWO_COL then -80 else 30
      left: feedback_left
      marginLeft: -feedback_width / 2
      width: feedback_width

    DIV 
      style: feedback_style
      slider_feedback

  handleMouseUp: (e) ->
    slider = fetch @props.key
    your_opinion = fetch @props.your_opinion
    mode = get_proposal_mode()
    
    e.stopPropagation()

    # Clicking on the slider handle should transition us between 
    # crafting <=> results. We should also transition to crafting 
    # when we've been dragging on the results page.
    if !TWO_COL && (slider.value == your_opinion.stance || mode == 'results')
      new_page = if mode == 'results' then 'crafting' else 'results'
      updateProposalMode new_page, 'click_slider'

    # We save the slider's position to the server only on mouse-up.
    # This way you can drag it with good performance.
    if your_opinion.stance != slider.value
      your_opinion.stance = slider.value
      save your_opinion
      window.writeToLog 
        what: 'move slider'
        details: {stance: slider.value}





