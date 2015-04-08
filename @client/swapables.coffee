############################
# SWAPABLE COMPONENTS
# Components that may be useful for more than one subdomain. Used to 
# tailor subdomain functionality. 
# 
# TODO: This abstraction is poor. Find better one. 

require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './bubblemouth'
require './customizations'
require './dock'
require './histogram'
require './permissions'
require './shared'


###########################
# Homepages
# 
# Available Homepages:
#   - SimpleHomepage
#   - LearnShareDecideHomepage
#

#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into clusters. 
#
# Customizations: 
#   cluster_options

proposal_support = (proposal) ->
  opinions = fetch('/page/' + proposal.slug).opinions

  if not opinions
    return null
  sum = 0
  for o in opinions
    sum += customization("opinion_value")(o)
  return sum


sorted_proposals = (cluster) ->
  options = customization("cluster_options.#{cluster.name}") || {}
  _.clone(cluster.proposals).sort((a,b) ->
    x_a = proposal_support(a) - 10000 + (if options.editor_icons \
                                         and proposal_editor(a) then 1 else 0)
    x_b = proposal_support(b) - 10000 + (if options.editor_icons \
                                         and proposal_editor(b) then 1 else 0)
    return x_b - x_a)

window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    subdomain = fetch('/subdomain')
    proposals = fetch('/proposals')
    line_height = '1.8em'

    DIV
      className: 'simplehomepage'
      style: 
        fontSize: 22
        margin: if !lefty then 'auto'
        width: if !lefty then 705

      STYLE null,
        '''a.proposal:hover {border-bottom: 1px solid grey}'''

      # List all clusters
      for cluster, index in proposals.clusters or []
        options = customization("cluster_options.#{cluster.name}") || {}

        if options.archived && (!@local.show_cluster || !(cluster.name in @local.show_cluster))
          DIV
            style: margin: '45px 0 45px 200px'

            "#{options.description} "

            A 
              style: 
                textDecoration: 'underline'
              onClick: do(cluster) => => 
                @local.show_cluster ||= []
                @local.show_cluster.push(cluster.name)
                save(@local)
              'Show archive'

        else if cluster.proposals?.length > 0
          first_column =
            width: 350
            marginLeft: if lefty then 200
            display: 'inline-block'
            verticalAlign: 'top'

          secnd_column =
            width: 300
            display: 'inline-block'
            verticalAlign: 'top'
            marginLeft: 50

          first_header =
            fontSize: 36
            marginBottom: 40
            fontWeight: 600
          _.extend(first_header, first_column)

          secnd_header =
            fontSize: 36
            marginBottom: 45
            fontWeight: 600
            position: 'relative'
            whiteSpace: 'nowrap'
          _.extend(secnd_header, secnd_column)

          #
          # Cluster of proposals
          DIV
            key: cluster.name
            style: margin: '45px 0'

            if options.description
              H1
                style: 
                  fontSize: 48
                  fontWeight: 200
                  marginLeft: 200
                options.description

            # Header of cluster
            H1
              style: first_header
              cluster.name || 'Proposals'
            H1
              style: secnd_header
              SPAN
                style:
                  position: 'absolute'
                  bottom: -43
                  fontSize: 21
                  color: '#444'
                  fontWeight: 300
                customization("slider_pole_labels.individual.oppose")
              SPAN
                style:
                  position: 'absolute'
                  bottom: -43
                  fontSize: 21
                  color: '#444'
                  right: 0
                  fontWeight: 300
                customization("slider_pole_labels.individual.support")
              SPAN 
                style: 
                  position: 'relative'
                  marginLeft: -(widthWhenRendered(options.homie_histo_title || 'Opinions', {fontSize: 36, fontWeight: 600}) - secnd_column.width)/2
                options.homie_histo_title || 'Opinions'

            for proposal in sorted_proposals(cluster)
              icons = options.editor_icons

              # Proposal
              DIV
                key: proposal.key
                style:
                  minHeight: 70

                DIV style: first_column,

                  if icons
                    editor = proposal_editor(proposal)

                    # Person's icon
                    A
                      href: proposal_url(proposal)
                      Avatar
                        key: editor
                        user: editor
                        style:
                          height: 50
                          width: 50
                          borderRadius: 0
                          backgroundColor: '#ddd'

                  # Name of Proposal
                  DIV
                    style:
                      display: 'inline-block'
                      fontWeight: 400
                      marginLeft: if icons then 18
                      paddingBottom: 20
                      width: first_column.width - 50 + (if icons then -18 else 0)
                      marginTop: if icons then 9
                    A
                      className: 'proposal'
                      style: if not icons then {borderBottom: '1px solid grey'}
                      href: proposal_url(proposal)
                      proposal.name

                # Histogram for Proposal
                A
                  href: proposal_url(proposal)
                  DIV
                    style: secnd_column
                    Histogram
                      key: "histogram-#{proposal.slug}"
                      opinions: opinionsForProposal(proposal)
                      width: 300
                      height: 50
                      enable_selection: false
                      draw_base: true



####
# LearnDecideShareHomepage
#
# A homepage where proposals are shown in a four column
# table.
#
# Proposals are divided into clusters. 
# 
# Customizations:
#
#  homepage_heading_columns
#    The labels of the four columns
#  cluster_options

window.LearnDecideShareHomepage = ReactiveComponent
  displayName: 'Homepage'

  render : ->
    subdomain = fetch('/subdomain')
    proposals = fetch('/proposals')

    homepage = fetch('/page/')
    
    # The "Welcome to the community!" people
    contributors = homepage.contributors.filter((u)-> !!fetch(u).avatar_file_name)
    contributors_without_avatar_count = homepage.contributors.filter((u)-> !fetch(u).avatar_file_name).length

    # Columns of the docking header for the proposal list.
    columns = customization('homepage_heading_columns') or [ 
                  {heading: 'Learn', details: 'about the issues'}, \
                  {heading: 'Decide', details: 'what you think'}, \
                  {heading: 'Share', details: 'your opinion'}, \
                  {heading: 'Join', details: 'the contributors'}]

    docking_header_height = 79

    DIV className: 'homepage',

      Dock
        container_selector: '.homepage'
        dock_on_zoomed_screens: false
        parent_key: @local.key

        DIV 
          style: 
            backgroundColor: subdomain.branding.primary_color
            color: 'white'
            height: docking_header_height
            minWidth: PAGE_WIDTH #minwidth is for when docking, position fixed mode

          TABLE style: {margin: 'auto', paddingLeft: 242},
            TBODY null,
              TR null,
                for col in columns
                  TD style: {display: 'inline-block', width: 250},
                    DIV 
                      style: 
                        fontWeight: 700
                        fontSize: 42
                        textAlign: 'center'
                      col.heading
                    DIV 
                      style: 
                        fontWeight: 300
                        fontSize: 18
                        textAlign: 'center'
                        position: 'relative'
                        top: -8
                      col.details

      DIV style: {marginTop: 30},
        if contributors.length > 0
          DIV 
            style: 
              width: PAGE_WIDTH
              position: 'relative'
              margin: 'auto'
            DIV 
              style:
                left: 1005
                position: 'absolute'
                width: 165
                textAlign: 'left'
                zIndex: 1

              for user in _(contributors).first(90)
                Avatar key: user, className: 'welcome_avatar', style: {height: 32, width: 32, margin: 1}
              if contributors_without_avatar_count > 0
                others = if contributors_without_avatar_count != 1 then 'others' else 'other'
                DIV style: {fontSize: 14, color: "#666"}, "...and #{contributors_without_avatar_count} #{others}"

        # Draw the proposal summaries
        for cluster, index in proposals.clusters or []
          options = customization("cluster_options.#{cluster.name}") || {}
          DIV null,
            if index == 1 and subdomain.name == 'livingvotersguide'
              customization('ZipcodeBox')()

            if cluster.proposals?.length > 0 
              TABLE
                style:
                  borderLeft: '0px solid rgb(191, 192, 194)'
                  margin: '20px auto'
                  position: 'relative'

                TBODY null,
                  TR null,
                    # Draw the cluster name off to the side
                    TH 
                      style: 
                        textAlign: 'right'
                        width: 115
                        padding: '8px 8px 8px 8px'
                        display: 'inline-block'
                        fontSize: 18
                        position: 'absolute'
                        left: -125
                        fontWeight: if browser.high_density_display then 300 else 400
                      cluster.name                

                  # Draw each proposal summary
                  for proposal in cluster.proposals
                    ProposalSummary
                      key: proposal.key
                      cluster: cluster.name
            
            # Cluster description
            if options.description 
              DIV
                style:
                  color: 'rgb(108,107,98)'
                  paddingLeft: 164
                  paddingTop: 12
                  margin: 'auto'
                  width: PAGE_WIDTH
                options.description

      if permit('create proposal') > 0
        # lazily styled & positioned...
        DIV style: {width: 871, margin: 'auto'}, 
          A 
            style: {color: '#888', textDecoration: 'underline', fontSize: 18, marginLeft: 30}
            href: '/proposal/new'
            'Create new proposal'

# Used by the LearnDecideShare homepage
window.ProposalSummary = ReactiveComponent
  displayName: 'ProposalSummary'

  render : ->
    subdomain = fetch('/subdomain')

    proposal = @data()
    your_opinion = fetch(proposal.your_opinion)
    
    hover_class = if @local.hovering_on == proposal.id then 'hovering' else ''

    link_hover_color = focus_blue
    cell_border = "1px solid #{if @local.hovering_on then link_hover_color else 'rgb(191, 192, 194)'}"
    TR 
      className: "proposal_summary " + hover_class
      style:
        height: ''
        padding: '0 30px'
        display: 'block'
        borderLeft: cell_border
        minHeight: 60
      onMouseEnter: => @local.hovering_on = true; save(@local)
      onMouseLeave: => @local.hovering_on = false; save(@local)

      TD 
        className: 'summary_name'
        style: 
          width: 320
          display: 'inline-block'
          fontSize: 18
          fontWeight: 500

        A 
          href: proposal_url(proposal)
          style: 
            color: "#{if @local.hovering_on then link_hover_color else ''}" 
            borderBottom: '1px solid #b1afa7'

          if subdomain.name == 'livingvotersguide' && proposal.category 
            "#{proposal.category[0]}-#{proposal.designator}: "
          proposal.name

      TD
        style: 
          borderLeft: cell_border
          borderRight: cell_border
          cursor: 'pointer'
          width: 170
          textAlign: 'center'
          display: 'inline-block'
          height: '100%'
          minHeight: 66

        onClick: => loadPage "/#{proposal.slug}"
        if !proposal.your_opinion || !your_opinion.published \
           || isNeutralOpinion(your_opinion.stance)
          style = {fontWeight: 400, color: 'rgb(158,158,158)', fontSize: 21}
          if @local.hovering_on
            style.color = 'black'
            style.fontWeight = 600
          SPAN style: style, '?'
        else if your_opinion.stance < 0 && !isNeutralOpinion(your_opinion.stance)
          SPAN style: {position: 'relative', left: 14},
            IMG 
              className: 'summary_opinion_marker'
              src: asset('no_x.svg')
              style: {width: 24, position: 'absolute', left: -28}
            SPAN style: {color: 'rgb(239,95,98)', fontSize: 18, fontWeight: 600}, 'No'
        else
          SPAN style: {position: 'relative', left: 14},
            IMG 
              className: 'summary_opinion_marker'
              src: asset('yes_check.svg')
              style: {width: 24, position: 'absolute', left: -28}

            SPAN style: {color: 'rgb(166,204,70)', fontSize: 18, fontWeight: 600}, 'Yes'

      TD
        className: 'summary_share'
        style: 
          cursor: 'pointer'
          width: 320
          display: 'inline-block'
          paddingLeft: 15
          marginTop: -4

        onClick: => loadPage proposal_url(proposal)
        if proposal.top_point
          mouth_style = 
            top: 5
            position: 'absolute'
            right: -COMMUNITY_POINT_MOUTH_WIDTH + 4
            transform: 'rotate(90deg)'

          DIV 
            className: 'top_point community_point pro'
            style : { width: 270, position: 'relative' }

            DIV className:'point_content',

              DIV 
                key: 'community_point_mouth'
                style: css.crossbrowserify mouth_style

                Bubblemouth 
                  apex_xfrac: 0
                  width: COMMUNITY_POINT_MOUTH_WIDTH
                  height: COMMUNITY_POINT_MOUTH_WIDTH
                  fill: "#f6f7f9", 
                  stroke: 'transparent', 
                  stroke_width: 0
                  box_shadow:
                    dx: '3'
                    dy: '0'
                    stdDeviation: "2"
                    opacity: .5



              DIV className:'point_nutshell', style: {fontSize: 15},
                "#{proposal.top_point.nutshell[0..30]}..."

###########################
# Homepage headers
window.DefaultHomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->
    subdomain = fetch '/subdomain'   

    masthead_style = 
      textAlign: 'center'
      backgroundColor: subdomain.branding.primary_color
      height: 45

    if subdomain.branding.masthead
      _.extend masthead_style, 
        height: 300
        backgroundPosition: 'center'
        backgroundSize: 'cover'
        backgroundImage: "url(#{subdomain.branding.masthead})"   
           
    DIV style: masthead_style,
      ProfileMenu()

      if subdomain.branding.masthead_header_text
        DIV style: {color: 'white', margin: 'auto', fontSize: 60, fontWeight: 700, position: 'relative', top: 50}, 
          if subdomain.external_project_url
            A href: "#{subdomain.external_project_url}", target: '_blank',
              subdomain.branding.masthead_header_text
          else
            subdomain.branding.masthead_header_text


window.DefaultProposalMasthead = ReactiveComponent
  displayName: 'DefaultProposalMasthead'

  render: ->
    subdomain = fetch '/subdomain'   

    masthead_style = 
      textAlign: 'center'
      backgroundColor: subdomain.branding.primary_color
      height: 50
           
    DIV style: masthead_style,
      ProfileMenu()

      if subdomain.branding.masthead_header_text
        DIV style: {color: 'white', margin: 'auto', fontSize: 60, fontWeight: 700, position: 'relative', top: 50}, 
          if subdomain.external_project_url
            A href: "#{subdomain.external_project_url}", target: '_blank',
              subdomain.branding.masthead_header_text
          else
            subdomain.branding.masthead_header_text



      if subdomain.branding.logo || subdomain.branding.masthead

        DIV 
          style: 
            width: BODY_WIDTH
            position: 'relative'
            margin: 'auto'

          DIV 
            style:
              position: 'absolute'
              left: 0
              padding: '2px 10px'
              backgroundColor: 'white'

            IMG 
              src: subdomain.branding.logo || subdomain.branding.masthead
              style: 
                height: 46


#########################
# Footers
#
window.DefaultFooter = ReactiveComponent
  displayName: 'Footer'
  render: ->
    subdomain = fetch '/subdomain'
    DIV
      style: 
        position: 'relative'
        padding: '2.5em 0 .5em 0'
        textAlign: 'center'
        margin: 'auto'
        marginLeft: if lefty then 20 + BODY_WIDTH / 2
        width: BODY_WIDTH

      A href: "#{subdomain.external_project_url}", target: '_blank', style: {display: 'inline-block', margin: 'auto'},
        if subdomain.branding.logo
          IMG src: "#{subdomain.branding.logo}", style: {width: 300}

      DIV style: {marginTop: 30, fontSize: '70%'},
        TechnologyByConsiderit()
        DIV style: {color: 'rgb(131,131,131)', marginTop: 5},
          'Bug to report? Want to use this technology in your organization? '
          A style: {textDecoration: 'none', fontWeight: 700}, href: "mailto:admin@consider.it", 'Email us'

window.TechnologyByConsiderit = ReactiveComponent
  displayName: 'TechnologyByConsiderit'
  render : -> 
    DIV style: {textAlign: 'left', color: 'rgb(131,131,131)', display: 'inline-block', fontSize: 20},
      "Technology by "
      A href: 'http://consider.it', style: {textDecoration: 'underline', color: '#B03B42', fontWeight: 600}, target: '_blank', 'Consider.it'


###########################
# Proposal headers
# 
# Available proposal headers:
#   - SimpleProposalHeading
#   - ProposalHeaderWithMenu
#

##
# SimpleProposalHeading
#
# A header that displays a prev/next proposal button & cluster name
#
# Customizations:
#  cluster_options
#  hide_home_button_in_proposal_header

window.SimpleProposalHeading = ReactiveComponent
  displayName: 'ProposalHeader'
  render : ->
    subdomain = fetch('/subdomain')
    proposals = fetch('/proposals')
    heading_fontsize = 45
    options = customization("cluster_options.#{@proposal.cluster}") || {}
    show_home_button = !customization('hide_home_button_in_proposal_header')

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
        paddingBottom: 15
        margin: if lefty then "30px 0 0 300px" else "30px auto 0 auto"
        width: BODY_WIDTH + 20
        position: 'relative'
        left: if !lefty then 10

      # Previous button
      if prev_proposal
        A
          style:
            position: 'absolute'
            right: 74
          href: proposal_url(prev_proposal)
          '< Prev'

      # Home button
      if show_home_button
        A
          href: '/'
          style: 
            position: 'absolute'
            right: 41

          I 
            className: 'fa fa-home'
            style: 
              fontSize: 20

      # Next button
      if next_proposal
        A
          style:
            position: 'absolute'
            right: if show_home_button then -23 else 0
          href: proposal_url(next_proposal)
          'Next >'

      # Photo
      if options.editor_icons
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

      # Proposal name
      DIV
        style:
          lineHeight: 1.2
          fontWeight: 700
          fontSize: heading_fontsize
        @proposal.name


####
# A header that shows the proposal title with a drop 
# down menu for navigating to any other proposal. 
# Has a link to the homepage. 
#

window.ProposalHeaderWithMenu = ReactiveComponent
  displayName: 'ProposalHeaderWithMenu'

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
        minWidth: PAGE_WIDTH # for width consistency when docking
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
        minWidth: PAGE_WIDTH # for width consistency when docking
        backgroundColor: subdomain.branding.primary_color
        textAlign: 'center'
        width: '100%'
        color: 'white'
        zIndex: 999
        position: 'relative'
      A
        href: '/'
        style: {position: 'absolute', display: 'inline-block', top: 10, left: 12},
        I className: 'fa fa-home', style: {fontSize: 28, color: 'white'}

      DIV
        style: 
          display: 'inline-block'
          position: 'absolute'
          left: 58
          fontSize: 18
          paddingTop: 12

        @proposal.cluster

      DIV
        # Set the width so we can align it perfectly with the proposal description text:
        style: 
          width: DESCRIPTION_WIDTH
          textAlign: 'left'
          margin: 'auto'
          marginLeft: if lefty then 300
          #marginRight: if lefty then 0

        DIV style: {width: CONTENT_WIDTH}, # ...but let the stuff inside be big
          DIV
            style:
              fontSize: 22
              fontWeight: 700
              position: 'relative'
              top: 4


            DIV 
              style: 
                backgroundColor: 'rgba(0,0,0,.2)'
                padding: '3px 15px'
                borderRadius: 6
                marginTop: 3
                display: 'inline-block'
                cursor: 'pointer'
              onMouseEnter: (=> @local.dropped_down = true; save(@local))
              onMouseLeave: (=> @local.dropped_down = false; save(@local))

              SPAN null,
                "#{if @proposal.designator && @proposal.category then "#{@proposal.category[0]}-#{@proposal.designator} " else ''}#{@proposal.name}" 
                I 
                  className: 'fa fa-caret-down'
                  style: 
                    paddingLeft: 8
                    fontSize: 30
                    position: 'relative'
                    top: 2

              if @local.dropped_down
                DIV 
                  style: 
                    width: 500
                    position: 'absolute'
                    top: 38
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


window.ProfileMenu = ReactiveComponent
  displayName: 'ProfileMenu'

  componentDidMount : -> @setBgColor()
  componentDidUpdate : -> @setBgColor()
  setBgColor : -> 
    cb = (is_light) => 
      if @local.light_background != is_light
        @local.light_background = is_light
        save @local

    is_light = isLightBackground @getDOMNode(), cb

    cb is_light

  render : -> 
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')
    loc = fetch('location') # should rerender on a location change because background
                            # color might change

    is_evaluator = subdomain.assessment_enabled && current_user.is_evaluator
    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    menu_options = [
      {href: '/edit_profile', label: 'Edit Profile'},
      {href: '/dashboard/email_notifications', label: 'Notifications'},
      if is_admin then {href: '/dashboard/import_data', label: 'Import Data'} else null,
      if is_admin then {href: '/dashboard/application', label: 'App Settings'} else null,
      if is_admin then {href: '/dashboard/roles', label: 'User Roles'} else null,
      if is_moderator then {href: '/dashboard/moderate', label: 'Moderate'} else null,
      if is_evaluator then {href: '/dashboard/assessment', label: 'Fact-check'} else null 
    ]

    menu_options = _.compact menu_options

    DIV
      id: 'user_nav'
      style:
        _.extend(
          position: 'absolute'
          right: 50
          top: 17,
          _.clone(@props.style))

      if current_user.logged_in
        SPAN
          className: 'profile_menu_wrap'
          style:
            position: 'relative'
          onMouseEnter: => @local.menu = true; save(@local)
          onMouseLeave: => @local.menu = false; save(@local)
          DIV 
            style: 
              display: if not @local.menu then 'none'
              position: 'absolute'
              marginTop: -8
              marginLeft: -8
              padding: 8
              paddingTop: 50
              paddingRight: 14
              backgroundColor: '#eee'
              left: -82
              textAlign: 'left'
              zIndex: 999999

            for option in menu_options
              A
                className: 'menu_link'
                href: option.href
                key: option.href
                option.label

            A 
              'data-action': 'logout'
              className: 'menu_link'
              onClick: @logout
              'Log out'

          SPAN 
            style: 
              color: if !@local.light_background then 'white'
              position: 'relative'
              zIndex: 9999999999
              backgroundColor: if !@local.menu then 'rgba(255,255,255, .1)'
              boxShadow: if !@local.menu then '0px 1px 1px rgba(0,0,0,.1)'
              borderRadius: 8
              padding: '3px 4px'

            Avatar 
              key: current_user.user
              hide_tooltip: true
              className: 'userbar_avatar'
              style: {height: 20, width: 20, marginRight: 7, marginTop: 1}
            I 
              className: 'fa fa-caret-down'
              style: 
                visibility: if @local.menu then 'hidden'
      else
        A
          'className': 'profile_anchor login'
          'data-action': 'login'
          onClick: (e) =>
            reset_key 'auth',
              form: 'login'

          style: 
            color: if !@local.light_background then 'white'
          'Log in'


  logout : -> 
    current_user = fetch('/current_user')
    current_user.logged_in = false
    current_user.trying_to = 'logout'

    auth = fetch 'auth'

    if auth.form && auth.form == 'edit profile'
      loadPage '/'

    reset_key auth

    save current_user, =>
      # We need to get a fresh your_opinion object
      # after logging out. 

      # TODO: the server should dirty keys on the client when the
      # current_user logs out
      arest.clear_matching_objects((key) -> key.match( /\/page\// ))


styles += """
.profile_navigation {
  text-align: right;
  width: 100%;
  padding: 20px 120px 0 0;
  font-size: 21px; }

.menu_link {
  position: relative;
  bottom: 8px;
  padding-left: 27px;
  display: block;
  color: #{focus_blue};
  white-space: nowrap; }

.menu_link:hover{ color: black; }

.profile_menu_wrap:hover .profile_anchor{ color: inherit; }
"""
