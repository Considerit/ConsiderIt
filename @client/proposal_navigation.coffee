require './customizations'
require './shared'






window.get_next_proposals = (args) -> 
  relative_to = args.relative_to
  all_proposals = fetch '/proposals' 
  subdomain = fetch('/subdomain')
  mod = (n, m) -> ((n % m) + m) % m

  return [[],[]] if !all_proposals.proposals || all_proposals.proposals.length == 0 

  # Determine the next proposal
  next_proposals = []; prev_proposals = []
  clusters = clustered_proposals_with_tabs()        
  all_proposals_flat = _.flatten (sorted_proposals(cluster.proposals) for cluster in clusters)
  if subdomain.name == 'HALA' && fetch('homepage_tabs').filter == 'Draft zoning changes'
    hala = fetch('hala')
    hala.name ||= capitalize(relative_to.slug.split('--')[0].replace(/_/g, ' '))
    all_proposals_flat = (p for p in all_proposals_flat when p.name.toLowerCase().indexOf(hala.name.toLowerCase()) > -1)
  else if subdomain.name in ['cprs-network', 'engage-cprs']
    all_proposals_flat = []
  
  idx = 0
  for proposal, idx in all_proposals_flat
    if proposal == relative_to
      break

  next_idx = mod(idx + 1, all_proposals_flat.length)
  prev_idx = mod(idx - 1, all_proposals_flat.length)

  for idx in [0..(args.count or all_proposals.proposals.length) - 1]
    break if !all_proposals_flat[ next_idx + idx ]
    continue if all_proposals_flat[ next_idx + idx ].key == relative_to.key
    next_proposals.push all_proposals_flat[ next_idx + idx ]

  if !args.count || (next_proposals.length < all_proposals.proposals.length && next_idx > 0)
    for idx in [0..(args.count or all_proposals.proposals.length) - 1 - next_proposals.length]
      break if !all_proposals_flat[ idx ] || all_proposals_flat[ idx ].key == relative_to.key
      next_proposals.push all_proposals_flat[ idx ]


  for idx in [0..(args.count or all_proposals.proposals.length) - 1]
    break if prev_idx - idx < 0
    continue if !all_proposals_flat[ prev_idx - idx ] || all_proposals_flat[ prev_idx - idx ].key == relative_to.key
    prev_proposals.push all_proposals_flat[ prev_idx - idx ]



  [prev_proposals, next_proposals]


window.NextProposals = ReactiveComponent
  displayName: 'NextProposals'

  render: -> 

    [dummy, next] = get_next_proposals
                      relative_to: @props.proposal 

    count = @props.count or 5

    to_show_first = []
    to_show_later = []
    for proposal in next 
      if !proposal.your_opinion.published
        to_show_first.push proposal 
      else 
        to_show_later.push proposal 

    to_show = to_show_first.concat(to_show_later)
    return SPAN null if to_show.length < 2 && arest.cache['/proposals']?.proposals?

    heading_style = _.defaults {}, customization('list_label_style'),
      fontSize: 36
      fontWeight: 700
      fontStyle: 'oblique'
      textAlign: 'center'
      marginBottom: 18

    loc = fetch 'location'
    hash = loc.url.split('/')[1].replace('-', '_')

    DIV 
      style: {}

      H2
        style: heading_style

        TRANSLATE
          id: "engage.related_proposals" 
          'Explore a related idea'

      if !to_show || to_show.length == 0
        LOADING_INDICATOR

      else 
        UL null, 

          for proposal, idx in to_show
            break if idx > count 

            cluster = proposal.cluster or 'Proposals'

            CollapsedProposal 
              key: "collapsed#{proposal.key or proposal}"
              proposal: proposal
              show_category: true
              width: @props.width
              hide_scores: true

      DIV 
        style: 
          textAlign: 'right'
          fontSize: 22

        TRANSLATE
          id: 'engage.back_to_homepage_option'
          link: 
            component: A 
            args: 
              href: "/##{hash}"
              style: 
                textDecoration: 'underline'
                fontWeight: 600
          "…or go <link>back to the homepage</link>"






window.GroupedProposalNavigation = (args) -> 
  proposals = fetch('/proposals').proposals

  heading_style = _.defaults {}, customization('list_label_style'),
    fontSize: 36
    fontWeight: 700
    fontStyle: 'oblique'
    textAlign: 'center'
    marginBottom: 18

  proposals_by_list = clustered_proposals(true)


  sections = ([k,v] for k,v of customization('homepage_tabs'))
  if !sections or sections.length == 0
    sections = [['all', _.keys(proposals_by_list)]] # TODO: check if this is correct default
  
  active_list = args.proposal.cluster or 'Proposals'



  local = fetch 'popnav'
  if !local.show?
    local.show = {}
    local.show[(args.proposal.cluster or 'Proposals')] = true 

  toggle_list = (category) ->
    local.show[category] = !local.show[category]
    save local 

  loc = fetch 'location'
  hash = loc.url.split('/')[1].replace('-', '_')


  current_section = null

  DIV 
    style: {}

    H2
      style: heading_style

      TRANSLATE
        id: 'engage.navigate_elsewhere.groupednav.header'
        'Done? Navigate to a different question'

    if !proposals || proposals.length == 0 
      LOADING_INDICATOR

    else 

      UL 
        style:
          listStyle: 'none'
          padding: 0

        for [name, lists] in sections 
          active_section = false 

          lists = clustered_proposals_with_tabs(name)

          total_proposals = 0
          for list in lists
            if active_list == list.name
              active_section = true 
              current_section = name
            total_proposals += (list.proposals or []).length            

          continue if total_proposals == 0 || name == 'Show all'

          LI 
            style: 
              marginBottom: 24


            if sections.length > 1
              H3
                style: {} 
                  

                A 
                  href: "/?tab=#{encodeURIComponent(name)}#active_tab"
                  style: 
                    fontSize: 28
                    fontWeight: 700
                    backgroundColor: '#ddd'
                    # textDecoration: 'underline'
                    cursor: 'pointer'
                    color: "#888"
                    fontWeight: 800
                    display: 'block'
                    marginLeft: -34
                    padding: '0 34px'

                  name

            if active_section

              UL 
                style: 
                  listStyle: 'none'
                  marginTop: 14

                for list in lists 
                  is_collapsed = !local.show[list.name] 
                  tw = if is_collapsed then 15 else 20
                  th = if is_collapsed then 20 else 15

                  cluster_key = list.key    
                  list_items_title = customization('list_items_title', cluster_key) or list.name or 'Proposals'
                  heading_text = customization('list_label', cluster_key) or list_items_title

                  continue if (list.proposals or []).length == 0 

                  do (list) => 
                    LI 
                      style: {}


                      if lists.length > 1 || sections.length == 1
                        H4 
                          style: 
                            marginBottom: 12 
                            cursor: 'pointer'
                            position: 'relative'

                          onKeyDown: (e) -> 
                            if e.which == 13 || e.which == 32 # ENTER or SPACE
                              toggle_list(list.name)
                              e.preventDefault()
                          onClick: -> 
                            toggle_list(list.name)
                            document.activeElement.blur()

                          if lists.length > 1
                            SPAN 
                              'aria-hidden': true
                              style: cssTriangle (if is_collapsed then 'right' else 'bottom'), (heading_style.color or 'black'), tw, th,
                                position: 'absolute'
                                left: -tw - 20
                                top: if is_collapsed then 10 else 13
                                width: tw
                                height: th
                                # display: if @local.hover_label or is_collapsed then 'inline-block' else 'none'
                                outline: 'none'

                          SPAN 
                            style: 
                              fontSize: 24

                            heading_text    


                      if local.show[list.name]


                        UL 
                          style: 
                            marginLeft: 0 #48

                          for proposal in list.proposals


                            cluster = proposal.cluster or 'Proposals'
                            active = proposal.slug == args.proposal.slug


                            [

                              if active 
                                DIV 
                                  style: 
                                    width: args.width 
                                    position: 'relative'
                                  DIV 
                                    style: 
                                      position: 'absolute'
                                      left: -150
                                      top: 0
                                    dangerouslySetInnerHTML: __html: "#{TRANSLATE('engage.navigation_helper_current_location', 'You are here')} &rarr;"

                              CollapsedProposal 
                                key: "collapsed#{proposal.key or proposal}"
                                proposal: proposal
                                show_category: true
                                width: args.width
                                hide_scores: true
                                hide_icons: true
                                hide_metadata: true
                                show_category: false
                                name_style: 
                                  fontSize: 16
                                wrapper_style: 
                                  backgroundColor: if active then "#eee"
                                icon: if proposal.your_opinion.published
                                        -> 
                                          SPAN 
                                            style: 
                                              position: 'relative'
                                              left: -22
                                              top: 3
                                            width: 8
                                            dangerouslySetInnerHTML: __html: '&#x2714;'
                                      else 
                                        -> 
                                          SPAN null 


                            ]




    DIV 
      style: 
        textAlign: 'right'
        fontSize: 22
        marginTop: 40

      TRANSLATE
        id: 'engage.back_to_homepage_option'
        link: 
          component: A 
          args: 
            href: if current_section && current_section != 'all' then "/?tab=#{encodeURIComponent(current_section)}##{hash}" else "/##{hash}"
            style: 
              textDecoration: 'underline'
              fontWeight: 600
        "…or go <link>back to the homepage</link>"



window.BackHomeNavigation = (args) -> 
  proposals = fetch('/proposals').proposals

  heading_style = _.defaults {}, customization('list_label_style'),
    fontSize: 36
    fontWeight: 400
    fontStyle: 'oblique'
    textAlign: 'center'
    marginBottom: 18


  loc = fetch 'location'
  hash = loc.url.split('/')[1].replace('-', '_')

  DIV 
    style: {}

    H2
      style: heading_style

      
      'Done? Go '

      A 
        href: "/##{hash}"
        style: 
          textDecoration: 'underline'
          fontWeight: 700
        "back to the homepage"
      '.'

























##
# DefaultProposalNavigation
#
# A header that displays a prev/next proposal button & cluster name

window.DefaultProposalNavigation = ReactiveComponent
  displayName: 'ProposalNavigation'
  render : ->

    [prev_proposals, next_proposals] = get_next_proposals
                                         relative_to: @proposal
                                         count: 1

    next_proposal = next_proposals[0]
    prev_proposal = prev_proposals[0]
    DIV
      style:
        margin: "30px auto 0 auto"
        width: HOMEPAGE_WIDTH()
        position: 'relative'

      if next_proposal || prev_proposal
        NAV 
          'aria-label': 'Previous or next proposals'
          role: 'navigation'
          style: 
            position: 'absolute'
            right: 0

          # Next button
          if next_proposal
            A
              'title': 'Previous proposal'
              style:
                display: 'inline-block'
                float: 'right'
              href: proposal_url(next_proposal)
              'data-no-scroll': true
              "#{translator("engage.navigation.next_proposal", "next")} >"

          # Previous button
          if prev_proposal
            A
              'title': 'Next proposal'
              style:
                display: 'inline-block'
                float: 'right'
                marginRight: if next_proposal then 10
              href: proposal_url(prev_proposal)
              'data-no-scroll': true
              "< #{translator("engage.navigation.previous_proposal", "prev")}"



      # Photo
      if customization('show_proposer_icon', "list/#{@proposal.cluster}")
        editor = proposal_editor(@proposal)
        width = Math.min(GUTTER(), 120)
        if editor
          Avatar
            key: editor
            user: editor
            img_size: 'original'
            style:
              position: 'absolute'
              #height: 225
              width: width
              top: 36
              maxWidth: width - (if width == 120 then 20 else 10)
              marginLeft: -width - (if width == 120 then 20 else 10)
              borderRadius: 0
              backgroundColor: 'transparent'

      # Cluster name
      DIV
        style:
          fontStyle: 'italic'
          visibility: if !@proposal.cluster then 'hidden'

        if permit('update proposal', @proposal) > 0
          INPUT 
            ref: 'cluster'
            name: 'cluster'
            pattern: '^.{3,}'
            defaultValue: @proposal.cluster
            'aria-label': 'Update the proposal category'
            style: 
              border: 'none'
              fontStyle: 'italic'
              fontSize: 16

            onBlur: => 
              @proposal.cluster = @refs.cluster.getDOMNode().value
              save @proposal


        else 
          @proposal.cluster or '-'


  componentDidUpdate : -> @typeset()
  componentDidMount : -> @typeset()

  typeset : -> 
    subdomain = fetch('/subdomain')

    if subdomain.name == 'RANDOM2015' && $('#proposal_name').find('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,"proposal_name"])

