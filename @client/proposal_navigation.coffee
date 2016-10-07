require './customizations'
require './shared'


##
# DefaultProposalNavigation
#
# A header that displays a prev/next proposal button & cluster name

window.DefaultProposalNavigation = ReactiveComponent
  displayName: 'ProposalNavigation'
  render : ->
    subdomain = fetch('/subdomain')

    all_proposals = fetch('/proposals') 

    mod = (n, m) -> ((n % m) + m) % m

    # Determine the next proposal
    next_proposal = prev_proposal = null
    if all_proposals.proposals  # In case /proposals isn't loaded

      all_proposals_flat = _.flatten (sorted_proposals(cluster.proposals) for cluster in clustered_proposals())

      for proposal, idx in all_proposals_flat
        if proposal == @proposal
          break

      next_idx = mod(idx + 1, all_proposals_flat.length)
      prev_idx = mod(idx - 1, all_proposals_flat.length)
      next_proposal = all_proposals_flat[next_idx]
      prev_proposal = all_proposals_flat[prev_idx]

    DIV
      style:
        margin: "30px auto 0 auto"
        width: HOMEPAGE_WIDTH()
        position: 'relative'

      DIV 
        style: 
          position: 'absolute'
          right: 0

        # Next button
        if next_proposal
          A
            style:
              display: 'inline-block'
              float: 'right'
            href: proposal_url(next_proposal)
            'data-no-scroll': true
            "#{t('next')} >"

        # Previous button
        if prev_proposal
          A
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

