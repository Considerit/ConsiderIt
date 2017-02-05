require './shared'
require './customizations'





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



window.sorted_proposals = (proposals) ->

  sort = fetch 'sort_proposals'
  set_sort() if !sort.func? 

  proposal_rank = sort.func

  proposals = proposals.slice().sort (a,b) ->
    return proposal_rank(b, sort.opinion_value) - proposal_rank(a, sort.opinion_value)

  # filter out filtered proposals
  filter_out = fetch 'filtered'
  if filter_out.proposals
    filtered = []
    for proposal in proposals
      if filter_out.proposals[proposal.key]
        filtered.push proposal
    for proposal in filtered
      proposals.splice proposals.indexOf(proposal), 1

  proposals



basic_proposal_scoring = (proposal, opinion_value) -> 
  if !opinion_value
    opinion_value = (o) -> o.stance

  opinions = fetch(proposal).opinions    
  if !opinions || opinions.length == 0
    return null

  filtered_out = fetch('filtered')
  if filtered_out.users
    opinions = (o for o in opinions when !(filtered_out.users?[o.user]))

  sum = 0
  for opinion in opinions
    sum += opinion_value(opinion)

  sum


sort_options = [

  { 
    func: basic_proposal_scoring
    name: 'total score'
    opinion_value: (o) -> o.stance
    description: "Each proposal is scored by the sum of opinions, where opinions are on [-1, 1]."
  }, {
    func: (proposal) -> new Date(proposal.created_at).getTime()
    name: 'newest'
    description: "The proposals submitted most recently are shown first."
  }, {
    func: basic_proposal_scoring
    name: 'most activity'
    opinion_value: (o) -> 1 + (o.point_inclusions or []).length
    description: "Each proposal is scored by the raw number of opinions and recognized pros/cons."
  }, { 
    func: (proposal, opinion_value) -> 
      sum = basic_proposal_scoring(proposal, opinion_value)
      sum / fetch(proposal).opinions.length
    name: 'average score'
    opinion_value: (o) -> o.stance
    description: "Each proposal is scored by the average opinion score, where opinions are on [-1, 1]."
  }, {
    func: (proposal) -> 
      if fetch(proposal.your_opinion).published then proposal.your_opinion.stance else -1
    name: 'your score'
    description: "Proposals are ordered by your own opinion on them."
  }, {
    func: (proposal, opinion_value) -> 
      sum = basic_proposal_scoring(proposal, opinion_value)
      n = Date.now()
      pt = new Date(proposal.created_at).getTime()
      sum / (1 + (n - pt) / 10000000000)  # decrease this constant to favor newer proposals


    name: 'trending'
    opinion_value: (o) -> 
      ot = new Date(o.updated_at).getTime()
      n = Date.now()
      o.stance / (1 + Math.pow((n - ot) / 100000, 2))
    description: "Like 'total score', except that newer opinions are weighed more heavily, and older proposals are penalized."
  }


]


set_sort = -> 
  sort = fetch 'sort_proposals'

  if !sort.func?
    found = false 
    loc = fetch('location')
    if loc.query_params?.sort_by
      for s in sort_options
        if s.name == loc.query_params.sort_by.replace('_', ' ')
          _.extend sort, s or sort_options[0]
          found = true 
          break

    if !found
      if def_sort = customization('homepage_default_sort_order')
        def = null 
        for s in sort_options
          if s.name == def_sort
            def = s
            break 
        _.extend sort, def or sort_options[0]

      else 
        _.extend sort, sort_options[0]

    save sort 





ProposalFilter = ReactiveComponent
  displayName: 'ProposalFilter'

  render : -> 

    proposals = fetch '/proposals' # registering dependency so that we get re-rendered...ApplyFilters is actually dependent
    filter_out = fetch 'filtered'
    filters = fetch 'filters'

    subdomain = fetch '/subdomain'

    return SPAN null if !subdomain.name


    DIV 
      style: _.defaults (@props.style or {})

      ApplyFilters()


      DIV
        style: 
          display: 'inline-block'
          verticalAlign: 'top'
          paddingTop: 16
          paddingRight: 12

        SortProposalsMenu() 

      DIV
        style: 
          display: 'inline-block'
          verticalAlign: 'top'
          paddingTop: 8

        FORM 
          style: 
            position: 'relative'

          onSubmit: (e) => 
            n = @refs.new_filter.getDOMNode()
            filters.for_proposals ||= []
            filters.for_proposals.push n.value
            save filters
            n.value = null

            e.stopPropagation(); e.preventDefault()

          SVG
            width: 20
            height: 20
            style: 
              pointerEvents: 'none'
              position: 'absolute'
              right: 5
              top: 9
              zIndex: 1
            fill: '#888'

            viewBox: "0 0 100 125"
            G null,
              PATH
                d: "M69.054,59.058l27.471,23.811c2.494,2.162,2.766,5.971,0.604,8.465l-0.981,1.132c-2.162,2.494-5.971,2.766-8.465,0.604   L60.418,69.438"
              PATH 
                d: "M2.358,41.458c0-19.744,16.005-35.749,35.751-35.749c19.744,0,35.749,16.005,35.749,35.749  c0,19.746-16.005,35.751-35.749,35.751C18.363,77.208,2.358,61.203,2.358,41.458z M38.563,67.583  c14.428,0,26.124-11.696,26.124-26.126c0-14.428-11.696-26.124-26.124-26.124c-14.43,0-26.126,11.696-26.126,26.124  C12.438,55.887,24.134,67.583,38.563,67.583z"

          INPUT
            ref: 'new_filter' 
            type: 'text'
            'aria-label': 'search proposals'

            style:
              fontSize: 14
              padding: '2px 8px'
              width: 150
              border: '1px solid #aaa'

        DIV 
          style:
            paddingTop: 5

          for filter in (filters.for_proposals or [])
            do (filter) => 
              BUTTON 
                style: 
                  backgroundColor: '#eee'
                  color: '#666'
                  padding: '4px 8px'
                  borderRadius: 16
                  fontSize: 16
                  cursor: 'pointer'
                  boxShadow: '0 1px 1px rgba(0,0,0,.2)'
                  marginRight: 10
                  border: 'none'

                onClick: -> 
                  idx = filters.for_proposals.indexOf(filter)
                  filters.for_proposals.splice idx, 1
                  save filters

                filter
                SPAN 
                  style: 
                    color: '#aaa'
                    fontSize: 10
                    paddingLeft: 10
                  'x'



SortProposalsMenu = ReactiveComponent
  displayName: 'SortProposalsMenu'
  render: -> 

    sort = fetch 'sort_proposals'
    set_sort() if !sort.func? 

    trigger = (e) =>
      _.extend sort, sort_options[@local.focus]                      
      save sort 
      @local.sort_menu = false
      save @local
      e.stopPropagation()
      e.preventDefault()

    set_focus = (idx) => 
      idx = 0 if !idx?
      @local.focus = idx 
      save @local 
      setTimeout => 
        @refs["menuitem-#{idx}"].getDOMNode().focus()
      , 0

    close_menu = => 
      document.activeElement.blur()
      @local.sort_menu = false
      save @local


    DIV
      style: 
        color: '#666'
        fontSize: 14

      "sort by "


      DIV 
        ref: 'menu_wrap'
        key: 'proposal_sort_order_menu'
        style: 
          display: 'inline-block'
          position: 'relative'

        onTouchEnd: => 
          @local.sort_menu = !@local.sort_menu
          save(@local)

        onMouseLeave: close_menu

        onBlur: (e) => 
          setTimeout => 
            # if the focus isn't still on an element inside of this menu, 
            # then we should close the menu
            if $(document.activeElement).closest(@refs.menu_wrap.getDOMNode()).length == 0
              @local.sort_menu = false; save @local
          , 0

        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32 || e.which == 27 # ENTER or ESC
            close_menu()
          else if e.which == 38 || e.which == 40 # UP / DOWN ARROW
            @local.focs = -1 if !@local.focus?
            if e.which == 38
              @local.focus--
              if @local.focus < 0 
                @local.focus = sort_options.length - 1
            else 
              @local.focus++
              if @local.focus > sort_options.length - 1
                @local.focus = 0 
            set_focus(@local.focus)
            e.preventDefault() # prevent window from scrolling too


          
        BUTTON 
          tabIndex: 0
          'aria-haspopup': "true"
          'aria-owns': "proposal_sort_order_menu_popup"

          style: 
            #fontWeight: 700
            position: 'relative'
            cursor: 'pointer'
            #textDecoration: 'underline'
            backgroundColor: 'transparent'
            border: 'none'
            padding: 0
            display: 'inline-block'
            fontSize: 'inherit'
            color: 'inherit'
            #border: "1px solid #ccc"
            #padding: "4px 8px"
            
            borderRadius: 16

          onClick: => 
            @local.sort_menu = !@local.sort_menu
            set_focus(0) if @local.sort_menu
            save(@local)
          
          onKeyDown: (e) =>
            if e.which == 13 || e.which == 32  
              @local.sort_menu = !@local.sort_menu
              set_focus(0) if @local.sort_menu
              save(@local)
              e.preventDefault()
              e.stopPropagation()

          sort.name

          SPAN style: _.extend cssTriangle 'bottom', "#777", 11, 7,
            display: 'inline-block'
            marginLeft: 4

        
        UL 
          id: 'proposal_sort_order_menu_popup'
          role: "menu"
          'aria-hidden': !@local.sort_menu
          hidden: !@local.sort_menu
          style: 
            position: 'absolute'
            left: if @local.sort_menu then 0 else -9999
            listStyle: 'none'
            zIndex: 999
            width: HOMEPAGE_WIDTH()
            backgroundColor: '#eee'
            border: "1px solid #{focus_blue}"
            top: 18
            borderRadius: 8
            fontWeight: 400
            overflow: 'hidden'
            boxShadow: '0 1px 2px rgba(0,0,0,.3)'

          for sort_option, idx in sort_options
            do (sort_option) => 
              LI 
                ref: "menuitem-#{idx}"
                key: sort_option.name
                role: "menuitem"
                tabIndex: if @local.focus == idx then 0 else -1
                style:
                  padding: '6px 12px'
                  borderBottom: "1px solid #ddd"
                  color: if @local.focus == idx then 'white'
                  backgroundColor: if @local.focus == idx then focus_blue
                  fontWeight: 600
                  cursor: 'pointer'
                  display: 'block'
                  outline: 'none'

                onClick: do(idx) => (e) => 
                  if @local.focus != idx 
                    set_focus idx 
                  trigger(e)
                onTouchEnd: do(idx) => (e) =>
                  if @local.focus != idx 
                    set_focus idx 
                  trigger(e)

                onKeyDown: (e) => 
                  if e.which == 13 || e.which == 32 # ENTER or SPACE
                    trigger(e) 
                    e.preventDefault()
                    
                onFocus: do(idx) => (e) => 
                  if @local.focus != idx 
                    set_focus idx
                  e.stopPropagation()
                onMouseEnter: do(idx) => => 
                  if @local.focus != idx 
                    set_focus idx
                onBlur: do(idx) => (e) =>
                  @local.focus = null 
                  save @local  
                onMouseExit: do(idx) => => 
                  @local.focus = null 
                  save @local

                sort_option.name

                DIV 
                  style: 
                    fontSize: 16
                    color: if @local.focus == idx then '#eee' else '#888'
                    fontWeight: 400

                  sort_option.description



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

OpinionFilter = ReactiveComponent
  displayName: 'OpinionFilter'

  render : -> 

    filters = customization 'opinion_filters'
    users = fetch '/users'
    filter_out = fetch 'filtered'
    bitcoin = fetch('/subdomain').name in ['bitcoin', 'bitcoinclassic']
    
    filters_for_admin = customization('opinion_filters_admin_only') 

    return SPAN null if filters_for_admin && !fetch('/current_user').is_admin

    toggle_filter = (filter) -> 
      filter_out.users = {}
      filter_out.opinion_filters ||= {}

      if filter_out.opinion_filters[filter.label]
        delete filter_out.opinion_filters[filter.label]
      else 
        filter_out.opinion_filters = {} # act like radio button
        filter_out.opinion_filters[filter.label] = filter


      filter_funcs = (f.pass for k,f of filter_out.opinion_filters)
      if filter_funcs.length > 0
        for user in users.users
          passes = true 
          for func in filter_funcs
            passes &&= func(user)

          if !passes
            filter_out.users[user.key] = 1

      save filter_out

    if fetch('/subdomain').name == 'bitcoinclassic' && !filter_out.opinion_filters?
      toggle_filter filters[0]


    DIV 
      style: (@props.style or {})
      className: 'filter_opinions_to'

      DIV 
        style: 
          color: focus_blue
          fontSize: 14
          fontWeight: 600

        'filter to' 
        if bitcoin 
          ' verified'
        ':'

      if bitcoin
        VerificationProcessExplanation()

      DIV 
        style: 
          marginTop: 0

        for filter,idx in filters 
          do (filter, idx) => 
            show_tooltip = => 
              @local.focus = idx
              save @local
              if filter.tooltip 
                tooltip = fetch 'tooltip'
                tooltip.coords = $(@refs["filter-#{idx}"].getDOMNode()).offset()
                tooltip.tip = filter.tooltip
                save tooltip

            hide_tooltip = => 
              @local.focus = null
              save @local            
              if filter.tooltip 
                tooltip = fetch 'tooltip'
                tooltip.coords = tooltip.tip = null 
                save tooltip

            is_enabled = filter_out.opinion_filters?[filter.label]
            BUTTON 
              'aria-label': "Filter opinions to #{filter.label}"
              'aria-describedby': if filter.tooltip then 'tooltip'
              'aria-pressed': is_enabled
              tabIndex: 0
              ref: "filter-#{idx}"
              style: 
                display: 'inline-block'
                marginLeft: 7
                padding: '0 3px 0 3px'  
                color: if is_enabled then 'white' else if @local.focus == idx then 'black' else '#777'
                cursor: 'pointer'
                fontSize: 16
                backgroundColor: if is_enabled then focus_blue else if @local.focus == idx then '#eee' else 'transparent'
                border: 'none'
                outline: 'none'

              onMouseEnter: show_tooltip
              onMouseLeave: hide_tooltip
              onFocus: show_tooltip
              onBlur: hide_tooltip 
              onClick: -> toggle_filter(filter)   
              onKeyDown: (e) -> 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  toggle_filter(filter) 
                  e.preventDefault()
                  e.stopPropagation()

              filter.label


VerificationProcessExplanation = ReactiveComponent
  displayName: 'VerificationProcessExplanation'
  render: -> 
    users = fetch '/users'
    callout = "about verification"
    DIV 
      style: 
        position: 'absolute'
        right: -sizeWhenRendered(callout, {fontSize: 12}).width
        top: -3

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






window.ProposalFilter = ProposalFilter
window.OpinionFilter = OpinionFilter