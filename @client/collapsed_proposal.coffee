require './shared'
require './customizations'
require './histogram'
require './slider'
require './permissions'
require './watch_star'
require './bubblemouth'


pad = (num, len) -> 
  str = num
  dec = str.split('.')
  i = 0 
  while i < len - dec[0].toString().length
    dec[0] = "0" + dec[0]
    i += 1

  dec[0] + if dec.length > 0 then '.' + dec[1] else ''

window.CollapsedProposal = ReactiveComponent
  displayName: 'CollapsedProposal'

  render : ->
    proposal = fetch @props.proposal
    options = @props.options

    # we want to update if the sort order changes so that we can 
    # resolve @local.keep_in_view
    fetch("cluster-#{slugify(proposal.cluster or 'Proposals')}/sort_order")

    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

    your_opinion = fetch proposal.your_opinion
    if your_opinion?.published
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    draw_slider = can_opine > 0 || your_opinion?.published

    icons = customization('show_proposer_icon', proposal)
    slider_regions = customization('slider_regions', proposal)
    show_proposal_scores = customization('show_proposal_scores', proposal)

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

    # sub_creation = new Date(fetch('/subdomain').created_at).getTime()
    # creation = new Date(proposal.created_at).getTime()
    # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

    LI
      key: proposal.key
      id: 'p' + proposal.slug.replace('-', '_')  # Initial 'p' is because all ids must begin 
                                           # with letter. seeking to hash was failing 
                                           # on proposals whose name began with number.
      style:
        minHeight: 70
        position: 'relative'
        margin: "0 0 15px 0"
        padding: 0
        listStyle: 'none'

      onMouseEnter: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onMouseLeave: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local

      DIV style: first_column,

        DIV 
          style: 
            position: 'absolute'
            left: if icons then -50 - 18

          if current_user?.logged_in
            # ability to watch proposal
            
            WatchStar
              proposal: proposal
              size: 30
              style: 
                position: 'absolute'
                left: -40
                top: 5


          if icons
            editor = proposal_editor(proposal)
            # Person's icon
            if editor 
              A
                href: proposal_url(proposal)
                'aria-hidden': true
                tabIndex: -1
                Avatar
                  key: editor
                  user: editor
                  style:
                    height: 50
                    width: 50
                    borderRadius: 0
                    backgroundColor: '#ddd'
                    # opacity: opacity
            else 
              SPAN 
                style: 
                  height: 50
                  width: 50
                  display: 'inline-block'
                  verticalAlign: 'top'
                  border: "2px dashed #ddd"

        # Name of Proposal
        DIV
          style:
            display: 'inline-block'
            fontWeight: 400
            paddingBottom: 20
            width: first_column.width

          A
            className: 'proposal proposal_homepage_name'
            style: 
              fontWeight: 500
              borderBottom: "1px solid #444"  
              color: '#000'            
              
            href: proposal_url(proposal)

            proposal.name

          DIV 
            style: 
              fontSize: 16
              color: "#999"
              fontStyle: 'italic'
              marginTop: 2

            if customization('show_proposal_meta_data')
              SPAN 
                style: {}

                prettyDate(proposal.created_at)

                if !icons && (editor = proposal_editor(proposal)) && editor == proposal.user
                  SPAN 
                    style: {}

                    " by #{fetch(editor)?.name}"

                SPAN 
                  style: 
                    paddingRight: 16

            if @props.show_category && proposal.cluster
              cluster = proposal.cluster 
              if fetch('/subdomain').name == 'dao' && proposal.cluster == 'Proposals'
                cluster = 'Ideas'

              SPAN 
                style: 
                  #border: "1px solid #{@props.category_color}"
                  backgroundColor: @props.category_color
                  padding: '1px 2px'
                  color: 'white' #@props.category_color
                  fontStyle: 'normal'
                  fontSize: 12


                cluster


            if !proposal.active
              SPAN 
                style: {}

                t('closed')


      # Histogram for Proposal
      DIV 
        style: 
          display: 'inline-block' 
          position: 'relative'
        # A
        #   href: proposal_url(proposal)

        DIV
          style: secnd_column
                

          Histogram
            key: "histogram-#{proposal.slug}"
            proposal: proposal
            opinions: opinions
            width: secnd_column.width
            height: 50
            enable_selection: false
            draw_base: true
            draw_base_labels: !slider_regions

          Slider 
            base_height: 0
            draw_handle: !!draw_slider
            key: "homepage_slider#{proposal.key}"
            width: secnd_column.width
            polarized: true
            regions: slider_regions
            respond_to_click: false
            base_color: 'transparent'
            handle: slider_handle.triangley
            handle_height: 18
            handle_width: 21
            handle_style: 
              opacity: if !browser.is_mobile && @local.hover_proposal != proposal.key && !@local.slider_has_focus then 0 else 1             
            offset: true
            handle_props:
              use_face: false
            label: "Express your opinion on a slider from #{customization("slider_pole_labels.oppose", proposal)} to #{customization("slider_pole_labels.support", proposal)}"
            onBlur: (e) => @local.slider_has_focus = false; save @local
            onFocus: (e) => @local.slider_has_focus = true; save @local 

            readable_text: (value) => 
              if value > .03
                "#{(value * 100).toFixed(0)}% #{customization("slider_pole_labels.support", proposal)}"
              else if value < -.03 
                "#{-1 * (value * 100).toFixed(0)}% #{customization("slider_pole_labels.oppose", proposal)}"
              else 
                "Neutral"
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
                save your_opinion
                window.writeToLog 
                  what: 'move slider'
                  details: {proposal: proposal.key, stance: slider.value}
                @local.slid = 1000

                update = fetch('homepage_you_updated_proposal')
                update.dummy = !update.dummy
                save update

                @local.keep_in_view = 
                  offset: prev_offset
                  scroll: prev_scroll

                scroll_handle = => 
                  @local.keep_in_view = null 
                  window.removeEventListener 'scroll', scroll_handle

                window.addEventListener 'scroll', scroll_handle


              mouse_over_element = closest e.target, (node) => 
                node == @getDOMNode()

              if @local.hover_proposal == proposal.key && !mouse_over_element
                @local.hover_proposal = null 
                save @local
      
      # little score feedback
      if show_proposal_scores
        score = 0
        filter_out = fetch 'filtered'
        opinions = (o for o in opinions when !filter_out.users?[o.user])

        for o in opinions 
          score += o.stance
        avg = score / opinions.length
        negative = score < 0
        score *= -1 if negative

        score = pad score.toFixed(1),2

        score_w = widthWhenRendered "#{score}", {fontSize: 18, fontWeight: 600}

        show_tooltip = => 
          if opinions.length > 0
            tooltip = fetch 'tooltip'
            tooltip.coords = $(@refs.score.getDOMNode()).offset()
            tooltip.tip = "#{opinions.length} opinions. Average of #{Math.round(avg * 100) / 100} on a -1 to 1 scale."
            save tooltip
        hide_tooltip = => 
          tooltip = fetch 'tooltip'
          tooltip.coords = null
          save tooltip

        DIV 
          'aria-hidden': true
          ref: 'score'
          style: 
            position: 'absolute'
            right: -50 - score_w
            top: 10

          onFocus: show_tooltip
          onMouseEnter: show_tooltip
          onBlur: hide_tooltip
          onMouseLeave: hide_tooltip

          SPAN 
            style: 
              color: '#999'
              fontSize: 18
              fontWeight: 600
              cursor: 'default'

            if negative
              '–'
            score

  componentDidUpdate: -> 
    if @local.keep_in_view
      prev_scroll = @local.keep_in_view.scroll
      prev_offset = @local.keep_in_view.offset

      target = prev_scroll + @getDOMNode().offsetTop - prev_offset
      if window.scrollTo && window.scrollY != target
        window.scrollTo(0, target)
        @local.keep_in_view = null

    if @local.slid && !@fading 
      @fading = true

      update_bg = => 
        if @local.slid <= 0
          @getDOMNode().style.backgroundColor = ''
          clearInterval int
          @fading = false
        else 
          @getDOMNode().style.backgroundColor = "rgba(253, 254, 216, #{@local.slid / 1000})"

      int = setInterval =>
        @local.slid -= 50
        update_bg() 
      , 50

      update_bg()
