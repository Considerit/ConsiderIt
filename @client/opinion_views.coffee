require './shared'
require './customizations'



save 
  key: 'opinion_views'
  active_views: {}




window.compose_opinion_views = (opinions, proposal, opinion_views) -> 
  opinion_views ?= fetch('opinion_views')
  opinion_views.active_views ?= {}
  active_views = opinion_views.active_views

  if !opinions
    opinions = opinionsForProposal(proposal)

  weights = {}
  salience = {}
  groups = {}

  for o in opinions
    weight = 1
    min_salience = 1
    has_groups = false
    for view_name, view of active_views
      has_groups ||= view.get_group?

    if has_groups
      u_groups = []

    u = o.user.key or o.user

    for view_name, view of active_views
      if view.get_salience?
        s = view.get_salience(u, o, proposal)
        if s < min_salience
          min_salience = s
      if view.get_weight?
        weight *= view.get_weight(u, o, proposal)
      if has_groups && view.get_group?
        ggg = view.get_group(u, o, proposal)
        if Array.isArray(ggg)
          u_groups = u_groups.concat ggg
        else 
          u_groups.push ggg
    weights[u] = weight
    salience[u] = min_salience
    if has_groups      
      groups[u] = u_groups

  {weights, salience, groups}
  

window.get_opinions_for_proposal = (opinions, proposal, weights) ->
  if !opinions
    opinions = opinionsForProposal proposal
  if !weights
    {weights, salience, groups} = compose_opinion_views(opinions, proposal)

  (o for o in opinions when weights[o.user] > 0)


window.get_user_groups_from_views = (groups) ->
  has_groups = Object.keys(groups).length > 0
  if has_groups
    group_set = new Set()
    for u, u_groups of groups
      for g in u_groups 
        group_set.add g
    Array.from group_set
  else 
    null 

group_colors = {}
window.get_color_for_groups = (group_array) ->
  num_groups = group_array.length
  hues = getNiceRandomHues num_groups
  colors = group_colors
  for hue,idx in hues 
    if group_array[idx] not of group_colors
      group_colors[group_array[idx]] = hsv2rgb hue, Math.random() / 2 + .5, Math.random() / 2 + .5
  group_colors






default_filters = 
  everyone: 
    key: 'everyone'
    name: 'everyone'
    pass: (u) -> true 

  just_you: 
    key: 'just_you'
    name: 'Just you'
    pass: (u) -> 
      user = fetch(u)
      user.key == fetch('/current_user').user



default_weights = 
  weighed_by_recency: 
    key: 'weighed_by_recency'
    name: 'Recent'
    label: 'Give greater weight to newer opinions.'
    weight: (u, opinion, proposal) ->
      if !proposal.time_created 
        proposals = fetch '/proposals'
        earliest = null
        for p in proposals.proposals 
          t = new Date(proposal.created_at).getTime()
          if !earliest || earliest > t
            earliest = t 
          proposal.time_created = earliest

      latest = Date.now()
      # if !proposal.latest_opinion 
      #   opinions = opinionsForProposal proposal
      #   latest = null
      #   for o in opinions
      #     if !latest || o.updated_at > latest.updated_at
      #       latest = o
      #   proposal.latest_opinion = new Date(latest.updated_at).getTime()

      # latest = proposal.latest_opinion
      earliest = proposal.time_created
      ot = new Date(opinion.updated_at).getTime()

      .1 + .9 * (ot - earliest) / (latest - earliest)

  weighed_by_substantiated: 
    key: 'weighed_by_substantiated'
    name: 'Substantiated'
    label: 'Add weight to opinions that justify their stance with pro and/or con reasons.'
    weight: (u, opinion, proposal) ->
      point_inclusions = Math.min(8,opinion.point_inclusions?.length or 0) 
      .1 + point_inclusions

  weighed_by_deliberative: 
    key: 'weighed_by_deliberative'
    name: 'Deliberative'
    label: 'Add weight to opinions that acknowledge both pro and con tradeoffs.'
    weight: (u, opinion, proposal) ->
      point_inclusions = opinion.point_inclusions
      has_pro = false 
      has_con = false  
      for inc in point_inclusions or []
        pnt = fetch(inc)
        has_pro ||= pnt.is_pro
        has_con ||= !pnt.is_pro
      if has_con && has_pro
        2
      else 
        .1


toggle_group = (view, replace_existing) ->
  _activate_opinion_view(view, 'group', replace_existing)

toggle_weight = (view, replace_existing) -> 
  _activate_opinion_view(view, 'weight', replace_existing)

toggle_opinion_filter = (view, replace_existing) -> 
  _activate_opinion_view(view, 'filter', replace_existing)


_activate_opinion_view = (view, view_type, replace_existing) ->  
  opinion_views = fetch('opinion_views')
  opinion_views.active_views ?= {}
  active_views = opinion_views.active_views

  view_name = view.key or view.label

  if view_name of active_views && !replace_existing
    delete active_views[view_name] #activating an active view toggles it off
  else 
    if view_type == 'filter'
      if view_name == default_filters.just_you.key
        to_delete = []
        for k,v of active_views
          if v.view_type == view_type
            to_delete.push k 
        for k in to_delete
          delete active_views[k]
      else if active_views[default_filters.just_you.key]
        delete active_views[default_filters.just_you.key]

    active_views[view_name] = 
      key: view.key
      name: view.name 
      view_type: view_type
      get_salience: (u, opinion, proposal) ->
        if view.salience?
          view.salience u, opinion, proposal
        else if !view.pass? || view.pass(u, opinion, proposal)
          1
        else if opinion_views.enable_comparison 
          .1
        else 
          0
      get_weight: (u, opinion, proposal) ->
        if view.weight?
          view.weight(u, opinion, proposal)
        else if opinion_views.enable_comparison || (!view.pass? || view.pass?(u, opinion, proposal))
          1
        else 
          0

      get_group: if view.group? then (u, opinion, proposal) -> 
        view.group(u, opinion, proposal) or 'Unknown'


  invalidate_proposal_sorts()
  save opinion_views




FilterOpinionsIcon = (opts) ->
  if opts.height && !opts.width 
    opts.width = opts.height * 72 / 61

  SVG 
    dangerouslySetInnerHTML: __html: '<g id="filter2" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><circle id="Oval" fill="#FFFFFF" cx="12" cy="16" r="9"></circle><circle id="Oval" fill="#FFFFFF" cx="35" cy="16" r="9"></circle><circle id="Oval" fill="#FFFFFF" cx="35" cy="47" r="9"></circle><circle id="Oval" fill="#FFFFFF" cx="59" cy="16" r="9"></circle><line x1="6.5" y1="31.5" x2="67.5" y2="32.5" id="Line" stroke="#FFFFFF" stroke-width="3" stroke-linecap="square" stroke-dasharray="0,5"></line></g>'
    height: opts.height or 61
    width: opts.width or 72
    viewBox: "0 0 72 61" 

WeighOpinionsIcon = (opts) ->
  if opts.height && !opts.width 
    opts.width = opts.height * 72 / 61

  SVG 
    dangerouslySetInnerHTML: __html: '<g id="weigh" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><circle id="Oval" fill="#FFFFFF" cx="10" cy="40" r="7"></circle><circle id="Oval" fill="#FFFFFF" cx="61" cy="38" r="10"></circle><circle id="Oval" fill="#FFFFFF" cx="34" cy="29" r="18"></circle><line x1="1.5" y1="48.5" x2="70.5" y2="48.5" id="Line" stroke="#FFFFFF" stroke-width="2" stroke-linecap="square"></line></g>'
    height: opts.height or 61
    width: opts.width or 72
    viewBox: "0 0 72 61" 





OpinionViews = ReactiveComponent
  displayName: 'OpinionViews'

  render : -> 

    DIV 
      style: (@props.style or {})
      className: 'filter_opinions_to'

      DIV 
        style: 
          marginTop: 0
          lineHeight: 1

        if customization('verification-by-pic') 
          VerificationProcessExplanation()

        DIV 
          style: 
            display: 'flex'
            justifyContent: 'space-between'

          OpinionFilters
            containerWidth: @props.style?.width or 400

          OpinionWeights
            containerWidth: @props.style?.width or 400


OpinionFilters = ReactiveComponent
  displayName: 'OpinionFilters'
  render: -> 
    custom_filters = customization 'opinion_views'
    user_tags = customization 'user_tags'

    opinion_views = fetch 'opinion_views'
    opinion_view_ui = fetch 'opinion_views_ui'

    is_admin = fetch('/current_user').is_admin
    show_others = !customization('hide_opinions') || is_admin


    # Attributes are additional filters that can distinguish amongst all 
    # participants. We take them from legacy opinion views, and from 
    # qualifying user_tags
    attributes = [] 
    if show_others
      if custom_filters
        for filter in custom_filters
          if filter.visibility == 'open' || is_admin
            if filter.pass
              attributes.push _.extend {}, filter, 
                name: filter.label
                options: [true, false]
      if user_tags
        for name, tag of user_tags 

          if (tag.visibility == 'open' || is_admin) && \
             (tag.self_report?.input in ['dropdown', 'boolean', 'checklist']) && \
             !tag.no_opinion_view # set in the user_tags customization to prevent an opinion view from automatically getting created

            attributes.push 
              key: name
              name: tag.name or tag.self_report?.question or name
              pass: do(name) -> (u, value) -> u.tags[name] == value
              options: tag.self_report.options or (if tag.self_report.input == 'boolean' then [true, false])
              input_type: tag.self_report?.input


    active_filters = {}
    for k,v of opinion_views.active_views
      if v.view_type == 'filter'
        active_filters[k] = v 

    if !opinion_view_ui.initialized      
      initial_filter = null 

      if !show_others
        toggle_opinion_filter default_filters.just_you
      # else if dfault = customization('opinion_filters_default')
      #   for filter in filters 
      #     if filter.label == dfault 
      #       toggle_opinion_filter filter 
      #       break 
      opinion_view_ui.initialized = true 
      save opinion_view_ui


    update_view_for_attribute = (attribute) ->
      if attribute.key 
        attribute = attribute.key

      # having no selections for an attribute paradoxically means that all values are valid.
      has_one_enabled = false 
      for val,enabled of opinion_view_ui.selected_vals_for_attribute[attribute]
        has_one_enabled ||= enabled
      if !has_one_enabled
        opinion_view_ui.selected_vals_for_attribute[attribute] = {}

      view = 
        key: attribute
        pass: (u) -> 
          user = fetch(u)
          val_for_user = user.tags[attribute]
          is_array = Array.isArray(val_for_user)

          passing_vals = (val for val,enabled of opinion_view_ui.selected_vals_for_attribute[attribute] when enabled)

          passes = false
          for passing_val in passing_vals
            if passing_val == 'true'
              passing_val = true 
            else if passing_val == 'false'
              passing_val = false
            passes ||= val_for_user == passing_val || (is_array && passing_val in val_for_user)

          passes 

      toggle_opinion_filter view, has_one_enabled

    toggle_comparison = (e) ->
      enabled = e.target.checked

      if enabled == null # toggle if argument not passed 
        opinion_views.enable_comparison = !opinion_views.enable_comparison
      else 
        opinion_views.enable_comparison = enabled
      save opinion_views 

    DIV 
      style: {}

      DropOverlay 
        open_area_on: 'activation'
        render_anchor: (menu_showing) =>
          if !menu_showing
            [
              FilterOpinionsIcon
                height: 30

              SPAN 
                style: 
                  paddingLeft: 8
                'filter opinions'
            ]
          else 
            SPAN 
              style: 
                paddingLeft: 8          
              'close opinion filters'

        # anchor_style: 
        #   float: 'right'
        anchor_open_style: 
          backgroundColor: focus_color() 
        anchor_class_name: 'filter-weight-sort-button'
        drop_area_style:
          top: 52
          width: @props.containerWidth + 50
          left: -25
        dummy: opinion_view_ui # for helping the child component of DropOverlay rerender properly
                               # on state change
        dummy2: opinion_views

        DIV null,
          DIV 
            style: 
              position: 'absolute'
              left: 60
              top: -17
            dangerouslySetInnerHTML: __html: """<svg width="25px" height="13px" viewBox="0 0 25 13" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g id="Page-2" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g id="Artboard" transform="translate(-1086.000000, -586.000000)" fill="#FFFFFF" stroke="#979797"><polyline id="Path" points="1087 599 1098.5 586 1110 599"></polyline></g></g></svg>"""

          UL 
            style: 
              listStyle: 'none'

            for option in [{name: 'Show only your opinions', label: 'Focus on expressing your own opinion.', filter: default_filters.just_you},
                           {name: 'Show other people’s opinions too', label: 'Learn what others think.', filter: default_filters.everyone} ]
              
              do (option) =>
                show_all_not_available = option.filter == default_filters.everyone && !show_others
                LI 
                  style: 
                    padding: '8px 0'

                  if show_all_not_available
                    "This forum is currently configured to hide other people's opinions"
                  
                  LABEL 
                    className: 'opinion_view_label'

                    style: 
                      pointerEvents: if show_all_not_available then 'none'
                      opacity: if show_all_not_available then .4

                    INPUT 
                      type: 'radio'
                      checked: (option.filter.key == 'everyone' && default_filters.just_you.key not of active_filters) || option.filter.key of active_filters
                      className: 'bigger opinion_view_checker'
                      onChange: ->
                        if !(option.filter.key == 'everyone' && default_filters.just_you.key not of active_filters)
                          toggle_opinion_filter option.filter



                    SPAN 
                      className: 'opinion_view_label_block'

                      DIV 
                        className: 'opinion_view_name'
                        option.name
                      DIV 
                        className: 'opinion_view_explanation'
                        option.label

                  if option.filter.key == 'everyone'

                    DIV 
                      style: 
                        pointerEvents: if opinion_views.active_views[default_filters.just_you.key] then 'none'
                        opacity: if opinion_views.active_views[default_filters.just_you.key] then .4

                      if attributes.length > 0
                        if !opinion_view_ui.visible_attributes? 
                          opinion_view_ui.visible_attributes = {}
                          # opinion_view_ui.visible_attributes[attributes[0].key] = true 
                        if !opinion_view_ui.selected_vals_for_attribute?
                          opinion_view_ui.selected_vals_for_attribute = {}

                        for attribute, cnt in attributes
                          opinion_view_ui.selected_vals_for_attribute[attribute.key] ?= {}

                          do (attribute) => 
                            toggle_attribute_visible = ->
                              opinion_view_ui.visible_attributes[attribute.key] = !opinion_view_ui.visible_attributes[attribute.key]
                              save opinion_view_ui

                            DIV 
                              className: 'attribute_group'

                              BUTTON
                                className: 'attribute_expander' 
                                  
                                onClick: toggle_attribute_visible
                                onKeyDown: (e) => 
                                  if e.which == 13 || e.which == 32 # ENTER or SPACE
                                    toggle_attribute_visible()
                                    e.preventDefault()
                                SPAN 
                                  className: 'attribute_caret' 
                                  dangerouslySetInnerHTML: __html: if opinion_view_ui.visible_attributes[attribute.key] then '&#9660;' else '&#9654;'

                                "Narrow by #{attribute.name}"


                              if opinion_view_ui.visible_attributes[attribute.key]

                                DIV 
                                  style: {}

                                  for val in attribute.options
                                    do (val) => 

                                      LABEL 
                                        className: 'attribute_value_selector' 
                                          
                                        INPUT 
                                          type: 'checkbox'
                                          # className: 'bigger'
                                          value: val
                                          checked: !!opinion_view_ui.selected_vals_for_attribute[attribute.key][val]
                                          onChange: (e) ->
                                            # create a view on the fly for this attribute
                                            opinion_view_ui.selected_vals_for_attribute[attribute.key][val] = e.target.checked
                                            save opinion_view_ui
                                            update_view_for_attribute(attribute)

                                        SPAN 
                                          className: 'attribute_value_value'
                                          "#{val}"

                      if attributes.length > 0 
                        DIV 
                          style: 
                            margin: "18px 0 0 32px"

                          LABEL null, 
                            DIV 
                              className: 'opinion_view_name'

                              "Group opinions by: "  

                            SELECT 
                              style: 
                                maxWidth: '100%'
                              onChange: (ev) -> 
                                opinion_view_ui.group_by = ev.target.value
                                save opinion_view_ui

                                if opinion_view_ui.group_by

                                  view = 
                                    key: 'group_by'
                                    name: "Group by #{opinion_view_ui.group_by}"
                                    group: (u, opinion, proposal) -> 
                                      group_val = fetch(u).tags[opinion_view_ui.group_by] or 'Unknown'
                                      if attribute.input_type == 'checklist'
                                        group_val.split(',')
                                      else 
                                        group_val
                                  toggle_group view, true
                                else 
                                  delete opinion_views.active_views.group_by
                                  save opinion_views


                              value: opinion_view_ui.group_by

                              OPTION 
                                value: null
                                ""
                              for attribute in attributes 
                                do (attribute) =>
                                  OPTION 
                                    value: attribute.key 
                                    attribute.name or attribute.question

                            DIV 
                              className: 'opinion_view_explanation'
                              "Opinions in the histogram are colorized based on the selected attributed."
          
          DIV 
            style: 
              marginTop: 24

            LABEL 
              className: 'opinion_view_label'
              style: 
                cursor: 'pointer'

              INPUT 
                type: 'checkbox'
                className: 'bigger opinion_view_checker'
                checked: opinion_views.enable_comparison
                onChange: toggle_comparison 

              SPAN 
                className: 'opinion_view_label_block'

                DIV 
                  className: 'opinion_view_name'
                  # style: 
                  #   paddingLeft: 12
                  TRANSLATE 'engage.compare_all', "Compare to everyone"

                DIV 
                  className: 'opinion_view_explanation'
                  "Filtered out opinions are shown as translucent rather than hidden."


      DIV null, 
        UL 
          style: 
            listStyle: 'none'
            paddingTop: 4

          if default_filters.just_you.key of active_filters
            draw_filter_cancel default_filters.just_you, -> toggle_opinion_filter default_filters.just_you

          for attribute, vals of (opinion_view_ui.selected_vals_for_attribute or {})
            for val, enabled of vals 
              do (attribute, val) ->
                if enabled 
                  draw_filter_cancel {name: "#{attribute}: #{val}"}, (v) -> 
                    opinion_view_ui.selected_vals_for_attribute[attribute][val] = false
                    save opinion_view_ui
                    update_view_for_attribute attribute


draw_filter_cancel = (v, cb) -> 
  LI 
    style: 
      textAlign: 'right'

    SPAN 
      style: 
        fontSize: 14
        fontWeight: 600
        fontFamily: 'Fira Sans Condensed'
        paddingRight: 4
      v.name

    BUTTON 
      style:
        border: 'none'
        backgroundColor: 'transparent'
        color: '#727272'
        padding: "0 4px"
      onClick: -> cb v 
      onKeyDown: (e) => 
        if e.which == 13 || e.which == 32 # ENTER or SPACE
          cb v 
      'x'


OpinionWeights = ReactiveComponent
  displayName: 'OpinionWeights'
  render: ->
    opinion_views = fetch 'opinion_views'

    activated_weights = {}
    for k,v of opinion_views.active_views
      if v.view_type == 'weight'
        activated_weights[k] = v 

    DIV 
      style: {}

      DropOverlay 
        open_area_on: 'activation'
        render_anchor: (menu_showing) =>
          if !menu_showing
            [
              WeighOpinionsIcon
                height: 30

              SPAN 
                style: 
                  paddingLeft: 8
                'weigh opinions'
            ]
          else 
            SPAN 
              style: 
                paddingLeft: 8          
              'close opinion weights'

        # anchor_style: 
        #   float: 'right'
        anchor_open_style: 
          backgroundColor: focus_color() 
        anchor_class_name: 'filter-weight-sort-button'
        drop_area_style:
          top: 52
          width: @props.containerWidth + 50
          right: -25

        DIV null,
          DIV 
            style: 
              position: 'absolute'
              right: 60
              top: -17
            dangerouslySetInnerHTML: __html: """<svg width="25px" height="13px" viewBox="0 0 25 13" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g id="Page-2" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g id="Artboard" transform="translate(-1086.000000, -586.000000)" fill="#FFFFFF" stroke="#979797"><polyline id="Path" points="1087 599 1098.5 586 1110 599"></polyline></g></g></svg>"""


          UL 
            style: 
              listStyle: 'none'

            for k,v of default_weights
              LI 
                style: 
                  padding: '8px 0'
                
                LABEL 
                  className: 'opinion_view_label'

                  INPUT 
                    type: 'checkbox'
                    checked: k of activated_weights
                    className: 'bigger opinion_view_checker'
                    onChange: do (k,v) -> ->
                      toggle_weight v

                  SPAN 
                    className: 'opinion_view_label_block'

                    DIV 
                      className: 'opinion_view_name'
                      v.name
                    DIV 
                      className: 'opinion_view_explanation'
                      v.label

      DIV null, 
        UL 
          style: 
            listStyle: 'none'
            paddingTop: 4

          for k,v of activated_weights
            do (k,v) ->
              draw_filter_cancel v, (v) -> toggle_weight(v)


VerificationProcessExplanation = ReactiveComponent
  displayName: 'VerificationProcessExplanation'
  render: -> 
    users = fetch '/users'
    callout = "about verification"
    DIV 
      style: 
        position: 'absolute'
        right: -sizeWhenRendered(callout, {fontSize: 12}).width
        top: -14

      SPAN 
        style: 
          color: "#aaa"
          fontSize: 14

        SPAN 
          style: 
            textDecoration: 'underline'
            cursor: 'pointer'
            color: if @local.describe_process then logo_red
          onClick: => 
            @local.describe_process = !@local.describe_process
            save @local
          callout

      if @local.describe_process
        para = 
          marginBottom: 20

        DIV 
          style: 
            textAlign: 'left'
            position: 'absolute'
            right: 0
            top: 40
            width: 650
            zIndex: 999
            padding: "20px 40px"
            backgroundColor: '#eee'
            #boxShadow: '0 1px 2px rgba(0,0,0,.3)'
            fontSize: 18

          SPAN 
            style: cssTriangle 'top', '#eee', 16, 8,
              position: 'absolute'
              right: 50
              top: -8


          DIV style: para,

            """Filters help us understand the opinions of the stakeholder groups. \
               Filters are conjunctive: only users that pass all active filters are shown.
               These are the filters:"""

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Users'
            """. Verified users have emailed us a verification image to validate their account.  
               We have also verified a few other people via other media channels, like Reddit. """
            SPAN style: fontStyle: 'italic', 
              "Verification results shown below."

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Miners'

            ". Miners are "
            OL 
              style: 
                marginLeft: 20 
              LI null,
                'Users who control a mining pool with > 1% amount of hashrate'
              LI null,
                'Users who control > 1% amount of hashrate'
            'We verify hashrate by consulting '
            A 
              href: 'https://blockchain.info/pools'
              target: '_blank'
              style: 
                textDecoration: 'underline'

              'https://blockchain.info/pools'
            '.'

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Developers'

            """. Bitcoin developers self-report by editing their user profile. If we recognize 
               someone as a committer or maintainer of Core or XT, we assign it. 
               We aren’t satisfied by our criteria for developer. We hope to work with 
               the community to define a more robust standard for 'reputable technical voice'.""" 

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Businesses'

            """. Bitcoin businesses self-report by editing their user profile. Business accounts
               are either users who operate the business or an account that will represent that 
               businesses' official position.""" 

          DIV style: para,
            "These filters aren’t perfect. If you think there is a problem, email us at "
            A
              href: "mailto:admin@consider.it"
              style: 
                textDecoration: 'underline'
              'admin@consider.it'

            ". We will try to make a more trustless process in the future."

          DIV 
            style: {}

            DIV 
              style: 
                fontWeight: 600
                fontSize: 26

              'Verification status'

            for user in users.users 
              user = fetch user 
              if user.tags.verified && user.tags.verified.toLowerCase() not in ['no', 'false']
                DIV 
                  style:
                    marginTop: 20

                  DIV 
                    style: 
                      fontWeight: 600

                    user.name


                  if user.tags.verified?.indexOf('http') == 0
                    IMG 
                      src: user.tags.verified
                      style: 
                        width: 400
                  else 
                    DIV 
                      style: 
                        fontStyle: 'italic'

                      user.tags.verified



styles += """
  button.filter-weight-sort-button {
    background-color: #666;
    color: white;
    vertical-align: middle;
    border: 1px solid #464646;
    box-shadow: 0px 1px 2px rgba(0,0,0,.5);
    border-radius: 8px;
    display: flex;
    align-items: center;
    height: 34px;
    font-family: 'Fira Sans Condensed';
    text-transform: uppercase;
    font-size: 14px;
    font-weight: 600;

  }

  label.opinion_view_label {
    display: flex;
  }
  .opinion_view_label input.opinion_view_checker {
    position: relative;
    top: 3px;
  }
  .opinion_view_label .opinion_view_label_block {
    width: 90%;
    padding-left: 12px;
    display: inline-block;
    cursor: pointer;
  }
  .opinion_view_name {
    font-family: 'Fira Sans Condensed';
    font-weight: bold;
    font-size: 18px;
  } 
  .opinion_view_explanation {
    color: #444444;
    font-size: 14px;
  }

  .attribute_group {
    margin-top: 12px;
    margin-left: 53px;
    position: relative;  
  }
  .attribute_group button.attribute_expander {
    border: none;
    background-color: transparent;
    color: black;
    font-weight: 400;
    font-family: 'Fira Sans Condensed';
    padding: 4px 0;
    position: relative;
    text-align: left;
  }
  .attribute_expander .attribute_caret {
    position: absolute;
    left: -20px;
    top: 7px;
    font-size: 12px;  
  }

  .attribute_value_selector {
    display: block; 
    cursor: pointer;
  }
  .attribute_value_selector input {
    position: relative;
    top: 2px;
  }
  .attribute_value_selector .attribute_value_value {
    padding-left: 16px;
    font-size: 14px;
    font-weight: 400;
    font-family: 'Fira Sans Condensed';
  }

"""

# window.opinion_trickle = -> 
#   filter_out = fetch 'filtered'
  
#   proposals = fetch '/proposals'

#   users = {}
#   for prop in proposals.proposals
#     for o in prop.opinions
#       users[o.user] = o.created_at or o.updated_at

#   users = ([k,v] for k,v of users)
#   users.sort (a,b) -> 
#     i = new Date(a[1])
#     j = new Date(b[1])
#     i.getTime() - j.getTime()

#   users = (u[0] for u in users)
#   cnt = users.length

#   steps = 1
#   tick = (interval) => 
#     if cnt >= 0
#       setTimeout => 
#         filter_out.users = {}
#         for user, idx in users
#           filter_out.users[user] = 1
#           break if idx > cnt 

#         cnt--
#         #cnt -= Math.ceil(steps / 2)
#         #tick(interval * .9)
#         tick(interval * .9)
#         steps++
#         dirty = true
#         setTimeout -> 
#           if dirty
#             save filter_out
#             dirty = false
#         , 2000
#       , interval

#   tick 1000


window.OpinionViews = OpinionViews
