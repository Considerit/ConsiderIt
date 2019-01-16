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

    col_sizes = column_sizes
                  width: @props.width

    # we want to update if the sort order changes so that we can 
    # resolve @local.keep_in_view
    fetch("cluster-#{slugify(proposal.cluster or 'Proposals')}/sort_order")

    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    your_opinion = fetch proposal.your_opinion
    if your_opinion?.published
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    draw_slider = can_opine > 0 || your_opinion?.published

    icons = customization('show_proposer_icon', proposal)
    slider_regions = customization('slider_regions', proposal)
    show_proposal_scores = !@props.hide_scores && customization('show_proposal_scores', proposal)

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

    can_edit = permit('update proposal', proposal) > 0


    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{customization("slider_pole_labels.support", proposal)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{customization("slider_pole_labels.oppose", proposal)}"
      else 
        "Neutral"
    LI
      key: proposal.key
      id: 'p' + proposal.slug.replace('-', '_')  # Initial 'p' is because all ids must begin 
                                           # with letter. seeking to hash was failing 
                                           # on proposals whose name began with number.
      style:
        minHeight: 64
        position: 'relative'
        margin: "0 0 #{if can_edit then '0' else '15px'} 0"
        padding: 0
        listStyle: 'none'

      onMouseEnter: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onMouseLeave: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local
      onFocus: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onBlur: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local

      DIV 
        style: 
          width: col_sizes.first 
          display: 'inline-block'
          verticalAlign: 'top'
          position: 'relative'

        DIV 
          style: 
            position: 'absolute'
            left: if icons then -40 - 18
            top: if icons then 4


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
                    height: 40
                    width: 40
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
          else 
            SVG 
              style: 
                position: 'relative'
                left: -22
                top: 3
              width: 8
              viewBox: '0 0 200 200' 
              CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'



        # Name of Proposal
        DIV
          style:
            display: 'inline-block'
            fontWeight: 400
            paddingBottom: if !can_edit then 20 else 4
            width: col_sizes.first

          A
            className: 'proposal proposal_homepage_name'
            style: 
              fontWeight: 600
              textDecoration: 'underline'
              #borderBottom: "1px solid #444"  
              color: '#000'            
              fontSize: 20
              
            href: proposal_url(proposal)

            proposal.name

          DIV 
            style: 
              fontSize: 12
              color: 'black' #'#999'
              marginTop: 4
              #fontStyle: 'italic'

            if customization('proposal_meta_data')
              customization('proposal_meta_data')(proposal)

            else if customization('show_proposal_meta_data')
              SPAN 
                style: 
                  paddingRight: 16

                prettyDate(proposal.created_at)


                SPAN 
                  style: 
                    padding: '0 8px'
                  '|'

                if !icons && (editor = proposal_editor(proposal)) && editor == proposal.user
                  [ 
                    SPAN 
                      style: {}

                      " by #{fetch(editor)?.name}"

                    SPAN 
                      style: 
                        padding: '0 8px'
                      '|'
                  ]



                if customization('discussion_enabled',proposal)
                  A 
                    href: proposal_url(proposal)
                    style: 
                      #fontWeight: 500
                      cursor: 'pointer'

                    if proposal.point_count == 1
                      "#{proposal.point_count} #{customization('point_labels.pro', proposal)} or #{customization('point_labels.con', proposal)}"
                    else 

                      "#{proposal.point_count} #{customization('point_labels.pros', proposal)} and #{customization('point_labels.cons', proposal)}"

            if !proposal.active
              SPAN 
                style: 
                  paddingRight: 16

                t('closed')

            if @props.show_category && proposal.cluster
              cluster = proposal.cluster 
              if fetch('/subdomain').name == 'dao' && proposal.cluster == 'Proposals'
                cluster = 'Ideas'

              SPAN 
                style: 
                  #border: "1px solid #{@props.category_color}"
                  #backgroundColor: @props.category_color
                  padding: '1px 2px'
                  #color: 'white' #@props.category_color
                  fontStyle: 'italic'
                  #fontSize: 12

                cluster

          if can_edit
            DIV
              style: 
                visibility: if !@local.hover_proposal then 'hidden'
                position: 'relative'
                top: -2

              A 
                href: "#{proposal.key}/edit"
                style:
                  marginRight: 10
                  color: focus_color()
                  backgroundColor: 'transparent'
                  padding: 0
                  fontSize: 12
                t('edit')

              if permit('delete proposal', proposal) > 0
                BUTTON
                  style:
                    marginRight: 10
                    color: focus_color()
                    backgroundColor: 'transparent'
                    border: 'none'
                    padding: 0
                    fontSize: 12

                  onClick: => 
                    if confirm('Delete this proposal forever?')
                      destroy(proposal.key)
                      loadPage('/')
                  t('delete')




      # Histogram for Proposal
      DIV 
        style: 
          display: 'inline-block' 
          position: 'relative'
          top: 4
          verticalAlign: 'top'
          width: col_sizes.second
          marginLeft: col_sizes.gutter
                

        Histogram
          key: "histogram-#{proposal.slug}"
          proposal: proposal
          opinions: opinions
          width: col_sizes.second
          height: 40
          enable_selection: false
          draw_base: true
          draw_base_labels: !slider_regions

        Slider 
          base_height: 0
          draw_handle: !!draw_slider
          key: "homepage_slider#{proposal.key}"
          width: col_sizes.second
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

        val = "0000 opinion#{if opinions.length != 1 then 's' else ''}"
        score_w = widthWhenRendered(' opinion' + (if opinions.length != 1 then 's' else ''), {fontSize: 12}) + widthWhenRendered("0000", {fontSize: 20})

        show_tooltip = => 
          if opinions.length > 0
            tooltip = fetch 'tooltip'
            tooltip.coords = $(@refs.score.getDOMNode()).offset()
            #tooltip.tip = "Average rating is #{Math.round(avg * 100) / 100} on a -1 to 1 scale."
            tooltip.tip = "Average rating is #{slider_interpretation(avg)}"
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
            right: -18 - score_w
            top: 23 #40 - 12
            textAlign: 'left'

          onFocus: show_tooltip
          onMouseEnter: show_tooltip
          onBlur: hide_tooltip
          onMouseLeave: hide_tooltip

          SPAN 
            style: 
              color: '#999'
              fontSize: 20
              #fontWeight: 600
              cursor: 'default'
              lineHeight: 1
            opinions.length

            SPAN 
              style: 
                color: '#999'
                fontSize: 12
                cursor: 'default'
                verticalAlign: 'baseline'

              ' opinion' + (if opinions.length != 1 then 's' else '')

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
