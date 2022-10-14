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


styles += """
  .OpinionSlider {
    position: relative;
  }

  .add_reasons_callout {
    background-color: #{focus_color()};
    color: white;
    font-weight: 600;
    font-size: 10px;
    border-radius: 8px;
    border: none;
    padding: 4px 12px;
    position: absolute;
    opacity: 0;
    transition: opacity .4s ease;
  }

  .ProposalItem:hover .add_reasons_callout {
    opacity: 1;
  }

  .collapsing.ProposalItem:hover .add_reasons_callout {
    opacity: 0;
    display: none;
  }  

"""

window.OpinionSlider = ReactiveComponent
  displayName: 'OpinionSlider'

  render : ->
    proposal = fetch @props.proposal
    slider = fetch @props.slider_key

    your_opinion = @props.your_opinion

    if @props.your_opinion.key
      your_opinion = fetch @props.your_opinion

    show_handle = @props.draw_handle

    mode = get_proposal_mode(proposal)

    # Update the slider value when the server gets back to us
    if slider.value != your_opinion.stance && (!slider.has_moved || @opinion_key != your_opinion.key)
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider
      @opinion_key = your_opinion.key # handle case where opinion is deleted, we want the slider 
                                      # value to reset

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"

    ####
    # Define slider layout      

    rtrn = DIV 
      className: 'OpinionSlider'
      style: 
        width: @props.width
        filter: if @props.backgrounded then 'grayscale(100%)'

      if (@props.focused || (TWO_COL() && @props.is_expanded)) && show_handle
        @drawFeedback() 

      Slider
        slider_key: @props.slider_key
        readable_text: slider_interpretation
        width: @props.width

        base_height: @props.base_height or 2

        base_color: if mode == 'crafting' #slider.docked
                      'rgb(175, 215, 255)' 
                    else 
                      'rgb(153, 153, 153)'


        # base_endpoint: if slider.docked then 'square' else 'sharp'
        regions: customization('slider_regions', proposal)
        polarized: true
        draw_helpers: @props.focused && !slider.has_moved

        handle: @props.handle or slider_handle.flat
        handle_height: @props.handle_height
        handle_width: @props.handle_width

        handle_props: 
          color: if @props.backgrounded then '#ccc' else focus_color()
          detail: @props.focused

        handle_style: 
          transition: "transform #{TRANSITION_SPEED}ms"
          transform: "scale(#{if !@props.focused then 1 else 1.75})"
          visibility: if !show_handle then 'hidden'
        
        onMouseUpCallback: @handleMouseUp
        respond_to_click: false
        offset: @props.offset
        # ticks: 
        #   increment: .5
        #   height: if @props.is_expanded then 5 else 2

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

        show_val_highlighter: @props.show_val_highlighter


        flip: !!@props.shouldFlip
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore


      @saveYourOpinionNotice()
      if @props.show_reasons_callout
        @showReasonsCallout()

    if @props.flip
      FLIPPED 
        flipId: "Opinion-slider-#{@props.slider_key}"
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore

        rtrn

    else 
      rtrn

  showReasonsCallout: ->
    your_opinion = @props.your_opinion
    proposal = @props.proposal

    BUTTON
      className: 'add_reasons_callout'
      style: 
        left: (your_opinion.stance + 1) / 2 * ITEM_OPINION_WIDTH() - 130 / 2 # 130 = width of "Give your Reasons" 
        width: 130
        top: 26
      onClick: => 
        toggle_expand
          proposal: proposal 
          prefer_personal_view: true                   
        
      onKeyPress: (e) => 
        if e.which == 32 || e.which == 13
          toggle_expand
            proposal: proposal
            prefer_personal_view: true                   

      if your_opinion.point_inclusions?.length > 0 
        translator 
          id: "engage.update_your_opinion_button"
          'Update your Reasons'

      else 
        translator 
          id: "engage.give_your_opinion_button"
          'Give your Reasons'

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
      can_opine = @props.permitted()

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
            can_opine = @props.permitted()
            if can_opine > 0
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
        onKeyPress: (e) => 
          if e.which == 32 || e.which == 13
            save_opinion(proposal)

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
    mode = get_proposal_mode(@props.proposal)
    proposal = fetch @props.proposal
    
    e.stopPropagation()

    # Clicking on the slider handle should transition us between crafting <=> results
    transition = @props.is_expanded && personal_view_available(proposal) && \
                 slider.value == your_opinion.stance


    finish_mouseup = =>
      # We save the slider's position to the server only on mouse-up.
      # This way you can drag it with good performance.
      can_opine = @props.permitted() > 0
      if your_opinion.stance != slider.value
        if can_opine
          your_opinion.stance = slider.value
          your_opinion.published = true
          your_opinion.key ?= "/new/opinion"
            
          save your_opinion, -> 
            show_flash(translator('engage.flashes.opinion_saved', "Your opinion has been saved"))
          
            update = fetch('homepage_you_updated_proposal')
            update.dummy = !update.dummy
            save update

          window.writeToLog 
            what: 'move slider'
            details: {stance: slider.value}
        else 
          slider.value = 0
          save slider

      if transition
        new_page = if mode == 'results' then 'crafting' else 'results'
        update_proposal_mode proposal, new_page, 'click_slider'


    can_opine = @props.permitted() > 0 

    if can_opine > 0

      finish_mouseup()

    else
      # trigger authentication
      reset_key 'auth',
        form: 'create account'
        goal: 'To participate, please introduce yourself.'
        after: finish_mouseup



styles += """
.slider_feedback {
  //opacity: 0;
  display: none;
}
:not(.expanding).is_expanded .slider_feedback {
  display: block;
}

"""


