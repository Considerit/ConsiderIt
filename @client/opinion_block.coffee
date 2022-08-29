
styles += """
  .is_collapsed .proposal_scores {
    position: absolute;
    left: calc(100%);
    top: 9px;    
  }

  [data-widget="OpinionBlock"] .slidergram_wrapper {
    display: flex;
  }

  .is_expanded [data-widget="OpinionBlock"] .slidergram_wrapper {
    justify-content: center;
  }
"""


window.OpinionBlock = ReactiveComponent
  displayName: 'OpinionBlock'

  render: ->
    proposal = fetch @props.proposal 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    show_proposal_scores = !@props.hide_scores && customization('show_proposal_scores', proposal, subdomain) && WINDOW_WIDTH() > 955
    show_proposal_scores = false 

    @expansion_state_changed = @props.expansion_state_changed
    @is_expanded = @props.is_expanded

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"


    # Histogram for Proposal
    DIV 
      "data-widget": 'OpinionBlock'

      DIV 
        className: 'slidergram_wrapper'

        Slidergram @props

    
      # little score feedback
      if show_proposal_scores        

        FLIPPED 
          flipId: "proposal_scores-#{proposal.key}"

          DIV 
            className: 'proposal_scores'


            HistogramScores
              proposal: proposal.key


styles += """
  [data-widget="Slidergram"] {
    display: inline-block;
    position: relative;
    top: -26px;
  }
"""

window.Slidergram = ReactiveComponent
  displayName: "Slidergram"

  render: ->

    @expansion_state_changed = @props.expansion_state_changed
    @is_expanded = @props.is_expanded

    proposal = fetch @props.proposal 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    col_sizes = column_sizes
                  width: @props.width

    # watching = current_user.subscriptions[proposal.key] == 'watched'
    # return if !watching && fetch('homepage_filter').watched


    your_opinion = proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion.key 

    if your_opinion.published
      can_opine = permit 'update opinion', proposal, your_opinion, subdomain
    else
      can_opine = permit 'publish opinion', proposal, subdomain

    draw_slider = can_opine > 0 || your_opinion.published

    slider_regions = customization('slider_regions', proposal, subdomain)

    opinions = opinionsForProposal(proposal)

    if draw_slider
      slider = fetch "homepage_slider#{proposal.key}"
    else 
      slider = null 

    if slider && your_opinion && slider.value != your_opinion.stance && !slider.has_moved 
      # Update the slider value when the server gets back to us
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider

    opinion_views = fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']

    width = col_sizes.second * (if @is_expanded then 2 else 1)

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"

    DIV 
      "data-widget": "Slidergram"
      # style: 
      #   width: width
              
      Histogram
        histo_key: "histogram-#{proposal.slug}"
        proposal: proposal.key
        opinions: opinions
        width: width
        height: if !@is_expanded then 40 else if screencasting() then 120 else 170
        enable_individual_selection: !@props.disable_selection && !browser.is_mobile
        enable_range_selection: !just_you && !browser.is_mobile && !ONE_COL()
        draw_base: true
        draw_base_labels: !slider_regions
        flip: true
        flip_state_changed: @props.expansion_state_changed


      Slider 
        slider_key: "homepage_slider#{proposal.key}"
        flip: true
        base_height: 0
        draw_handle: !!draw_slider
        width: width
        polarized: true
        regions: slider_regions
        respond_to_click: false
        base_color: 'transparent'
        handle: slider_handle.triangley
        handle_height: 18
        handle_width: 21
        handle_style: 
          opacity: if just_you && !browser.is_mobile && @local.hover_proposal != proposal.key && !@local.slider_has_focus then 0 else 1             
        offset: true
        ticks: 
          increment: .5
          height: 2

        handle_props:
          use_face: false
        label: translator
                  id: "sliders.instructions"
                  negative_pole: get_slider_label("slider_pole_labels.oppose", proposal, subdomain)
                  positive_pole: get_slider_label("slider_pole_labels.support", proposal, subdomain)
                  "Express your opinion on a slider from {negative_pole} to {positive_pole}"
        onBlur: (e) => @local.slider_has_focus = false; save @local
        onFocus: (e) => @local.slider_has_focus = true; save @local 

        readable_text: slider_interpretation
        onMouseUpCallback: (e) =>
          # We save the slider's position to the server only on mouse-up.
          # This way you can drag it with good performance.
          if your_opinion.stance != slider.value

            # save distance from top that the proposal is at, so we can 
            # maintain that position after the save potentially triggers 
            # a re-sort. 
            prev_offset = ReactDOM.findDOMNode(@).offsetTop
            prev_scroll = window.scrollY

            your_opinion.stance = slider.value
            your_opinion.published = true

            your_opinion.key ?= "/new/opinion"
            save your_opinion, ->
              show_flash(translator('engage.flashes.opinion_saved', "Your opinion has been saved"))

            window.writeToLog 
              what: 'move slider'
              details: {proposal: proposal.key, stance: slider.value}
            @local.slid = 1000

            update = fetch('homepage_you_updated_proposal')
            update.dummy = !update.dummy
            save update

          mouse_over_element = closest e.target, (node) => 
            node == ReactDOM.findDOMNode(@)

          if @local.hover_proposal == proposal.key && !mouse_over_element
            @local.hover_proposal = null 
            save @local    