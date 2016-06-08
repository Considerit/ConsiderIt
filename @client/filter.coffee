require './shared'
require './customizations'





get_all_tags = -> 
  proposals = fetch '/proposals'
  proposals = _.flatten (c.proposals for c in proposals.clusters)
  all_tags = {}
  for proposal in proposals 
    text = "#{proposal.name} #{proposal.description}"

    if text.indexOf("#") > -1 && tags = text.match(/#(\w+)/g)
      for tag in tags
        tag = tag.toLowerCase()

        all_tags[tag] ||= 0
        all_tags[tag] += 1

  # ordered_tags = ({tag: k, count: v} for k,v of all_tags when v > 1)
  # ordered_tags.sort (a,b) -> b.count - a.count

  all_tags 


regexes = {}
ApplyFilters = ReactiveComponent
  displayName: 'ApplyFilters'

  render: ->
    filters = fetch 'filters'
    filter_out = fetch 'filtered'
    filter_out.proposals ||= {}

    proposals = fetch '/proposals'
    proposals = _.flatten (c.proposals for c in proposals.clusters)

    new_filter_out = {}

    for filter in (filters.for_proposals or [])
      if !regexes[filter]
        regexes[filter] = new RegExp filter, 'i'

    for proposal in proposals 
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

  proposal_rank = sort.func or customization("proposal_rank")

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
    description: "Each proposal is scored by the sum of opinions, with newer opinions weighed more heavily."
  }


]


set_sort = -> 
  sort = fetch 'sort_proposals'
  if !sort.func?
    if customization("proposal_rank")
      sort.func = customization("proposal_rank")
      sort.name = 'custom'
    else if customization('default_proposal_sort')
      def = null 
      for s in sort_options
        if s.name == customization('default_proposal_sort')
          def = s 

      _.extend sort, def or sort_options[0]

    else 
      _.extend sort, sort_options[0]

    save sort 





ProposalFilter = ReactiveComponent
  displayName: 'ProposalFilter'

  render : -> 

    proposals = fetch '/proposals'
    filter_out = fetch 'filtered'
    filters = fetch 'filters'

    sort = fetch 'sort_proposals'

    set_sort() if !sort.func? 

    DIV 
      style: _.defaults (@props.style or {})

      ApplyFilters()



      FORM 
        onSubmit: (e) => 
          n = @refs.new_filter.getDOMNode()
          filters.for_proposals ||= []
          filters.for_proposals.push n.value
          save filters
          n.value = null

          e.stopPropagation(); e.preventDefault()


        INPUT
          ref: 'new_filter' 
          type: 'text'
          placeholder: 'search proposals'
          style:
            fontSize: 16
            padding: '4px 8px'
            width: 300

      DIV 
        style:
          paddingTop: 5

        for filter in (filters.for_proposals or [])
          do (filter) => 
            SPAN 
              style: 
                backgroundColor: '#eee'
                color: '#666'
                padding: '4px 8px'
                borderRadius: 16
                fontSize: 16
                cursor: 'pointer'
                boxShadow: '0 1px 1px rgba(0,0,0,.2)'
                marginRight: 10
              onClick: -> 
                idx = filters.for_proposals.indexOf(filter)
                filters.for_proposals.splice idx, 1
                save filters

              filter 

      DIV
        style: 
          color: focus_blue
          fontSize: 20
          fontWeight: 500
          marginTop: 12

        "sort proposals by "


        SPAN 
          style: 
            fontWeight: 700
            position: 'relative'
            cursor: 'pointer'
            textDecoration: 'underline'

          onClick: => 
            @local.show_sort_options = !@local.show_sort_options
            save @local

          sort.name

          SPAN style: _.extend cssTriangle 'bottom', focus_blue, 11, 7,
            display: 'inline-block'
            marginLeft: 4

          if @local.show_sort_options
            DIV 
              style: 
                position: 'absolute'
                zIndex: 999
                width: HOMEPAGE_WIDTH()
                backgroundColor: 'white'
                border: "1px solid #{focus_blue}"
                top: 24
                borderRadius: 8
                fontWeight: 400
                overflow: 'hidden'
                boxShadow: '0 1px 2px rgba(0,0,0,.3)'

              for sort_option in sort_options #when sort_option.name != sort.name
                do (sort_option) => 
                  DIV 
                    style:
                      padding: '6px 12px'
                      borderBottom: "1px solid #eaeaea"
                      color: if @local.hover == sort_option.name then 'white'
                      backgroundColor: if @local.hover == sort_option.name then focus_blue
                      fontWeight: 600
                    onMouseEnter: => @local.hover = sort_option.name; save @local 
                    onMouseLeave: => @local.hover = null; save @local
                    onClick: (e) =>
                      _.extend sort, sort_option                      
                      save sort 
                      @local.show_sort_options = false
                      save @local
                      e.stopPropagation()


                    sort_option.name

                    DIV 
                      style: 
                        fontSize: 16
                        color: if @local.hover == sort_option.name then '#ccc' else '#888'
                        fontWeight: 400

                      sort_option.description



OpinionFilter = ReactiveComponent
  displayName: 'OpinionFilter'

  render : -> 

    filters = customization 'opinion_filters'
    users = fetch '/users'
    filter_out = fetch 'filtered'
    bitcoin = fetch('/subdomain').name in ['bitcoin', 'bitcoinclassic']

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

      DIV 
        style: 
          color: focus_blue
          fontSize: 20
          fontWeight: 600

        'Filter opinions to' 
        if bitcoin 
          ' verified'

      if bitcoin
        VerificationProcessExplanation()

      DIV 
        style: 
          marginTop: 0
        for filter,idx in filters 
          do (filter, idx) => 
            is_enabled = filter_out.opinion_filters?[filter.label]
            DIV 
              ref: "filter-#{idx}"
              style: 
                display: 'inline-block'
                marginRight: if idx != filters.length - 1 then 5
                paddingRight: if idx != filters.length - 1 then 5  
                borderRight: if idx != filters.length - 1 then '1px solid #ddd'
                color: if is_enabled then focus_blue else '#aaa'
                cursor: 'pointer'
                fontSize: 16

              onMouseEnter: => 
                if filter.tooltip 
                  tooltip = fetch 'tooltip'
                  tooltip.coords = $(@refs["filter-#{idx}"].getDOMNode()).offset()
                  tooltip.tip = filter.tooltip
                  save tooltip
              onMouseLeave: => 
                if filter.tooltip 
                  tooltip = fetch 'tooltip'
                  tooltip.coords = tooltip.tip = null 
                  save tooltip
              onClick: -> toggle_filter(filter)              

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