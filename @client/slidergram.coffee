window.Slidergram = ReactiveComponent
  displayName: 'Slidergram'

  render: ->
    subdomain = fetch '/subdomain'

    statement = fetch @props.statement
    slider_regions = customization('slider_regions', statement, subdomain)

    opinion_views = fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", statement, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", statement, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"

    your_opinion = statement.your_opinion
    fetch (your_opinion.key) if your_opinion.key 

    if your_opinion.published
      can_opine = permit 'update opinion', statement, your_opinion, subdomain
    else
      can_opine = permit 'publish opinion', statement, subdomain

    enable_sliding = can_opine > 0 || your_opinion.published

    if enable_sliding
      slider = fetch "slidergram-#{statement.key}"
    else 
      slider = null 

    if slider && your_opinion && slider.value != your_opinion.stance && !slider.has_moved 
      # Update the slider value when the server gets back to us
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider

    DIV null,

      Histogram
        key: "histogram-#{statement.key}"
        statement: statement
        opinions: opinions_for_statement statement
        width: @props.width
        height: 40
        enable_individual_selection: !browser.is_mobile
        enable_range_selection: !just_you && !browser.is_mobile
        draw_base: true
        draw_base_labels: !slider_regions

      Slider 
        base_height: 0
        draw_handle: !!enable_sliding
        key: "slidergram-#{statement.key}"
        width: @props.width
        polarized: true
        regions: slider_regions
        respond_to_click: false
        base_color: 'transparent'
        handle: slider_handle.triangley
        handle_height: 18
        handle_width: 21
        # handle_style: 
        #   opacity: if just_you && !browser.is_mobile && @local.hover_proposal != proposal.key && !@local.slider_has_focus then 0 else 1             
        offset: true
        ticks: 
          increment: .5
          height: 2

        handle_props:
          use_face: false
        label: translator
                  id: "sliders.instructions"
                  negative_pole: get_slider_label("slider_pole_labels.oppose", statement, subdomain)
                  positive_pole: get_slider_label("slider_pole_labels.support", statement, subdomain)
                  "Express your opinion on a slider from {negative_pole} to {positive_pole}"
        # onBlur: (e) => @local.slider_has_focus = false; save @local
        # onFocus: (e) => @local.slider_has_focus = true; save @local 

        readable_text: slider_interpretation
        onMouseUpCallback: (e) =>
          # We save the slider's position to the server only on mouse-up.
          # This way you can drag it with good performance.
          if your_opinion.stance != slider.value

            # save distance from top that the proposal is at, so we can 
            # maintain that position after the save potentially triggers 
            # a re-sort. 
            prev_offset = @getDOMNode().offsetTop
            prev_scroll = window.scrollY

            your_opinion.stance = slider.value
            your_opinion.published = true

            your_opinion.key ?= "/new/opinion"
            save your_opinion
            window.writeToLog 
              what: 'move slider'
              details: {statement: statement.key, stance: slider.value}
            @local.slid = 1000

            update = fetch('slider_dragged')
            update.dummy = !update.dummy
            save update

          mouse_over_element = closest e.target, (node) => 
            node == @getDOMNode()

          # if @local.hover_proposal == proposal.key && !mouse_over_element
          #   @local.hover_proposal = null 
          #   save @local