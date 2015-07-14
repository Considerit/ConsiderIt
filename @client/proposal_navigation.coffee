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
    proposals = fetch('/proposals')
    show_proposer_icon = customization('show_proposer_icon', "cluster/#{@proposal.cluster}")

    mod = (n, m) -> ((n % m) + m) % m

    # Determine the next proposal
    next_proposal = prev_proposal = null
    if proposals.clusters  # In case /proposals isn't loaded
      curr_cluster = _.findWhere proposals.clusters, {name: @proposal.cluster}
      if curr_cluster?.proposals.length > 1
        proposals = sorted_proposals(curr_cluster)
        # Now find the current proposal in the cluster, and return the next one
        for proposal, index in proposals
          if @proposal == proposal
            break
        next_index = mod(index + 1, proposals.length)
        prev_index = mod(index - 1, proposals.length)
        next_proposal = proposals[next_index]
        prev_proposal = proposals[prev_index]

    DIV
      style:
        margin: "30px auto 0 auto"
        width: BODY_WIDTH()
        position: 'relative'

      # Previous button
      if prev_proposal
        A
          style:
            position: 'absolute'
            right: 74
          href: proposal_url(prev_proposal)
          'data-no-scroll': true
          '< Prev'


      # Next button
      if next_proposal
        A
          style:
            position: 'absolute'
            right: 0
          href: proposal_url(next_proposal)
          'data-no-scroll': true
          'Next >'

      # Photo
      if show_proposer_icon
        editor = proposal_editor(@proposal)
        if editor
          Avatar
            key: editor
            user: editor
            img_size: 'original'
            style:
              position: 'absolute'
              #height: 225
              width: 225
              marginLeft: -225 - 35
              borderRadius: 0
              backgroundColor: 'transparent'

      # Cluster name
      DIV
        style:
          fontStyle: 'italic'
          visibility: if !@proposal.cluster then 'hidden'

        @proposal.cluster or '-'


  componentDidUpdate : -> @typeset()
  componentDidMount : -> @typeset()

  typeset : -> 
    subdomain = fetch('/subdomain')

    if subdomain.name == 'RANDOM2015' && $('#proposal_name').find('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,"proposal_name"])



####
# A header that shows the proposal title with a drop 
# down menu for navigating to any other proposal. 
# Has a link to the homepage. 
#

window.ProposalNavigationWithMenu = ReactiveComponent
  displayName: 'ProposalNavigationWithMenu'

  render : ->
    subdomain = fetch('/subdomain')
    proposals = fetch('/proposals')

    # If navigation bar is enabled, then we'll use a really short proposal name in the heading.
    # Otherwise we'll display the full question. This split doesn't come from
    # deep thought. Right now we'll just show the nav bar if the proposal belongs to a group
    use_navigation_bar = @proposal.cluster && proposals

    if not use_navigation_bar
      heading_style =
        textAlign: 'center'
        backgroundColor: subdomain.branding.primary_color
        fontSize: 26
        padding: '4px 90px'
        width: '100%'
        color: 'white'
        zIndex: 999
        position: 'relative'

      return DIV 
        style: heading_style,
        SPAN null, @proposal.name
    
    # Now we know that we are drawing the navigation bar

    # Determine the next proposal
    if proposals.clusters  # In case /proposals isn't loaded
      curr_cluster = _.findWhere proposals.clusters, {name: @proposal.cluster}

    next_proposal =
      if curr_cluster?.proposals.length > 1
        # Now find the current proposal in the cluster, and return the next one
        for proposal, index in curr_cluster.proposals
          if @proposal == proposal
            break
        next_index = (index + 1) % curr_cluster.proposals.length
        curr_cluster.proposals[next_index]

    heading_height = 50
    DIV
      id: 'proposal_heading'
      
      style:
        height: heading_height
        backgroundColor: subdomain.branding.primary_color
        width: '100%'
        color: 'white'
        zIndex: 999
        position: 'relative'
        marginBottom: 20
      A
        href: '/'
        style: 
          position: 'absolute'
          display: 'inline-block'
          top: -8
          left: 12
          fontSize: 43
        '<' 

      SPAN
        style: 
          display: 'inline-block'
          fontSize: 18
          paddingTop: 12
          marginLeft: 70

        @proposal.cluster


      DIV 
        style: 
          position: 'relative'
          display: 'inline-block'        
          textAlign: 'left'
          backgroundColor: 'rgba(0,0,0,.1)'
          padding: '3px 15px'
          marginLeft: 20
          borderRadius: 6
          display: 'inline-block'
          cursor: 'pointer'

        onTouchEnd: (=> @local.dropped_down = !@local.dropped_down; save(@local))
        onMouseEnter: (=> @local.dropped_down = true; save(@local))
        onMouseLeave: (=> @local.dropped_down = false; save(@local))

        SPAN null,
          "#{if @proposal.designator && @proposal.category then "#{@proposal.category[0]}-#{@proposal.designator} " else ''}#{@proposal.name}" 
          I 
            className: 'fa fa-caret-down'
            style: 
              paddingLeft: 8
              #fontSize: 30
              position: 'relative'
              top: 2

        if @local.dropped_down
          DIV 
            style: 
              width: 500
              position: 'absolute'
              #top: 38
              paddingTop: 5

            DIV style: {backgroundColor: subdomain.branding.primary_color, borderRadius: '4px'},
              DIV style: {backgroundColor: 'rgba(0,0,0,.2)', padding: '14px 0', borderRadius: '4px'},

                if curr_cluster?.proposals.length > 1
                  DIV null,
                    TABLE className: 'current_cluster', style: {width: '100%'},
                      TBODY null,
                        for other_proposal in curr_cluster.proposals
                          TR 
                            onClick: do(other_proposal) => => loadPage(proposal_url(other_proposal))
                            key: "tr/#{other_proposal.slug}"
                            TD style: {textAlign: 'left', paddingLeft: 20},
                              A 
                                href: proposal_url(other_proposal)
                                style: 
                                  color: 'white'
                                  fontWeight: if other_proposal.key == @proposal.key then 700 else 400
                                  fontSize: 18                                        
                                other_proposal.name

                            TD style: {position: 'relative'},
                              if !other_proposal.your_opinion || !fetch(other_proposal.your_opinion).published
                                SPAN style: {fontWeight: 400, color: 'rgb(205,205,205)', fontSize: 21}, '?'
                              else
                                # make a small slider summary
                                opinion = fetch(other_proposal.your_opinion)
                                face_size = 20 # height/width of the summary slider bar
                                eye_style = { width: 2, height: 2, borderRadius: '50%', backgroundColor: subdomain.branding.primary_color, position: 'absolute', top: 6 }
                                mouth_style = {fontSize: 12, color: subdomain.branding.primary_color, left: face_size * .45, top: face_size * .28, position: 'absolute', transform: 'rotate(90deg)'}
                                css.crossbrowserify mouth_style
                                if isNeutralOpinion(fetch(other_proposal.your_opinion).stance)
                                  # confused!
                                  mouth = '|'
                                else if opinion.stance < 0
                                  # frown!
                                  mouth = '('
                                else
                                  # pleased!
                                  mouth = ')'

                                DIV 
                                  style: 
                                    borderBottom: "1px solid white"
                                    width: 100
                                    position: 'relative'
                                    top: 15

                                  DIV
                                    style: 
                                      borderRadius: '50%'
                                      backgroundColor: 'white'
                                      width: face_size
                                      height: face_size
                                      position: 'absolute'
                                      top: -face_size / 2
                                      marginLeft: -face_size / 2 
                                      left: "#{100 * (opinion.stance + 1.0) / 2.0}%"
                                    DIV style: _.extend {}, eye_style, {left: 6} # left eye
                                    DIV style: _.extend {}, eye_style, {left: face_size - 8} # right eye
                                    DIV style: mouth_style, mouth


                            TD style: {paddingRight: 20}

                    DIV className: 'separator', style: {borderBottom: '1px dotted #dedede', width: '85%', margin: '28px auto 12px auto'}

                DIV className: 'other_clusters',
                  for cluster in proposals.clusters
                    if @proposal.cluster != cluster.name && cluster.proposals.length > 0
                      do (cluster) =>
                        DIV 
                          className: 'another_cluster'
                          key: cluster
                          onMouseEnter: => @local.show_cluster = cluster.name; save(@local)
                          onMouseLeave: => @mouseLeaveOtherCluster(cluster.name)
                          style: {padding: '0 50px', width: '100%', position: 'relative'}

                          SPAN style: {float: 'left', fontSize: 18, fontWeight: 400},
                            cluster.name
                          I className: 'fa fa-caret-right', style: {float: 'right'}
                          DIV style: {clear: 'both'}

                          if @local.show_cluster == cluster.name
                            DIV style: {width: 300, zIndex: 99999, backgroundColor: subdomain.branding.primary_color, borderRadius: '4px', position: 'absolute', left: 458, top: -12},                                  
                              UL className: 'other_proposal_list', style: {backgroundColor: 'rgba(0,0,0,.2)', borderRadius: '4px', padding: '8px 0' },
                                for other_proposal in cluster.proposals
                                  LI style: {listStyle: 'none'}, key: "li/#{other_proposal.slug}",
                                    A 
                                      href: proposal_url(other_proposal)
                                      style:
                                        display: 'block'
                                        textAlign: 'left'
                                        padding: '2px 10px'
                                        color: 'white'
                                        fontSize: 18
                                        fontWeight: 400
                                      other_proposal.name

  mouseLeaveOtherCluster : (cluster) -> 
    if @local.show_cluster == cluster
      @local.show_cluster = null
      save(@local)

styles += """
.current_cluster tr:hover, .other_proposal_list li:hover {
  background-color: rgba(0, 0, 0, 0.1);
  cursor: pointer; }
"""