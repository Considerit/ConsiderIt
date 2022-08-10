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
    proposal = fetch @props.proposal
    slider = fetch @props.slider_key

    your_opinion = @props.your_opinion

    if @props.your_opinion.key
      your_opinion = fetch @props.your_opinion

    opinion_views = fetch 'opinion_views'
    hist_selection = opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected
    show_handle = @props.permitted && !hist_selection




    # Update the slider value when the server gets back to us
    if slider.value != your_opinion.stance && (!slider.has_moved || @opinion_key != your_opinion.key)
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider
      @opinion_key = your_opinion.key # handle case where opinion is deleted, we want the slider 
                                      # value to reset


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

      if (@props.focused || TWO_COL()) && show_handle
        @drawFeedback() 

      Slider
        slider_key: @props.slider_key
        width: @props.width
        handle_height: SLIDER_HANDLE_SIZE()
        base_height: 2 # 6
        # base_color: 'transparent'
        base_color: if slider.docked
                      'rgb(175, 215, 255)' 
                    else 
                      'transparent'
        # base_endpoint: if slider.docked then 'square' else 'sharp'
        regions: customization('slider_regions', proposal)
        polarized: true
        draw_helpers: @props.focused && !slider.has_moved
        handle: if @props.backgrounded 
                  slider_handle.flat 
                else 
                  customization('slider_handle', proposal) or slider_handle.flat
        handle_props: 
          color: if @props.backgrounded then '#ccc' else focus_color()
          detail: @props.focused
        handle_style: 
          transition: "transform #{TRANSITION_SPEED}ms"
          transform: "scale(#{if !@props.focused then 1 else 1.75})"
          visibility: if !show_handle then 'hidden'
        
        onMouseUpCallback: @handleMouseUp
        respond_to_click: false
        ticks: 
          increment: .5
          height: 5
        label: translator
                 id: "sliders.instructions-with-proposal"
                 negative_pole: @props.pole_labels[0]
                 positive_pole: @props.pole_labels[1]
                 proposal_name: proposal.name
                 "Express your opinion on a slider from {negative_pole} to {positive_pole} about {proposal_name}"
        readable_text: (value) => 
          if value > .03
            "#{(value * 100).toFixed(0)}% #{@props.pole_labels[1]}"
          else if value < -.03 
            "#{-1 * (value * 100).toFixed(0)}% #{@props.pole_labels[0]}"
          else 
            translator "sliders.feedback-short.neutral", "Neutral"

      @saveYourOpinionNotice()


  saveYourOpinionNotice : -> 
    proposal = fetch @props.proposal
    your_opinion = @props.your_opinion
    slider = fetch @props.slider_key
    current_user = fetch '/current_user'

    return SPAN null if (!TWO_COL() && customization('discussion_enabled', proposal))  || \
                         current_user.logged_in || slider.is_moving
    

    style = 
      #backgroundColor: '#eee'
      padding: 10
      color: 'white'
      textAlign: 'center'
      fontSize: 16
      position: 'relative'
      fontWeight: 700
      textDecoration: 'underline'
      cursor: 'pointer'
      color: focus_color()

    notice = translator "engage.login_to_save_opinion", 'Log in to save your opinion'
    
    s = sizeWhenRendered notice, style

    save_opinion = (proposal) -> 
      if your_opinion.published
        can_opine = permit 'update opinion', proposal, your_opinion
      else
        can_opine = permit 'publish opinion', proposal

      if can_opine > 0
        your_opinion.published = true
        your_opinion.key ?= "/new/opinion"
        save your_opinion, ->
          show_flash(translator('engage.flashes.opinion_saved', "Your opinion has been saved"))

      else
        # trigger authentication
        reset_key 'auth',
          form: 'create account'
          goal: 'To participate, please introduce yourself.'
          after: =>
            save_opinion(proposal)


    DIV 
      style: 
        width: @props.width
        margin: 'auto'
        position: 'relative'

      BUTTON
        className: 'like_link'
        style: _.extend style, 
          left: (slider.value + 1) / 2 * @props.width - s.width / 2 - 10

        onClick: => save_opinion(proposal)

        notice 

  drawFeedback: -> 
    proposal = fetch @props.proposal
    slider = fetch @props.slider_key
    default_feedback = (value) -> 
      if Math.abs(value) < 0.02
        translator "sliders.feedback.neutral", "You are neutral"
      else 
        "#{Math.round(value * 100)}%"

    labels = customization 'slider_pole_labels', proposal
    slider_feedback = 

      if !slider.has_moved 
        translator "sliders.slide_prompt", 'Slide Your Overall Opinion'
      else if func = labels.slider_feedback or default_feedback
        func slider.value, proposal
      else if TWO_COL() 
        translator "sliders.slide_feedback_short", "Your opinion"
      else 
        ''

    return SPAN null if slider_feedback == '' 

    feedback_style = 
      pointerEvents: 'none' 
      fontSize: if TWO_COL() then "22px" else "30px"
      fontWeight: if !TWO_COL() then 700
      color: if @props.backgrounded then '#eee' else focus_color()
      textAlign: 'center'
      #visibility: if @props.backgrounded then 'hidden'

    # Keep feedback centered over handle, but keep within the bounds of 
    # the slider region when the slider is in an extreme position. 
    feedback_left = @props.width * (slider.value + 1) / 2
    feedback_width = widthWhenRendered(slider_feedback, feedback_style) + 10

    # if slider.docked 
    #   if slider.value > 0
    #     feedback_left = Math.min(@props.width - feedback_width/2, feedback_left)
    #   else
    #     feedback_left = Math.max(feedback_width/2, feedback_left)

    _.extend feedback_style, 
      position: 'absolute'      
      top: if !TWO_COL() then -80 else 37
      left: feedback_left
      marginLeft: -feedback_width / 2
      width: feedback_width

    DIV
      className: 'slider_feedback'
      'aria-hidden' : true
      style: feedback_style
      slider_feedback

  handleMouseUp: (e) ->
    slider = fetch @props.slider_key
    your_opinion = @props.your_opinion
    mode = get_proposal_mode()
    proposal = fetch @props.proposal
    
    e.stopPropagation()

    # Clicking on the slider handle should transition us between 
    # crafting <=> results. We should also transition to crafting 
    # when we've been dragging on the results page.
    transition = !TWO_COL() && \
       (slider.value == your_opinion.stance || mode == 'results') &&
       customization('discussion_enabled', proposal)

    if transition


      if your_opinion.published
        can_opine = permit 'update opinion', proposal, your_opinion
      else
        can_opine = permit 'publish opinion', proposal

      if can_opine > 0
        new_page = if mode == 'results' then 'crafting' else 'results'
        updateProposalMode new_page, 'click_slider'
      else
        # trigger authentication
        reset_key 'auth',
          form: 'create account'
          goal: 'To participate, please introduce yourself.'
          after: =>
            new_page = if mode == 'results' then 'crafting' else 'results'
            updateProposalMode new_page, 'click_slider'




    # We save the slider's position to the server only on mouse-up.
    # This way you can drag it with good performance.
    if your_opinion.stance != slider.value
      your_opinion.stance = slider.value
      if !transition && fetch('/current_user').logged_in
        your_opinion.published = true
      your_opinion.key ?= "/new/opinion"
        
      save your_opinion, -> 
        show_flash(translator('engage.flashes.opinion_saved', "Your opinion has been saved"))
      
      window.writeToLog 
        what: 'move slider'
        details: {stance: slider.value}





