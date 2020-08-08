require './shared'
require './customizations'
require './drop_menu'




# get_all_tags = -> 
#   proposals = fetch '/proposals'
#   all_tags = {}
#   for proposal in proposals.proposals 
#     text = "#{proposal.name} #{proposal.description}"

#     if text.indexOf("#") > -1 && tags = text.match(/#(\w+)/g)
#       for tag in tags
#         tag = tag.toLowerCase()

#         all_tags[tag] ||= 0
#         all_tags[tag] += 1

#   # ordered_tags = ({tag: k, count: v} for k,v of all_tags when v > 1)
#   # ordered_tags.sort (a,b) -> b.count - a.count

#   all_tags 


regexes = {}
ApplyFilters = ReactiveComponent
  displayName: 'ApplyFilters'

  render: ->
    filters = fetch 'filters'
    filter_out = fetch 'filtered'
    filter_out.proposals ||= {}

    proposals = fetch '/proposals'

    new_filter_out = {}

    for filter in (filters.for_proposals or [])
      if !regexes[filter]
        regexes[filter] = new RegExp filter, 'i'

    for proposal in proposals.proposals
      editor = proposal_editor(proposal)
      if editor 
        editor = fetch(editor).name 
      else 
        editor = ""
      text = "#{editor} #{proposal.name} #{proposal.description} #{prettyDate(proposal.created_at)}"
      passes = true 
      for filter in (filters.for_proposals or [])
        passes &&= !!text.match regexes[filter]
      if !passes
        new_filter_out[proposal.key] = 1

    if JSON.stringify(new_filter_out) != JSON.stringify filter_out.proposals
      filter_out.proposals = new_filter_out
      save filter_out

    SPAN null



window.invalidate_proposal_sorts = -> 
  sort = fetch 'sort_proposals'
  for k,v of sort.sorts 
    v.force_resort = true 
  save sort 

window.sorted_proposals = (proposals, sort_key, require_force) ->

  sort = fetch 'sort_proposals'
  set_sort() if !sort.name? 

  filters = fetch 'filtered'

  proposals = proposals.slice()


  # filter out filtered proposals
  filter_out = fetch 'filtered'
  if filter_out.proposals
    filtered = []
    for proposal in proposals
      if filter_out.proposals[proposal.key]
        filtered.push proposal
    for proposal in filtered
      proposals.splice proposals.indexOf(proposal), 1

  comp = sort.comp
  proposals = proposals.sort comp

  if require_force
    # when dragging a slider on a list of proposals, we may want to 
    # return the old sort order even if it isn't technically correct.
    # This is because it is too annoying to have the proposals list
    # jumping around all the time.  

    sort.sorts ||= {}

    keys = (p.key for p in (proposals or []))
    order = md5 keys

    cached_order = null
    if sort_key of sort.sorts
      cached_order = md5 sort.sorts[sort_key].cache
    else 
      cached_order = null 
      sort.sorts[sort_key] = {cache: [], stale: true, force_resort: true}

    # alright, same order
    if cached_order == order 
      if sort.sorts[sort_key].force_resort
        sort.sorts[sort_key].force_resort = false 
        sort.sorts[sort_key].stale = false 
        save sort

    # force an update to the sort order, either because its stale, bc we're initializing, or 
    # because a new proposal has been added or removed
    else if sort.sorts[sort_key].force_resort || proposals.length != sort.sorts[sort_key].cache.length
      sort.sorts[sort_key].force_resort = false
      sort.sorts[sort_key].stale = false
      sort.sorts[sort_key].cache = (p.key for p in proposals)
      save sort

    # return the stale sort order
    else 
      if !sort.sorts[sort_key].stale
        sort.sorts[sort_key].stale = true 
        save sort 
      dict_proposals = {}
      for p in proposals 
        dict_proposals[p.key] = p 
      proposals = (dict_proposals[k] for k in sort.sorts[sort_key].cache)

  proposals



basic_proposal_scoring = (proposal, opinion_value) -> 
  if !opinion_value
    opinion_value = (o) -> o.stance

  opinions = fetch(proposal).opinions    
  if !opinions || opinions.length == 0
    return {sum: 0, avg: 0, std_dev: 0, opinions: []}

  filtered_out = fetch 'filtered'
  if filtered_out.users
    opinions = (o for o in opinions when filtered_out.enable_comparison || !(filtered_out.users?[o.user]))

  sum = 0
  for opinion in opinions
    sum += opinion_value(opinion)

  avg = sum / opinions.length

  differences = 0
  for o in opinions 
    differences += (o.stance - avg) * (o.stance - avg)

  std_dev = Math.sqrt(differences / opinions.length)
  {sum, avg, std_dev, opinions}


sort_options = [

  { 
    comp: (a, b) -> basic_proposal_scoring(b, ((o) -> o.stance)).avg - basic_proposal_scoring(a, ((o) -> o.stance)).avg
    name: 'Average Score'
    description: "Each response is scored by the average opinion score, where opinions are on [-1, 1]."
  }, { 
    comp: (a, b) -> basic_proposal_scoring(b, ((o) -> o.stance)).sum - basic_proposal_scoring(a, ((o) -> o.stance)).sum
    name: 'Total Score'
    description: "Each response is scored by the sum of opinions, where opinions are on [-1, 1]."
  }, {
    name: 'Trending'
    description: "'Total Score', except that newer opinions and responses are weighed more heavily."

    comp: (a, b) ->
      ov = (o) -> 
        ot = new Date(o.updated_at).getTime()
        n = Date.now()
        o.stance / (1 + Math.pow((n - ot) / 100000, 2))

      val = (proposal) -> 
        sum = basic_proposal_scoring(proposal, ov).sum
        n = Date.now()
        pt = new Date(proposal.created_at).getTime()
        sum / (1 + (n - pt) / 10000000000)  # decrease this constant to favor newer proposals

      val(b) - val(a)
  },
  { 
    name: 'Alphabetically'
    comp: (a, b) -> a.name.localeCompare b.name
    description: "Sort alphabetically by the response's title"
  }, {
    comp: (a,b) -> new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    name: 'Newest'
    description: "The responses submitted most recently are shown first."
  }, { 
    name: 'Unity'
    description: "Responses where the community is most united for or against are shown highest."
    comp: (a,b) -> 
      ov = (o) -> o.stance
      val = (proposal) ->
        stats = basic_proposal_scoring(proposal, ov)
        if stats.opinions.length > 1
          Math.log(stats.opinions.length + 1) / stats.std_dev / (1 - Math.abs(stats.avg) + 1)
        else 
          -1
      val(b) - val(a)

  }, { 
    name: 'Difference'
    description: "Responses where the community is most split are shown highest."
    comp: (a,b) -> 
      ov = (o) -> o.stance
      val = (proposal) ->
        stats = basic_proposal_scoring(proposal, ov)
        if stats.opinions.length > 1
          stats.std_dev * Math.log(stats.opinions.length + 1) 
        else
          -1
      val(b) - val(a)

  }, {
    name: 'Most Activity'
    description: "Ranked by number of opinions and discussion."

    comp: (a,b) ->
      ov = (o) -> 1 + (o.point_inclusions or []).length
      basic_proposal_scoring(b, ov).sum - basic_proposal_scoring(a, ov).sum

  }


]

set_sort = -> 
  sort = fetch 'sort_proposals'
  if !sort.name?
    found = false 
    loc = fetch('location')
    if loc.query_params?.sort_by
      for s in sort_options
        if s.name == loc.query_params.sort_by.replace('_', ' ')
          _.extend sort, s or sort_options[2]
          found = true 
          break

    if !found
      if def_sort = customization('homepage_default_sort_order')
        def = null 
        for s in sort_options
          if s.name == def_sort
            def = s
            break 
        _.extend sort, def or sort_options[2]

      else 
        _.extend sort, sort_options[2]

    save sort 





ProposalSort = ReactiveComponent
  displayName: 'ProposalSort'

  render : -> 

    proposals = fetch '/proposals' # registering dependency so that we get re-rendered...ApplyFilters is actually dependent
    filter_out = fetch 'filtered'
    # filters = fetch 'filters'

    subdomain = fetch '/subdomain'

    return SPAN null if !subdomain.name


    SPAN 
      style: _.defaults (@props.style or {})

      # ApplyFilters()


      DIV
        style: 
          display: 'inline-block'
          #verticalAlign: 'top'
          #paddingTop: 4 #16
          paddingRight: 12

        SortProposalsMenu() 

      # DIV
      #   style: 
      #     display: 'inline-block'
      #     verticalAlign: 'top'
      #     paddingTop: 8

      #   FORM 
      #     style: 
      #       position: 'relative'

      #     onSubmit: (e) => 
      #       n = @refs.new_filter.getDOMNode()
      #       filters.for_proposals ||= []
      #       filters.for_proposals.push n.value
      #       save filters
      #       n.value = null

      #       e.stopPropagation(); e.preventDefault()

      #     SVG
      #       width: 20
      #       height: 20
      #       style: 
      #         pointerEvents: 'none'
      #         position: 'absolute'
      #         right: 5
      #         top: 9
      #         zIndex: 1
      #       fill: '#888'

      #       viewBox: "0 0 100 125"
      #       G null,
      #         PATH
      #           d: "M69.054,59.058l27.471,23.811c2.494,2.162,2.766,5.971,0.604,8.465l-0.981,1.132c-2.162,2.494-5.971,2.766-8.465,0.604   L60.418,69.438"
      #         PATH 
      #           d: "M2.358,41.458c0-19.744,16.005-35.749,35.751-35.749c19.744,0,35.749,16.005,35.749,35.749  c0,19.746-16.005,35.751-35.749,35.751C18.363,77.208,2.358,61.203,2.358,41.458z M38.563,67.583  c14.428,0,26.124-11.696,26.124-26.126c0-14.428-11.696-26.124-26.124-26.124c-14.43,0-26.126,11.696-26.126,26.124  C12.438,55.887,24.134,67.583,38.563,67.583z"

      #     INPUT
      #       ref: 'new_filter' 
      #       type: 'text'
      #       'aria-label': 'search proposals'

      #       style:
      #         fontSize: 14
      #         padding: '2px 8px'
      #         width: 150
      #         border: '1px solid #aaa'

      #   DIV 
      #     style:
      #       paddingTop: 5

      #     for filter in (filters.for_proposals or [])
      #       do (filter) => 
      #         BUTTON 
      #           style: 
      #             backgroundColor: '#eee'
      #             color: '#666'
      #             padding: '4px 8px'
      #             borderRadius: 16
      #             fontSize: 16
      #             cursor: 'pointer'
      #             boxShadow: '0 1px 1px rgba(0,0,0,.2)'
      #             marginRight: 10
      #             border: 'none'

      #           onClick: -> 
      #             idx = filters.for_proposals.indexOf(filter)
      #             filters.for_proposals.splice idx, 1
      #             save filters

      #           filter
      #           SPAN 
      #             style: 
      #               color: '#aaa'
      #               fontSize: 10
      #               paddingLeft: 10
      #             'x'



SortProposalsMenu = ReactiveComponent
  displayName: 'SortProposalsMenu'
  render: -> 

    sort = fetch 'sort_proposals'
    set_sort() if !sort.name? 

    SPAN
      style: 
        color: 'black'
        fontSize: 20

      TRANSLATE "engage.sort_by", "sort by"

      " "

      DropMenu
        options: sort_options

        open_menu_on: 'activation'

        selection_made_callback: (option) -> 
          invalidate_proposal_sorts()
          _.extend sort, option   
          save sort 

        render_anchor: ->
          SPAN 
            style: 
              fontWeight: 700

            translator "engage.sort_order.#{sort.name}", sort.name

            SPAN style: _.extend cssTriangle 'bottom', focus_color(), 8, 5,
              display: 'inline-block'
              marginLeft: 4   
              marginBottom: 2

        render_option: (option, is_active) -> 
          [        
            DIV 
              style: 
                fontWeight: 600
                fontSize: 20

              translator "engage.sort_order.#{option.name}", option.name 

            DIV 
              style: 
                fontSize: 12
                color: if is_active then 'white' else 'black'

              translator "engage.sort_order.#{option.name}.description", option.description 
          ]

        wrapper_style: 
          display: 'inline-block'

        anchor_style: 
          fontWeight: 600
          padding: 0
          display: 'inline-block'
          color: focus_color() #'inherit'
          textTransform: 'lowercase'
          borderRadius: 16

        menu_style: 
          minWidth: 500
          backgroundColor: '#eee'
          border: "1px solid #{focus_color()}"
          left: -9999
          top: 18
          borderRadius: 8
          fontWeight: 400
          overflow: 'hidden'
          boxShadow: '0 1px 2px rgba(0,0,0,.3)'

        menu_when_open_style: 
          left: 0

        option_style: 
          padding: '6px 12px'
          borderBottom: "1px solid #ddd"
          display: 'block'

        active_option_style: 
          color: 'white'
          backgroundColor: focus_color()




window.opinion_trickle = -> 
  filter_out = fetch 'filtered'
  
  proposals = fetch '/proposals'

  users = {}
  for prop in proposals.proposals
    for o in prop.opinions
      users[o.user] = o.created_at or o.updated_at

  users = ([k,v] for k,v of users)
  users.sort (a,b) -> 
    i = new Date(a[1])
    j = new Date(b[1])
    i.getTime() - j.getTime()

  users = (u[0] for u in users)
  cnt = users.length

  steps = 1
  tick = (interval) => 
    if cnt >= 0
      setTimeout => 
        filter_out.users = {}
        for user, idx in users
          filter_out.users[user] = 1
          break if idx > cnt 

        cnt--
        #cnt -= Math.ceil(steps / 2)
        #tick(interval * .9)
        tick(interval * .9)
        steps++
        dirty = true
        setTimeout -> 
          if dirty
            save filter_out
            dirty = false
        , 2000
      , interval

  tick 1000



toggle_filter = (filter) -> 
  users = fetch '/users'
  filter_out = fetch 'filtered'

  return if !users.users
  
  filter_out.users = {}

  if filter_out.current_filter == filter
    filter_out.current_filter = null 
  else 
    filter_out.current_filter = filter 

  filter_func = filter_out.current_filter?.pass

  if filter_func
    for user in users.users      
      if !filter_func(user)
        filter_out.users[user.key] = 1

  invalidate_proposal_sorts()
  save filter_out

set_comparison_mode = (enabled) ->
  filter_out = fetch 'filtered'

  if enabled == null # toggle if argument not passed 
    filter_out.enable_comparison = !filter_out.enable_comparison
  else 
    filter_out.enable_comparison = enabled
  save filter_out 


OpinionFilter = ReactiveComponent
  displayName: 'OpinionFilter'

  render : -> 

    filter_out = fetch 'filtered'
    users = fetch '/users' # fetched here so its ready for toggle_filter func

    return DIV null if !users.users
    filters_for_admin = customization('opinion_filters_admin_only') 
    custom_filters = customization 'opinion_filters'
    if typeof(custom_filters) == 'function'
      custom_filters = custom_filters()

    is_admin = fetch('/current_user').is_admin
    
    filters = [{
                label: 'everyone'
                tooltip: null 
                pass: (u) -> true 
              }, {
                label: 'just you'
                tooltip: null 
                pass: (u) -> 
                  user = fetch(u)
                  user.key == fetch('/current_user').user
              }]

    if custom_filters && (!filters_for_admin || is_admin)
      for filter in custom_filters
        if !filter.admin_only || is_admin
          filters.push filter

    if !filter_out.current_filter
      dfault = customization('opinion_filters_default') or 'everyone'
      initial_filter = null 
      for filter in filters 
        if filter.label == dfault 
          initial_filter = filter 
          break 

      initial_filter ||= filters[0]

      toggle_filter initial_filter

    current_filter = filter_out.current_filter

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
            fontSize: 20
            position: 'relative'

          if true || current_filter?.label in ['everyone', 'just you']
            TRANSLATE "engage.opinion_filter.label", 'show opinion of' 
          else 
            TRANSLATE "engage.opinion_filter.label_short", 'showing'
          
          ": "

          DropMenu
            options: filters

            open_menu_on: 'activation'

            selection_made_callback: toggle_filter

            render_anchor: ->
              
              key = if current_filter?.label not in ['everyone', 'just you'] then "/translations/#{fetch('/subdomain').name}" else null
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

          if current_filter.label != 'everyone'
            DIV 
              style: @props.enable_comparison_wrapper_style or {}


              INPUT 
                type: 'checkbox'
                id: 'enable_comparison'
                checked: filter_out.enable_comparison
                ref: 'enable_comparison'
                onChange: => 
                  set_comparison_mode @refs.enable_comparison.getDOMNode().checked

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






window.ProposalSort = ProposalSort
window.SortProposalsMenu = SortProposalsMenu
window.OpinionFilter = OpinionFilter