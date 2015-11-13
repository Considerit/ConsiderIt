require './shared'
require './customizations'
require './dock'
require './histogram'
require './permissions'
require './watch_star'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './bubblemouth'

default_cluster_name = 'Proposals'

window.Homepage = ReactiveComponent
  displayName: 'Homepage'
  render: ->
    doc = fetch('document')
    subdomain = fetch('/subdomain')

    title = subdomain.app_title || subdomain.name
    if doc.title != title
      doc.title = title
      save doc

    customization('Homepage')()


#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into clusters. 


window.proposal_editor = (proposal) ->
  editors = (e for e in proposal.roles.editor when e != '*')
  editor = editors.length > 0 and editors[0]

  return editor != '-' and editor


window.sorted_proposals = (cluster) ->
  cluster_key = "cluster/#{cluster.name}"
  show_icon = customization('show_proposer_icon', cluster_key)
  proposal_support = customization("proposal_support")
  _.clone(cluster.proposals).sort (a,b) ->
    return proposal_support(b) - proposal_support(a)

cluster_styles = ->

  first_column =
    width: HOMEPAGE_WIDTH() * .6 - 50
    display: 'inline-block'
    verticalAlign: 'top'
    position: 'relative'

  secnd_column =
    width: HOMEPAGE_WIDTH() * .4
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

  [first_column, secnd_column, first_header, secnd_header]

window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    subdomain = fetch('/subdomain')
    proposals = fetch('/proposals')
    current_user = fetch('/current_user')

    line_height = '1.8em'

    # make sure that proposals w/o a cluster use the default cluster
    clusters = {}
    for c in proposals.clusters
      if c.name 
        clusters[c.name] = {}
        for own k,v of c
          clusters[c.name][k] = v
      else 
        unnamed = {}
        for own k,v of c 
          unnamed[k] = v 

    if unnamed 
      if clusters[default_cluster_name]
        c = clusters[default_cluster_name]
        c.proposals = c.proposals.concat unnamed.proposals
      else 
        unnamed.name = default_cluster_name
        clusters[default_cluster_name] = unnamed

    clusters = _.values clusters
    console.log (c.proposals for c in clusters)

    DIV
      className: 'simplehomepage'
      style: 
        fontSize: 22
        margin: 'auto'
        width: HOMEPAGE_WIDTH()
        marginTop: 10
        position: 'relative'

      STYLE null,
        '''a.proposal:hover {border-bottom: 1px solid grey}'''


      if permit('create proposal') > 0 && customization('show_new_proposal_button')
        A 
          style: 
            color: logo_red
            marginTop: 35
            display: 'inline-block'
            borderBottom: "1px solid #{logo_red}"

          href: '/proposal/new'
          t('Create new proposal')

      # List all clusters

      for cluster, index in clusters or []
        cluster_key = "cluster/#{cluster.name}"

        options =   
          archived: customization("archived", cluster_key)
          label: customization("label", cluster_key)
          description: customization("description", cluster_key)
          homie_histo_title: customization("homie_histo_title", cluster_key)
          show_proposer_icon: customization("show_proposer_icon", cluster_key)

        DIV 
          style: 
            position: 'relative'

          if current_user.logged_in && index == 0
            @drawWatchFilter()

          if options.archived && (!@local.show_cluster || !(cluster.name in @local.show_cluster))
            DIV
              style: margin: "45px 0"

              "#{options.label} "

              A 
                style: 
                  textDecoration: 'underline'
                onClick: do(cluster) => => 
                  @local.show_cluster ||= []
                  @local.show_cluster.push(cluster.name)
                  save(@local)
                'Show archive'
          else if cluster.proposals?.length > 0
            @drawCluster cluster, options

  typeset : -> 
    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && $('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,".proposal_homepage_name"])

  componentDidMount : -> @typeset()
  componentDidUpdate : -> @typeset()

  # cluster of proposals
  drawCluster: (cluster, options) -> 
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    DIV
      key: cluster.name
      id: if cluster.name && cluster.name then cluster.name.toLowerCase()
      style: margin: '45px 0'

      @drawClusterHeading cluster, options

      for proposal,idx in sorted_proposals(cluster)
        [@drawProposal proposal, options.show_proposer_icon

        @drawThreshold(subdomain, cluster, idx)

        ]

      if permit('create proposal') > 0 && customization('show_new_proposal_button')
        @drawAddNew cluster, options

  drawAddNew : (cluster, options) -> 
    cluster_name = cluster.name or default_cluster_name
    icons = options.show_proposer_icon
    current_user = fetch '/current_user'

    adding = @local.adding_new_proposal == cluster_name 
    cluster_slug = slugify(cluster_name)

    DIV null,


      if !adding 

        SPAN 
          style: 
            marginLeft: if icons then 50 + 18
            color: logo_red
            cursor: 'pointer'
            fontWeight: 500
          onClick: => @local.adding_new_proposal = cluster_name; save(@local)

          t("add new")

      else 
        [first_column, secnd_column, first_header, secnd_header] = cluster_styles()
        w = first_column.width - 50 + (if icons then -18 else 0)
        
        DIV null, 

          if icons
            editor = current_user.user
            # Person's icon
            Avatar
              key: editor
              user: editor
              style:
                height: 50
                width: 50
                borderRadius: 0
                backgroundColor: '#ddd'


          DIV 
            style: 
              marginLeft: if icons then 18 - 8
              display: 'inline-block'
            TEXTAREA 
              id:"#{cluster_slug}-name"
              name:'name'
              pattern:'^.{3,}'
              placeholder: t('proposal_summary_instr')
              required:'required'
              resize: 'none'
              style: 
                fontSize: 22
                width: w
                borderColor: '#ccc'
                outline: 'none'
                padding: '6px 8px'

            WysiwygEditor
              key:"description-new-proposal-#{cluster_slug}"
              placeholder: "Add #{t('details')} here"
              container_style: 
                padding: '6px 8px'
                border: '1px solid #ccc'

              style: 
                fontSize: 16
                width: w - 8 * 2
                marginBottom: 8
                minHeight: 120


            if @local.errors?.length > 0
              
              DIV
                style:
                  fontSize: 18
                  color: 'darkred'
                  backgroundColor: '#ffD8D8'
                  padding: 10
                  marginTop: 10
                for error in @local.errors
                  DIV null, 
                    I
                      className: 'fa fa-exclamation-circle'
                      style: {paddingRight: 9}

                    SPAN null, error

            DIV 
              style: 
                marginTop: 8

              SPAN 
                style: 
                  backgroundColor: focus_blue
                  color: 'white'
                  cursor: 'pointer'
                  borderRadius: 16
                  padding: '4px 16px'
                  display: 'inline-block'
                  marginRight: 12


                onClick: => 
                  name = $(@getDOMNode()).find("##{cluster_slug}-name").val()
                  description = fetch("description-new-proposal-#{cluster_slug}").html
                  slug = slugify(name)
                  active = true 
                  hide_on_homepage = false

                  proposal =
                    key : '/new/proposal'
                    name : name
                    description : description
                    cluster : cluster_name
                    slug : slug
                    active: active
                    hide_on_homepage: hide_on_homepage

                  InitializeProposalRoles(proposal)
                  
                  proposal.errors = []
                  @local.errors = []
                  save @local

                  save proposal, => 
                    if proposal.errors?.length == 0
                      @local.adding_new_proposal = null 
                    else
                      @local.errors = proposal.errors
                    save @local



                t('Done')

              SPAN 
                style: 
                  color: '#888'
                  cursor: 'pointer'
                onClick: => @local.adding_new_proposal = null; save(@local)

                t('cancel')

  drawClusterHeading : (cluster, options) -> 
    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

    cluster_key = "cluster/#{cluster.name}"

    DIV null,
      if options.label
        DIV 
          style: 
            width: CONTENT_WIDTH()
          H1
            style: 
              fontSize: 48
              fontWeight: 200
              
            options.label

          if options.description
            DIV                
              style:
                fontSize: 22
                fontWeight: 200
                marginBottom: 10

              options.description

      # Header of cluster
      H1
        style: first_header
        cluster.name || default_cluster_name

        if cluster.proposals.length > 10
          " (#{cluster.proposals.length})"
      H1
        style: secnd_header
        SPAN
          style:
            position: 'absolute'
            bottom: -43
            fontSize: 21
            color: '#444'
            fontWeight: 300
          customization("slider_pole_labels.individual.oppose", cluster_key)
        SPAN
          style:
            position: 'absolute'
            bottom: -43
            fontSize: 21
            color: '#444'
            right: 0
            fontWeight: 300
          customization("slider_pole_labels.individual.support", cluster_key)
        SPAN 
          style: 
            position: 'relative'
            marginLeft: -(widthWhenRendered(options.homie_histo_title, 
                         {fontSize: 36, fontWeight: 600}) - secnd_column.width)/2
          options.homie_histo_title

  drawProposal : (proposal, icons) ->
    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

    unread = hasUnreadNotifications(proposal)

    DIV
      key: proposal.key
      style:
        minHeight: 70

      DIV style: first_column,


        if current_user?.logged_in && unread
          A
            title: 'New activity'
            href: proposal_url(proposal)
            style: 
              position: 'absolute'
              left: -75
              top: 5
              width: 22
              height: 22
              textAlign: 'center'
              display: 'inline-block'
              cursor: 'pointer'
              backgroundColor: logo_red
              color: 'white'
              fontSize: 14
              borderRadius: '50%'
              padding: 2
              fontWeight: 600

            I 
              className: 'fa-bell fa'


        if current_user?.logged_in
          # ability to watch proposal
          
          WatchStar
            proposal: proposal
            size: 30
            style: 
              position: 'absolute'
              left: -40
              top: 5


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
            marginTop: if icons then 0 #9
          A
            className: 'proposal proposal_homepage_name'
            style: if not icons then {borderBottom: '1px solid grey'}
            href: proposal_url(proposal)
            proposal.name

          if !proposal.active
            DIV
              style: 
                fontSize: 14
                color: '#414141'
                fontWeight: 200
                marginTop: 5

              t('closed')


      # Histogram for Proposal
      A
        href: proposal_url(proposal)
        DIV
          style: secnd_column
          Histogram
            key: "histogram-#{proposal.slug}"
            proposal: proposal
            opinions: opinionsForProposal(proposal)
            width: secnd_column.width
            height: 50
            enable_selection: false
            draw_base: true    

  drawWatchFilter: -> 
    filter = fetch 'homepage_filter'

    DIV 
      id: 'watching_filter'
      style: 
        position: 'absolute'
        left: -87  
        top: 5
        border: "1px solid #bbb"
        opacity: if !filter.watched && !@local.hover_watch_filter then .3
        padding: '3px 10px'
        cursor: 'pointer'
        display: 'inline-block'
        backgroundColor: '#fafafa'
        borderRadius: 8

      onMouseEnter: => 
        @local.hover_watch_filter = true

        tooltip = fetch 'tooltip'
        tooltip.coords = $(@getDOMNode()).find('#watching_filter').offset()
        tooltip.tip = t('filter_to_watched')
        save tooltip
        save @local

      onMouseLeave: => 
        @local.hover_watch_filter = false
        save @local
        tooltip = fetch 'tooltip'
        tooltip.coords = null
        save tooltip

      onClick: => 
        filter.watched = !filter.watched
        save filter

      SPAN
        style: 
          fontSize: 16
          verticalAlign: 'text-bottom'
          color: '#666'
        "only "

      I 
        className: "fa fa-star"
        style: 
          color: logo_red
          verticalAlign: 'text-bottom'

          # width: 30
          # height: 30

  drawThreshold: (subdomain, cluster, idx) -> 

    cutoff = 28 
    if subdomain.name == 'ANUP2015'
      cutoff = 7

    if subdomain.name in ['ANUP2015', 'RANDOM2015'] && cluster.name == 'Under Review' && idx == cutoff
      DIV 
        style:
          borderTop: "4px solid green"
          borderBottom: "4px solid #{logo_red}"
          padding: "4px 0"
          textAlign: 'center'
          
          fontWeight: 600
          margin: "16px 0 32px 0"

        I
          style: 
            color: 'green'
            display: 'block'
          className: 'fa fa-thumbs-o-up'


        "Acceptance threshold for #{cutoff} papers"

        I
          style: 
            display: 'block'
            color: logo_red
          className: 'fa fa-thumbs-o-down'    

