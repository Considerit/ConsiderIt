





styles += """
  .AggregatedHistogram {
    opacity: 1;
  }

  .animating-expansion .AggregatedHistogram {
    opacity: 0;    
  }


"""



window.AggregatedHistogram =  ReactiveComponent
  displayName: 'AggregatedHistogram'

  render: ->
    opinion_views = bus_fetch 'opinion_views'
    return SPAN null if !opinion_views.active_views.group_by

    proposal = bus_fetch @props.proposal 

    {weights, salience, groups} = compose_opinion_views(null, proposal)
    opinions = get_opinions_for_proposal opinions, proposal, weights

    all_groups = get_user_groups_from_views groups
    all_groups ||= []

    has_groups = !!all_groups

    colors = get_color_for_groups all_groups

    legend_color_size = 28

    rating_str = "0000 / 00%"

    group_scores = {}


    group_opinions = []
    group_weights = {}

    opinion_views = bus_fetch('opinion_views')
    is_weighted = false 
    for v,view of opinion_views.active_views
      is_weighted ||= view.view_type == 'weight'


    min_weight = Infinity
    max_weight = 0
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


        if cnt < min_weight
          min_weight = cnt

        if cnt > max_weight
          max_weight = cnt

        group_weights[group] = cnt
        group_opinions.push [group, avg, group_weights[group]]
      else
        group_weights[group] = 0
        group_opinions.push [group, 0, group_weights[group]]


    if min_weight < Infinity && min_weight != max_weight
      for k,v of group_weights
        group_weights[k] = v /  ((max_weight - min_weight) / 2)

      for group,idx in all_groups 
        group_opinions[idx][2] = group_weights[group]


    visible_groups = Object.keys group_scores
    visible_groups.sort (a,b) -> group_scores[b].avg - group_scores[a].avg

    width = @props.width
    h = @props.height

    histokey = "#{width}-#{h}-#{JSON.stringify(group_opinions)}-#{JSON.stringify(group_weights)}"
    histocache = @local.histocache?[histokey]?.positions

    if !histocache
      fill_ratio = .6

      delegate_layout_task 
        task: 'layoutAvatars'
        histo: @local.key
        k: histokey
        r: calculateAvatarRadius width, h, group_opinions, group_weights,
                          fill_ratio: fill_ratio
        w: width
        h: h
        o: group_opinions
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
      boxShadow: "inset 0 -1px 2px 0 var(--shadow_dark_25)"
    separator_inserted = false 


    label_style = 
      fontSize: 12
      fontWeight: 400
      color: "var(--text_gray)"
      bottom: -13

    FLIPPED 
      flipId: "aggregated-histo-#{proposal.key}"
      shouldFlip: @props.shouldFlip
      shouldFlipIgnore: @props.shouldFlipIgnore
      translate: true

      DIV 
        className: 'AggregatedHistogram histoavatars-container'


        DIV null, 

          DIV 
            style: 
              width: width
              height: h
              position: 'relative'

            if !histocache
              DIV 
                style: {position: 'absolute', top: h / 2 - 20, left: width / 2 - 25}
                LOADING_INDICATOR

            if histocache

              for group in visible_groups
                pos = histocache[group]
                continue if !pos
                {avg, cnt} = group_scores[group]

                DIV 
                  key: group
                  "aria-haspopup": 'dialog'
                  "data-popover": proposal.key
                  "data-group": group
                  "data-attribute": opinion_views.active_views.group_by.name
                  "data-stance": "#{Math.round(100 * avg)}% #{if is_weighted then 'weighted' else ''} average"
                  "data-opinion-count": cnt

                  style: _.extend {}, group_avatar_style,
                    width:  pos[2] * 2
                    height: pos[2] * 2
                    transform: "translate(#{pos[0]}px, #{pos[1]}px)"
                    backgroundColor: colors[group]
                    position: 'absolute'
          
        DIV 
          style: 
            position: 'relative'
            top: 6
          

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





window.AggregatedGroupPopover = ReactiveComponent
  displayName: 'AggregatedGroupPopover' 

  render: -> 
    {proposal, attribute, group, attribute, stance, num_opinions} = @props
    proposal = bus_fetch proposal

    opinion_views = bus_fetch 'opinion_views'

    DIV 
      style: 
        padding: '8px 4px'
        position: 'relative'
        maxWidth: "min(80vw, 600px)"

      DIV 
        style: 
          display: 'flex'

        DIV null,
          
          DIV null  
            attribute

          DIV 
            style: 
              fontWeight: 700
              fontSize: 18

            group



          DIV 
            style: 
              marginTop: 8

            "#{num_opinions} opinions  •  #{stance}"

