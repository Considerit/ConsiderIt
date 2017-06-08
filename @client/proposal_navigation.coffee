require './customizations'
require './shared'



window.get_next_proposals = (args) -> 
  relative_to = args.relative_to
  all_proposals = fetch '/proposals' 
  subdomain = fetch('/subdomain')
  mod = (n, m) -> ((n % m) + m) % m

  # Determine the next proposal
  if all_proposals.proposals?.length > 0  # In case /proposals isn't loaded
    next_proposals = []; prev_proposals = []
    clusters = clustered_proposals_with_tabs()        
    all_proposals_flat = _.flatten (sorted_proposals(cluster.proposals) for cluster in clusters)
    if subdomain.name == 'HALA' && fetch('homepage_tabs').filter == 'Draft zoning changes'
      hala = fetch('hala')
      hala.name ||= capitalize(relative_to.slug.split('--')[0].replace(/_/g, ' '))
      all_proposals_flat = (p for p in all_proposals_flat when p.name.toLowerCase().indexOf(hala.name.toLowerCase()) > -1)
    else if subdomain.name in ['cprs-network', 'engage-cprs']
      all_proposals_flat = []
    for proposal, idx in all_proposals_flat
      if proposal == relative_to
        break

    next_idx = mod(idx + 1, all_proposals_flat.length)
    prev_idx = mod(idx - 1, all_proposals_flat.length)

    for idx in [0..(args.count or all_proposals.proposals.length) - 1]
      break if !all_proposals_flat[ next_idx + idx ]
      next_proposals.push all_proposals_flat[ next_idx + idx ]

    for idx in [0..(args.count or all_proposals.proposals.length) - 1]
      break if prev_idx - idx < 0
      prev_proposals.push all_proposals_flat[ prev_idx - idx ]



    [prev_proposals, next_proposals]
  else 
    [[], []]


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
              "#{t('next')} >"

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
              "< #{t('prev')}"



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

