require './shared'
require './customizations'



save 
  key: 'opinion_views'
  active_views: {}

activate_opinion_view = (view) -> 

  opinion_views = fetch('opinion_views')
  opinion_views.active_views ?= {}
  active_views = opinion_views.active_views

  # TODO: In the future, we'll allow conjunctive views, but 
  #       for now, only allow one at a time
  to_delete = []
  for k,v of active_views
    if v.created_by == 'activate_opinion_view'
      to_delete.push k 
  for k in to_delete
    delete active_views[k]

  view_name = view.key or view.label

  active_views[view_name] = 
    created_by: 'activate_opinion_view'
    get_salience: (u, opinion, proposal) ->
      if view.salience?
        view.salience u, opinion, proposal
      else if !view.pass || view.pass(u, opinion, proposal)
        1
      else if opinion_views.enable_comparison 
        .1
      else 
        0
    get_weight: (u, opinion, proposal) ->
      if view.weight?
        view.weight(u, opinion, proposal)
      else if opinion_views.enable_comparison || view.pass?(u, opinion, proposal)
        1
      else 
        0

  invalidate_proposal_sorts()
  save opinion_views



opinion_view_cache = {}
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
    groups = []
    u = o.user.key or o.user

    for view_name, view of active_views
      if view.get_salience?
        s = view.get_salience(u, o, proposal)
        if s < min_salience
          min_salience = s
      if view.get_weight?
        weight *= view.get_weight(u, o, proposal)
      if view.groups? 
        groups.concat view.groups(u, o, proposal)
    weights[u] = weight
    salience[u] = min_salience
    groups[u] = groups
  {weights, salience, groups}
  

window.get_opinions_for_proposal = (opinions, proposal, weights) ->
  if !opinions
    opinions = opinionsForProposal proposal
  if !weights
    {weights, salience, groups} = compose_opinion_views(opinions, proposal)

  (o for o in opinions when weights[o.user] > 0)



default_views = 
  everyone: 
    key: 'everyone'
    label: 'everyone'
    tooltip: null 
    pass: (u) -> true 

  just_you: 
    key: 'just_you'
    label: 'just you'
    tooltip: null 
    pass: (u) -> 
      user = fetch(u)
      user.key == fetch('/current_user').user

  weighed_by_activity: 
    key: 'weighed_by_activity'
    label: 'weighed by reasons given'
    weight: (u, opinion, proposal) ->
      point_inclusions = opinion.point_inclusions?.length or 0 
      .1 + point_inclusions

  weighed_by_recency: 
    key: 'weighed_by_recency'
    label: 'weighed by recency'
    weight: (u, opinion, proposal) ->
      if !proposal.time_created 
        proposal.time_created = new Date(proposal.created_at).getTime()
      earliest = proposal.time_created

      ot = new Date(opinion.updated_at).getTime()

      time_since_creation = ot - earliest 

      # based on days since creation
      Math.log .1 + time_since_creation / (1000 * 60 * 60 * 24)


OpinionViews = ReactiveComponent
  displayName: 'OpinionViews'

  render : -> 

    custom_filters = customization 'opinion_views'
    opinion_views = fetch 'opinion_views'

    is_admin = fetch('/current_user').is_admin
    
    filters = [default_views.just_you]

    if !customization('hide_opinions') || is_admin
      filters.unshift default_views.everyone
      filters.push default_views.weighed_by_activity
      filters.push default_views.weighed_by_recency


    if custom_filters && !customization('hide_opinions')
      for filter in custom_filters
        if filter.visibility == 'open' || is_admin
          filters.push filter

    if !@local.current_filter
      dfault = customization('opinion_filters_default') or 'everyone'
      initial_filter = null 
      for filter in filters 
        if filter.label == dfault 
          initial_filter = filter 
          break 

      initial_filter ||= filters[0]

      activate_opinion_view initial_filter
      @local.current_filter = initial_filter
      save @local

    current_filter = @local.current_filter

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
            # fontSize: 20
            position: 'relative'

          TRANSLATE "engage.opinion_filter.label", 'show opinion of' 
          
          ": "

          DropMenu
            options: filters

            open_menu_on: 'activation'

            selection_made_callback: (filter) =>
              activate_opinion_view filter
              @local.current_filter = filter
              save @local

            render_anchor: ->
              
              key = if (current_filter?.key or current_filter?.label) not in ['everyone', 'just_you', 'weighed_by_activity', 'weighed_by_recency'] then "/translations/#{fetch('/subdomain').name}" else null
              SPAN 
                style: 
                  fontWeight: 'bold'      
                  position: 'relative'        

                translator 
                  id: "opinion_filter.name.#{current_filter.label}"
                  key: key

                  current_filter.label

                SPAN style: _.extend cssTriangle 'bottom', focus_color(), 8, 5,
                  right: -12
                  bottom: 8
                  position: 'absolute'

            render_option: (filter, is_active) -> 
              [        
                translator 
                  id: "opinion_filter.name.#{filter.label}"
                  key: "/translations/#{fetch('/subdomain').name}"
                  filter.label

                if filter.tooltip
                  DIV 
                    style: 
                      fontSize: 12
                      color: if is_active then 'white' else 'black'

                    filter.tooltip
              ]

            wrapper_style: 
              display: 'inline-block'

            anchor_style: 
              fontWeight: 600
              padding: 0
              display: 'inline-block'
              color: focus_color() #'inherit'
              # textTransform: 'lowercase'
              borderRadius: 16
              textAlign: (@props.style or {}).textAlign

            menu_style: 
              minWidth: 300
              backgroundColor: '#eee'
              border: "1px solid #{focus_color()}"
              left: 'auto'
              right: -9999
              top: 18
              borderRadius: 8
              fontWeight: 400
              overflow: 'hidden'
              boxShadow: '0 1px 2px rgba(0,0,0,.3)'
              textAlign: 'right'

            menu_when_open_style: 
              right: 0

            option_style: 
              padding: '6px 12px'
              borderBottom: "1px solid #ddd"
              display: 'block'

            active_option_style: 
              color: 'white'
              backgroundColor: focus_color()

          if current_filter.key != 'everyone' && (is_admin || !customization('hide_opinions'))
            DIV 
              style: @props.enable_comparison_wrapper_style or {}


              INPUT 
                type: 'checkbox'
                id: 'enable_comparison'
                checked: opinion_views.enable_comparison
                ref: 'enable_comparison'
                onChange: => 
                  enabled = @refs.enable_comparison.getDOMNode().checked

                  if enabled == null # toggle if argument not passed 
                    opinion_views.enable_comparison = !opinion_views.enable_comparison
                  else 
                    opinion_views.enable_comparison = enabled
                  save opinion_views 

              LABEL 
                htmlFor: 'enable_comparison'
                TRANSLATE 'engage.compare_all', "compare to everyone"


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
