require './shared'
require './customizations'
require './histogram'
require './slider'
require './permissions'
require './bubblemouth'
require './popover'

window.EXPAND_IN_PLACE = false # temporary global variable that will be eliminated when proposals expanding in place is finished

styles += """
  [data-widget="CollapsedProposal"] {
    min-height: 84px;
    position: relative;
    padding: 0px;
    list-style: none;    
    display: flex;
    margin: 0;
  }

  .one-col [data-widget="CollapsedProposal"] {
    padding: 14px 0; 
    flex-direction: column;
  }
  .one-col [data-widget="CollapsedProposal"]:nth-child(even) {
    background-color: #f4f7f9;
  }

  a.proposal_homepage_name, button.add_new_proposal {
    font-weight: 700;
    text-decoration: underline;
    color: #000;
    font-size: 17px;
  }

  [data-widget="CollapsedProposal"] .description_on_homepage {
    font-size: 14px;
    color: #444;
    padding-bottom: 10px;  
    text-decoration: none;
    font-weight: 400;
    cursor: pointer;
    overflow-y: hidden;
    padding-top: 3px;
  }



  [data-widget="CollapsedProposal"] .proposal_info {
    display: inline-block;
    position: relative;
    margin-left: -58px;
  }

  [data-widget="CollapsedProposal"] .proposal_histo {
    display: inline-block;
    position: relative;
    top: -26px;
  }

  [data-widget="CollapsedProposal"] .proposal_scores {
    position: absolute;
    left: calc(100%);
    top: 9px;    
  }




  [data-widget="CollapsedProposal"].editable {
    margin-bottom: 15px;
  }

  [data-widget="CollapsedProposal"].editable .proposal_name {
    padding-bottom: 4px;
  }

  [data-widget="CollapsedProposal"] .proposal_name {
    display: inline-block;
    padding-bottom: 20px;
  }

  [data-widget="CollapsedProposal"] .metadata {
    font-size: 12px;
    color: #555;
    margin-top: 6px;
  }


  [data-widget="CollapsedProposal"] .proposal_pic, [data-widget="CollapsedProposal"] [data-widget="Avatar"] {
    height: 40px;
    width: 40px;
    border-radius: 0px;
    background-color: #ddd;
  }

  [data-widget="CollapsedProposal"] .proposal_bullet {
    position: relative;
    left: 13px;
    top: 0px;
  }


  [data-widget="CollapsedProposal"] .metadata .separated {
    padding-right: 4px;
    margin-right: 12px;
    font-weight: 400;
  }

  [data-widget="CollapsedProposal"] .metadata .separated.give-your-opinion {
    text-decoration: none;
    background-color: #f7f7f7;
    border-radius: 8px;
    padding: 4px 10px;
    border: 1px solid #eee;
    box-shadow: 0 1px 1px rgba(160,160,160,.8);
    white-space: nowrap;
  }

"""

proposal_url = (proposal, prefer_crafting_page) ->
  # The special thing about this function is that it only links to
  # "?results=true" if the proposal has an opinion.

  proposal = fetch proposal
  result = "/#{proposal.slug}"
  subdomain = fetch '/subdomain'

  if TWO_COL() || !proposal.active || (!customization('show_crafting_page_first', proposal, subdomain) && !prefer_crafting_page) || !customization('discussion_enabled', proposal, subdomain)
    result += '?results=true'

  return result


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

    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    subdomain = fetch '/subdomain'

    your_opinion = proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion.key 

    if your_opinion.published
      can_opine = permit 'update opinion', proposal, your_opinion, subdomain
    else
      can_opine = permit 'publish opinion', proposal, subdomain

    draw_slider = can_opine > 0 || your_opinion.published

    icons = customization('show_proposer_icon', proposal, subdomain) && !@props.hide_icons && !customization('anonymize_everything')
    slider_regions = customization('slider_regions', proposal, subdomain)
    show_proposal_scores = !@props.hide_scores && customization('show_proposal_scores', proposal, subdomain) && WINDOW_WIDTH() > 955

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

    can_edit = permit('update proposal', proposal, subdomain) > 0

    opinion_views = fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']
    everyone = !!opinion_views.active_views['everyone'] || !!opinion_views.active_views['weighed_by_substantiated'] || !!opinion_views.active_views['weighed_by_recency']

    opinion_publish_permission = permit('publish opinion', proposal, subdomain)

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"


    showing_description = customization('proposal_show_description_on_homepage', null, subdomain)

    is_open = EXPAND_IN_PLACE && fetch('location').url == "/#{proposal.slug}"

    FLIPPED 
      key: proposal.key
      flipId: proposal.key
      LI
        key: proposal.key
        className: "#{if can_edit then 'editable' else ''} #{if is_open then 'is_open' else ''}"
        "data-name": slugify(proposal.name)
        id: 'p' + (proposal.slug or "#{proposal.id}").replace('-', '_')  # Initial 'p' is because all ids must begin 
                                             # with letter. seeking to hash was failing 
                                             # on proposals whose name began with number.


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

        if @local.editing
          EditProposal 
            proposal: proposal.key
            done_callback: (e) =>
              @local.editing = false
              save @local

        if @props.focused_on
          DIV
            style: 
              position: 'absolute'
              left: -66
              top: -8
              backgroundColor: 'white'
              padding: '8px 14px'
              borderRadius: 8
              fontSize: 36
              color: '#666'

            #dangerouslySetInnerHTML: __html: "#{TRANSLATE('engage.navigation_helper_current_location', 'You are here')} &rarr;"
            dangerouslySetInnerHTML: __html: "&rarr;"


        DIV 
          className: 'proposal_info'
          style: 
            width: col_sizes.first 
            marginLeft: 58

          

          # icon or bullet
          DIV 
            style: 
              position: 'absolute'
              left: -58
              top: if icons then 4


            if icons
              editor = proposal_editor(proposal)

              A
                href: proposal_url(proposal)
                "data-no-scroll": EXPAND_IN_PLACE
                'aria-hidden': true
                tabIndex: -1

                if proposal.pic 
                  IMG
                    className: 'proposal_pic'
                    src: proposal.pic 

                else if editor
                  # Person's icon
                  Avatar
                    key: editor
                    user: editor
                    style:
                      height: 40
                      width: 40

                else # no author specified
                  SPAN 
                    className: 'empty_pic'
                    style: 
                      height: 36
                      width: 36
                      display: 'inline-block'
                      border: "2px dashed #ddd"
            else
              @props.icon?() or SVG 
                className: 'proposal_bullet'
                key: 'bullet'
                width: 8
                viewBox: '0 0 200 200' 
                CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'



          # Name of Proposal
          DIV
            className: 'proposal_name'
            style:
              width: col_sizes.first

            A
              "data-no-scroll": EXPAND_IN_PLACE
              className: 'proposal proposal_homepage_name'              
              href: proposal_url(proposal, just_you && current_user.logged_in)

              proposal.name


            if showing_description
              len = customization('proposal_show_description_on_homepage', null, subdomain)
              if len == true || len == 'true'
                len = 700
                
              desc = proposal.description

              max_desc_height = Math.floor 20 * len / 70

              # predict height of rendered description
              div = document.createElement("div")
              div.style.fontSize = "14px"
              div.style.width = "#{col_sizes.first}px"
              div.style.visibility = 'hidden'
              div.innerHTML = proposal.description
              parent = document.getElementById('content')
              parent.appendChild div 
              exceeds_height = max_desc_height < div.clientHeight            
              parent.removeChild div


              DIV 
                style: 
                  position: 'relative' 

                DIV
                  className: 'description_on_homepage'
                  style: 
                    maxHeight: max_desc_height

                  onClick: (e) => 
                    if e.target.tagName not in ["A", "BUTTON"]
                      loadPage proposal_url(proposal, just_you && current_user.logged_in)                
                      window.scrollTo(0, 0)

                  dangerouslySetInnerHTML: __html: desc 

                if exceeds_height
                  DIV 
                    style: 
                      background: 'linear-gradient(0deg, rgba(255,255,255,1) 0%, rgba(255,255,255,1) 34%, rgba(255,255,255,0) 100%)'
                      bottom: 0
                      height: 18
                      width: '100%'
                      position: 'absolute'
                      pointerEvents: 'none'


            DIV 
              className: 'metadata monospaced'

              if customization('proposal_meta_data', null, subdomain)?
                customization('proposal_meta_data', null, subdomain)(proposal)

              else if !@props.hide_metadata && customization('show_proposal_meta_data', null, subdomain)
                show_author_name_in_meta_data = !icons && (editor = proposal_editor(proposal)) && editor == proposal.user && !customization('anonymize_everything')
                show_timestamp = !screencasting() && subdomain.name != 'galacticfederation'
                show_discussion_info = customization('discussion_enabled', proposal, subdomain)
                show_cluster = @props.show_category && proposal.cluster
                is_closed = opinion_publish_permission == Permission.DISABLED
                read_only = opinion_publish_permission == Permission.INSUFFICIENT_PRIVILEGES

                [
                  if show_timestamp
                    SPAN 
                      key: 'date'
                      className: 'separated'

                      # if !show_author_name_in_meta_data
                      #   TRANSLATE 'engage.proposal_metadata_date_added', "Added: "
                      
                      prettyDate(proposal.created_at)


                  if show_author_name_in_meta_data
                    SPAN 
                      key: 'author name'
                      className: 'separated'

                      TRANSLATE
                        id: 'engage.proposal_author'
                        name: fetch(editor)?.name 
                        " by {name}"

                  if show_discussion_info
                    [
                      A 
                        key: 'proposal-link'
                        href: proposal_url(proposal)
                        "data-no-scroll": EXPAND_IN_PLACE
                        className: 'separated'
                        style: 
                          textDecoration: 'none'
                          whiteSpace: 'nowrap'                        
                        TRANSLATE
                          key: 'point-count'
                          id: "engage.point_count"
                          cnt: proposal.point_count

                          "{cnt, plural, one {# pro or con} other {# pros & cons}}"

                      if proposal.active && permit('create point', proposal, subdomain) > 0 && WINDOW_WIDTH() > 955

                        A 
                          key: 'give-opinion'
                          href: proposal_url(proposal)
                          "data-no-scroll": EXPAND_IN_PLACE
                          className: 'separated give-your-opinion'                          
                          TRANSLATE
                            id: "engage.add_your_own"

                            "give your opinion"
                    ]
                ]



              if show_cluster
                SPAN 
                  style: 
                    padding: '1px 2px'
                    color: @props.category_color or 'black'
                    fontWeight: 500

                  get_list_title "list/#{proposal.cluster}", true, subdomain

              if is_closed
                SPAN 
                  style: 
                    padding: '0 16px'
                  TRANSLATE "engage.proposal_closed.short", 'closed'

              else if read_only
                SPAN 
                  style: 
                    padding: '0 16px'
                  TRANSLATE "engage.proposal_read_only.short", 'read-only'

            

            if can_edit
              DIV
                style: 
                  visibility: if !@local.hover_proposal then 'hidden'

                BUTTON 
                  className: 'like_link'              
                  onClick: (e) => 
                    @local.editing = true 
                    save @local
                    e.stopPropagation()
                    e.preventDefault()
                    
                  style:
                    marginRight: 10
                    color: focus_color()
                    padding: 0
                    fontSize: 12
                    fontWeight: 600
                  TRANSLATE 'engage.edit_button', 'edit'

                if permit('delete proposal', proposal, subdomain) > 0
                  BUTTON
                    className: 'like_link'
                    style:
                      marginRight: 10
                      color: focus_color()
                      padding: 0
                      fontSize: 12
                      fontWeight: 600

                    onClick: => 
                      if confirm('Delete this proposal forever?')
                        destroy(proposal.key)
                        loadPage('/')
                    TRANSLATE 'engage.delete_button', 'delete'




        # Histogram for Proposal
        DIV 
          className: 'proposal_histo'      
          style: 
            width: col_sizes.second
            marginLeft: col_sizes.gutter
                  

          Histogram
            histo_key: "histogram-#{proposal.slug}"
            proposal: proposal.key
            opinions: opinions
            width: col_sizes.second
            height: 40
            enable_individual_selection: !@props.disable_selection && !browser.is_mobile
            enable_range_selection: !just_you && !browser.is_mobile && !ONE_COL()
            draw_base: true
            draw_base_labels: !slider_regions

          Slider 
            slider_key: "homepage_slider#{proposal.key}"
            base_height: 0
            draw_handle: !!draw_slider
            width: col_sizes.second
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
      
        # little score feedback
        if show_proposal_scores        
          DIV 
            className: 'proposal_scores'

            HistogramScores
              proposal: proposal.key




window.HistogramScores = ReactiveComponent
  displayName: 'HistogramScores'

  render: ->
    proposal = @props.proposal

    {weights, salience, groups} = compose_opinion_views(null, proposal)
    opinions = get_opinions_for_proposal opinions, proposal, weights


    if opinions.length == 0 || ONE_COL()
      return SPAN null

    all_groups = get_user_groups_from_views groups
    has_groups = !!all_groups

    overall_score = 0
    overall_weight = 0
    overall_cnt = 0
    for o in opinions 
      continue if salience[o.user.key or o.user] < 1
      w = weights[o.user.key or o.user]
      overall_score += o.stance * w
      overall_weight += w
      overall_cnt += 1
    overall_avg = overall_score / overall_weight
    negative = overall_score < 0
    overall_score *= -1 if negative

    score = pad overall_score.toFixed(1),2

    opinion_views = fetch('opinion_views')
    is_weighted = false 
    for v,view of opinion_views.active_views
      is_weighted ||= view.view_type == 'weight'

    DIV 
      'aria-hidden': true
      ref: 'score'
      style: 
        textAlign: 'left'
        whiteSpace: 'nowrap'

      SPAN 
        style: 
          color: '#555'
          cursor: 'default'
          lineHeight: .8
          fontSize: 11

        TRANSLATE
          id: "engage.proposal_score_summary"

          num_opinions: overall_cnt 
          "{num_opinions, plural, =0 {no opinions} one {# opinion} other {# opinions} }"

        if overall_weight > 0  
          DIV 
            style: 
              position: 'relative'
              top: -4

            if is_weighted         
              TRANSLATE
                id: "engage.proposal_score_summary_weighted.explanation"
                percentage: Math.round(overall_avg * 100) 
                "{percentage}% weighted average"

            else 
              TRANSLATE
                id: "engage.proposal_score_summary.explanation"
                percentage: Math.round(overall_avg * 100) 
                "{percentage}% average"

        if has_groups && overall_weight > 0
          BUTTON
            'data-popover': @props.proposal.key or @props.proposal
            'data-proposal-scores': overall_avg
            className: 'like_link'
            style: 
              color: focus_color()
              position: 'relative'
              top: -4
            "breakdown by #{fetch('opinion_views').active_views.group_by.name}"



window.ProposalScoresPopover =  ReactiveComponent
  displayName: 'ProposalScoresPopover'

  render: ->
    proposal = @props.proposal 
    overall_avg = @props.overall_avg

    {weights, salience, groups} = compose_opinion_views(null, proposal)
    opinions = get_opinions_for_proposal opinions, proposal, weights

    all_groups = get_user_groups_from_views groups
    has_groups = !!all_groups


    col_sizes = column_sizes()

    opinion_views = fetch 'opinion_views'

    colors = get_color_for_groups all_groups

    legend_color_size = 28

    rating_str = "0000 / 00%"

    group_scores = {}


    group_opinions = []
    group_weights = {}

    opinion_views = fetch('opinion_views')
    is_weighted = false 
    for v,view of opinion_views.active_views
      is_weighted ||= view.view_type == 'weight'


    for group in all_groups 

      weight = 0
      cnt = 0
      score = 0
      for o in opinions 
        continue if salience[o.user.key or o.user] < 1 or group not in groups[o.user.key or o.user]
        w = weights[o.user.key or o.user]
        score += o.stance * w
        weight += w
        cnt += 1

      if weight > 0 
        avg = score / weight
        group_scores[group] = {avg, cnt}

        group_weights[group] = cnt
        group_opinions.push {stance: avg, user: group}

    visible_groups = Object.keys group_scores
    visible_groups.sort (a,b) -> group_scores[b].avg - group_scores[a].avg

    w = col_sizes.second
    h = 70
    if !@local.histocache?
      fill_ratio = .6

      delegate_layout_task 
        task: 'layoutAvatars'
        histo: @local.key
        k: @local.key
        r: calculateAvatarRadius w, h, group_opinions, group_weights,
                          fill_ratio: fill_ratio
        w: w
        h: h
        o: group_opinions
        weights: group_weights
        layout_params: 
          fill_ratio: fill_ratio
          cleanup_overlap: 2
          jostle: 0
          rando_order: 0
          topple_towers: .05
          density_modified_jostle: 0

    group_avatar_style = 
      borderRadius: '50%'
      width: legend_color_size
      height: legend_color_size
      display: 'inline-block'
      boxShadow: "0 1px 2px 0 rgba(103,103,103,0.50), inset 0 -1px 2px 0 rgba(0,0,0,0.16)"
    separator_inserted = false 

    items = visible_groups.slice()

    if items.length > 1
      separator_idx = 0
      for group,idx in items 
        {avg, cnt} = group_scores[group]
        if idx != 0 && group_scores[items[idx - 1]].avg > overall_avg \
                    && group_scores[items[idx]].avg <= overall_avg 
          separator_idx = idx 
          break 
      items.splice separator_idx, 0, 'avg_separator'

    label_style = 
      fontSize: 12
      fontWeight: 400
      color: '#555'
      bottom: -13

    DIV 
      style: 
        padding: "12px 12px 12px 18px"


      DIV 
        style: 
          width: w
          height: h
          position: 'relative'

        if @local.histocache?.positions

          for group in visible_groups
            pos = @local.histocache.positions[group]
            {avg, cnt} = group_scores[group]
            DIV 
              "data-tooltip": "#{group}: #{cnt} opinions with #{Math.round(100 * avg)}% #{if is_weighted then 'weighted' else ''} avg"
              style: _.extend {}, group_avatar_style,
                width:  pos[2] * 2
                height: pos[2] * 2
                transform: "translate(#{pos[0]}px, #{pos[1]}px)"
                backgroundColor: colors[group]
                position: 'absolute'
      DIV 
        style: 
          position: 'relative'

        Slider 
          base_height: 1
          width: col_sizes.second
          polarized: true
          respond_to_click: false
          base_color: '#999'
          draw_handle: false 
          offset: true
          ticks: 
            increment: .5
            height: 4

        SPAN
          style: _.extend {}, label_style,
            position: 'absolute'
            left: 0
          get_slider_label("slider_pole_labels.oppose", proposal)

        SPAN
          style: _.extend {}, label_style,
            position: 'absolute'
            right: 0

          get_slider_label("slider_pole_labels.support", proposal)

      UL 
        'aria-hidden': true
        style: 
          listStyle: 'none'
          marginTop: 24
          maxWidth: 250
          margin: '24px auto 0px auto'

        for group,idx in items 
          insert_separator = group == 'avg_separator' 

          if insert_separator
            separator_inserted = true 
          else 
            {avg, cnt} = group_scores[group]

          continue if !(cnt > 0)
          diff = avg - overall_avg

          LI 
            style: 
              fontSize: 14
              display: 'flex'
              alignItems: 'center'
              marginBottom: 16

            DIV 
              style: _.extend {}, group_avatar_style, 
                backgroundColor: colors[group]
                visibility: if insert_separator then 'hidden'
                minWidth: legend_color_size
        

            DIV 
              style: 
                paddingLeft: 12

              DIV 
                style: 
                  fontWeight: if insert_separator then 400 else 700
                  letterSpacing: -1
                  textAlign: if insert_separator then 'right'

                if !insert_separator
                  group
                else 
                  "Overall average #{if is_weighted then 'weighted' else ''} opinion:"

              
              if !insert_separator
                DIV 
                  style: 
                    color: '#666'
                    marginTop: -2
                    fontSize: 11


                  "#{Math.round(avg * 100)}% #{if is_weighted then 'weighted ' else ''}avg • "

                  TRANSLATE
                    id: "engage.proposal_score_summary"
                    num_opinions: cnt 
                    "{num_opinions, plural, =0 {no opinions} one {# opinion} other {# opinions} }"

            DIV 
              style: 
                color: if insert_separator then 'black' else if diff < 0 then '#C02626' else '#148918'
                textAlign: 'right'
                flex: 1
                paddingLeft: 16
                fontSize: 12
                fontWeight: 600

              if insert_separator
                "#{Math.round(overall_avg * 100)}%" 
              else 
                "#{if diff > 0 then '+' else ''}#{Math.round(diff * 100)}%"
