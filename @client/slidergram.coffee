window.Slidergram = ReactiveComponent
  displayName: 'Slidergram'

  render: ->

    statement = fetch @props.statement
    slider_regions = customization('slider_regions', statement, subdomain)

    # Histogram for Proposal
    DIV null,

      Histogram
        key: "histogram-#{proposal.slug}"
        proposal: proposal
        opinions: opinionsForProposal(proposal)
        width: @props.width
        height: 40
        enable_individual_selection: !browser.is_mobile
        enable_range_selection: !just_you && !browser.is_mobile
        draw_base: true
        draw_base_labels: !slider_regions

      Slider 
        base_height: 0
        draw_handle: !!draw_slider
        key: "slider-small-#{proposal.key}"
        width: @props.width
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
            prev_offset = @getDOMNode().offsetTop
            prev_scroll = window.scrollY

            your_opinion.stance = slider.value
            your_opinion.published = true

            your_opinion.key ?= "/new/opinion"
            save your_opinion
            window.writeToLog 
              what: 'move slider'
              details: {proposal: proposal.key, stance: slider.value}
            @local.slid = 1000

            update = fetch('homepage_you_updated_proposal')
            update.dummy = !update.dummy
            save update

          mouse_over_element = closest e.target, (node) => 
            node == @getDOMNode()

          if @local.hover_proposal == proposal.key && !mouse_over_element
            @local.hover_proposal = null 
            save @local