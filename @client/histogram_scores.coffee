styles += """

  .proposal_scores {
    position: absolute;
  }

  .is_collapsed .proposal_scores {
    left: calc(100% - 80px);
    top: 23px;    
  }

"""



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

    histocache = @local.histocache?[@local.key]?.positions

    width = ITEM_OPINION_WIDTH()
    h = 70
    if !@local.histocache?
      fill_ratio = .6

      delegate_layout_task 
        task: 'layoutAvatars'
        histo: @local.key
        k: @local.key
        r: calculateAvatarRadius width, h, group_opinions, group_weights,
                          fill_ratio: fill_ratio
        w: width
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

        if histocache
          for group in visible_groups
            pos = histocache[group]
            {avg, cnt} = group_scores[group]

            DIV 
              key: group
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
          width: width
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
            key: group
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

