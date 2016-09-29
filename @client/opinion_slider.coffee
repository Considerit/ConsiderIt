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
    @proposal ||= fetch(@props.proposal)
    slider = fetch @props.key
    your_opinion = fetch @props.your_opinion

    hist = fetch namespaced_key('histogram', @proposal)
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
      left: - (@props.width - PROPOSAL_HISTO_WIDTH()) / 2
      width: @props.width
      height: SLIDER_HANDLE_SIZE()

    if @props.backgrounded
      css.grayscale slider_style

    DIV 
      className: 'opinion_slider'
      style : slider_style

      # Draw the pole labels of the slider
      @drawPoleLabels()

      if (@props.focused || TWO_COL()) && @props.permitted && !hist_selection
        @drawFeedback() 



      Slider
        key: @props.key
        width: @props.width
        handle_height: SLIDER_HANDLE_SIZE()
        base_height: 6
        base_color: if @props.focused 
                      'rgb(175, 215, 255)' 
                    else 
                      'rgb(200, 200, 200)'
        base_endpoint: if slider.docked then 'square' else 'sharp'
        regions: customization('slider_regions', @proposal)
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

        label: "Express your opinion on a slider from #{@props.pole_labels[0][0]} to #{@props.pole_labels[1][0]} about #{@proposal.name}"
        readable_text: (value) => 
          if value > .03
            "#{(value * 100).toFixed(0)}% #{@props.pole_labels[1][0]}"
          else if value < -.03 
            "#{-1 * (value * 100).toFixed(0)}% #{@props.pole_labels[0][0]}"
          else 
            "Neutral"

      @saveYourOpinionNotice()


  saveYourOpinionNotice : -> 
    your_opinion = fetch @props.your_opinion
    slider = fetch @props.key
    current_user = fetch '/current_user'

    return SPAN null if (!TWO_COL() && customization('discussion_enabled', @proposal))  || \
                        ( your_opinion.published || \
                          (!slider.has_moved && your_opinion.point_inclusions.length == 0)\
                        ) || slider.is_moving
    

    style = 
      #backgroundColor: '#eee'
      padding: 10
      color: 'white'
      textAlign: 'center'
      fontSize: 16
      margin: '10px 0'
      position: 'relative'
      fontWeight: 700
      textDecoration: 'underline'
      cursor: 'pointer'
      color: focus_blue

    notice = if current_user.logged_in
               t('save_your_opinion')
             else 
               t('login_to_save_opinion')
    
    s = sizeWhenRendered notice, style


    DIV 
      style: 
        width: @props.width
        margin: 'auto'
        position: 'relative'

      A 
        style: _.extend style, 
          left: (slider.value + 1) / 2 * @props.width - s.width / 2 - 10

        onClick: => saveOpinion(@proposal)

        notice 

        


  drawPoleLabels: ->
    slider = fetch @props.key

    if !slider.docked
      for pole_label, idx in @props.pole_labels
        [main_text, sub_text] = pole_label


        available_x = WHITESPACE() + GUTTER() - 55

        w = Math.max( widthWhenRendered(main_text, {fontSize: 30, maxWidth: available_x}), \
                      widthWhenRendered(sub_text, {fontSize: 14, maxWidth: available_x}))

        DIV 
          key: main_text
          style: 
            position: 'absolute'
            fontSize: 30
            top: -20
            pointerEvents: 'none'
            left: if idx == 0 then -(w + 55)
            right: if idx == 1 then -(w + 55)
            width: w

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

    labels = customization 'slider_pole_labels', @proposal
    slider_feedback = 
      if !slider.has_moved 
        t('Slide Your Overall Opinion')
      else if func = labels.slider_feedback
        func slider.value, @proposal
      else
        if TWO_COL() then t("Your opinion") else ''       

    return SPAN null if slider_feedback == '' 

    feedback_style = 
      pointerEvents: 'none' 
      fontSize: if TWO_COL() then 22 else 30
      fontWeight: if !TWO_COL() then 700
      color: if @props.backgrounded then '#eee' else focus_blue
      #visibility: if @props.backgrounded then 'hidden'

    # Keep feedback centered over handle, but keep within the bounds of 
    # the slider region when the slider is in an extreme position. 
    feedback_left = @props.width * (slider.value + 1) / 2
    feedback_width = widthWhenRendered(slider_feedback, feedback_style) + 10

    if slider.docked 
      if slider.value > 0
        feedback_left = Math.min(@props.width - feedback_width/2, feedback_left)
      else
        feedback_left = Math.max(feedback_width/2, feedback_left)

    _.extend feedback_style, 
      position: 'absolute'      
      top: if slider.docked then -57 else if !TWO_COL() then -80 else 37
      left: feedback_left
      marginLeft: -feedback_width / 2
      width: feedback_width

    H2  
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
    transition = !TWO_COL() && \
       (slider.value == your_opinion.stance || mode == 'results') &&
       customization('discussion_enabled', @proposal)

    if transition
      new_page = if mode == 'results' then 'crafting' else 'results'
      updateProposalMode new_page, 'click_slider'


    # We save the slider's position to the server only on mouse-up.
    # This way you can drag it with good performance.
    if your_opinion.stance != slider.value
      your_opinion.stance = slider.value
      if !transition && fetch('/current_user').logged_in
        your_opinion.published = true
      save your_opinion
      window.writeToLog 
        what: 'move slider'
        details: {stance: slider.value}





