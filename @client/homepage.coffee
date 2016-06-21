require './shared'
require './customizations'
require './dock'
require './histogram'
require './permissions'
require './watch_star'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './bubblemouth'
require './filter'

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

    DIV null,

      customization('Homepage')()

      # if customization('tawkspace')
      #   IFRAME 
      #     src: customization('tawkspace')
      #     height: 500
      #     width: CONTENT_WIDTH()


#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into clusters. 


window.proposal_editor = (proposal) ->
  editors = (e for e in proposal.roles.editor when e != '*')
  editor = editors.length > 0 and editors[0]

  return editor != '-' and editor



cluster_keys = ['archived', 'label', 'description', 'homie_histo_title',
                'show_proposer_icon', 'slider_handle', 'slider_pole_labels', 
                'slider_regions', 'slider_ticks', 'discussion', 'show_score', 
                'uncollapseable', 'cluster_header', 'homepage_label', 
                'cluster_filters', 'proposal_style', 'one_line_desc']

cluster_options = (key) -> 
  options = {}
  for k in cluster_keys
    options[k] = customization k, key 

  options.proposal_style = _.extend 
    fontWeight: 500
  , (customization('proposal_style', key))
  options


window.cluster_styles = ->

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
    marginBottom: 30
    fontWeight: 600
  _.extend(first_header, first_column)

  secnd_header =
    fontSize: 36
    fontWeight: 600
    position: 'relative'
    whiteSpace: 'nowrap'
  _.extend(secnd_header, secnd_column)

  [first_column, secnd_column, first_header, secnd_header]



window.get_clusters = -> 
  proposals = fetch('/proposals')
  # make sure that proposals w/o a cluster use the default cluster
  clusters = {}
  for c in (proposals.clusters or [])
    if c.name 
      clusters[c.name] = {}
      for own k,v of c
        clusters[c.name][k] = v
    else 
      unnamed = {}
      for own k,v of c 
        unnamed[k] = v 

    if unnamed?
      if clusters[default_cluster_name]
        c = clusters[default_cluster_name]
        c.proposals = c.proposals.concat unnamed.proposals
      else 
        unnamed.name = default_cluster_name
        clusters[default_cluster_name] = unnamed

  # move archived clusters to the back 
  clusters = _.values clusters
  c = []
  a = []
  for cluster in clusters 
    options = cluster_options "cluster/#{cluster.name}"
    if !options.archived
      c.push cluster 
    else 
      a.push cluster 
  for cluster in a 
    c.push cluster 
  [c,a]



ProposalsLoading = ReactiveComponent
  displayName: 'ProposalLoading'

  render: ->  
    if !@local.cnt?
      @local.cnt = 0

    negative = Math.floor((@local.cnt / 284)) % 2 == 1

    DIV 
      style: 
        width: HOMEPAGE_WIDTH()
        margin: 'auto'
        padding: '60px'
        textAlign: 'center'
        fontStyle: 'italic'
        #color: logo_red
        fontSize: 24

      DIV 
        style: 
          position: 'relative'
          top: 6
          left: 3
        
        drawLogo 50, logo_red, logo_red, false, true, logo_red, (if negative then 284 - @local.cnt % 284 else @local.cnt % 284), false


      "Loading proposals...there is much to consider!"

  componentWillMount: -> 
    @int = setInterval => 
      @local.cnt += 1 
      save @local 
    , 10

  componentWillUnmount: -> 
    clearInterval @int 


window.TagHomepage = ReactiveComponent
  displayName: 'TagHomepage'

  render: -> 
    subdomain = fetch('/subdomain')
    current_user = fetch('/current_user')

    show_all = fetch('show_all_proposals')

    all = fetch('/proposals')
    if !all.clusters
      return ProposalsLoading()   

    proposals = []
    [clusters, archived] = get_clusters()
    hues = getNiceRandomHues clusters.length
    colors = {}
    for cluster, idx in clusters
      proposals = proposals.concat cluster.proposals
      colors[cluster.name] = hues[idx]

    proposals = sorted_proposals(proposals)

    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

    DIV null,

      DIV
        className: 'simplehomepage'
        style: 
          fontSize: 22
          margin: '45px auto'
          width: HOMEPAGE_WIDTH()
          position: 'relative'

        STYLE null,
          '''a.proposal:hover {border-bottom: 1px solid grey}'''

        ProposalFilter
          style: 
            width: first_column.width
            marginBottom: 20
            paddingLeft: if customization('show_proposer_icon') then 68
            display: 'inline-block'
            verticalAlign: 'top'


        DIV null, 
          for proposal,idx in proposals
            continue if idx > 20 && !show_all.show_all

            DIV 
              key: "collapsed#{proposal.key}"

              CollapsedProposal 
                key: "collapsed#{proposal.key}"
                proposal: proposal
                options: cluster_options("cluster/proposals")
                show_category: true
                category_color: hsv2rgb(colors[proposal.cluster], .7, .8)

        if !show_all.show_all && proposals.length > 20 
          DIV
            style:
              backgroundColor: '#f9f9f9'
              width: HOMEPAGE_WIDTH()
              #position: 'absolute'
              #bottom: 0
              textDecoration: 'underline'
              cursor: 'pointer'
              paddingTop: 10
              paddingBottom: 10
              fontWeight: 600
              textAlign: 'center'
              marginTop: 40

            onMouseDown: => 
              show_all.show_all = true
              save(show_all)
            'Show all proposals'




window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    subdomain = fetch('/subdomain')

    cluster_filters = fetch 'cluster_filters'
    if subdomain.name == 'dao' && cluster_filters.clusters == '*'
      return TagHomepage()

      
    proposals = fetch('/proposals')
    current_user = fetch('/current_user')

    if !proposals.clusters 
      return ProposalsLoading()   

    [clusters, archived] = get_clusters()

    # collapse by default archived clusters
    collapsed = fetch 'collapsed'
    if !collapsed.clusters?
      collapsed.clusters = {}
      for cluster in archived 
        collapsed.clusters["cluster/#{cluster.name}"] = 1
      save collapsed


    DIV null,

      DIV
        className: 'simplehomepage'
        style: 
          fontSize: 22
          margin: '45px auto'
          width: HOMEPAGE_WIDTH()
          position: 'relative'

        STYLE null,
          '''a.proposal:hover {border-bottom: 1px solid grey}'''

        if customization('proposal_filters')
          [first_column, secnd_column, first_header, secnd_header] = cluster_styles()
          ProposalFilter
            style: 
              width: first_column.width
              marginBottom: 20
              paddingLeft: if customization('show_proposer_icon') then 68
              display: 'inline-block'
              verticalAlign: 'top'

        if customization('opinion_filters')
          [first_column, secnd_column, first_header, secnd_header] = cluster_styles()
          hala = subdomain.name == 'HALA'

          OpinionFilter
            style: 
              width: if !hala then secnd_column.width
              marginBottom: 20
              marginLeft: if !hala then secnd_column.marginLeft
              display: if !hala then 'inline-block'
              verticalAlign: 'top'
              textAlign: if !hala then 'center' else 'right'

        # List all clusters
        for cluster, index in clusters or []
          cluster_key = "cluster/#{cluster.name}"
          options = cluster_options cluster_key

          fails_filter = cluster_filters.filter? && (cluster_filters.clusters != '*' && !(cluster.name in cluster_filters.clusters) )
          if fails_filter && ('*' in cluster_filters.clusters)
            in_others = []
            for filter, clusters of customization('cluster_filters')
              in_others = in_others.concat clusters 

            fails_filter &&= cluster.name in in_others


          if fails_filter
            SPAN null 
          else 

            Cluster
              key: cluster_key
              cluster: cluster 
              options: options 
              index: index


        if permit('create proposal') > 0 && customization('show_new_proposal_button') && subdomain.name not in ['bitcoin', 'bitcoinfoundation'] 
          A 
            style: 
              color: logo_red
              marginTop: 35
              display: 'inline-block'
              borderBottom: "1px solid #{logo_red}"

            href: '/proposal/new'
            t('Create new proposal')

  typeset : -> 
    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && $('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,".proposal_homepage_name"])

  componentDidMount : -> @typeset()
  componentDidUpdate : -> @typeset()

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


window.NewProposal = ReactiveComponent
  displayName: 'NewProposal'


  render : -> 
    cluster_name = @props.cluster_name 
    cluster_key = "cluster/#{cluster_name}"

    cluster_state = fetch(@props.local)


    return SPAN null if cluster_name == 'Blocksize Survey'

    cluster_name = cluster_name or default_cluster_name
    current_user = fetch '/current_user'

    adding = cluster_state.adding_new_proposal == cluster_name 
    cluster_slug = slugify(cluster_name)

    permitted = permit('create proposal')
    needs_to_login = permitted == Permission.NOT_LOGGED_IN
    permitted = permitted > 0

    icons = @props.icons

    return SPAN null if !permitted && !needs_to_login

    DIV null,


      if !adding 

        SPAN 
          style: _.extend @props.label_style,
            cursor: 'pointer'

          onClick: (e) => 
            if permitted
              cluster_state.adding_new_proposal = cluster_name; save(cluster_state)
            else 
              e.stopPropagation()
              reset_key 'auth', {form: 'login', goal: '', ask_questions: true}
          
          if permitted
            t("add new")
          else 
            t("login_to_add_new")

      else 
        [first_column, secnd_column, first_header, secnd_header] = cluster_styles()
        w = first_column.width - 50 + (if icons then -18 else 0)
        
        DIV null, 
          if customization('proposal_tips')
            @drawTips()

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
                border: "1px solid #ccc"
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
                      cluster_state.adding_new_proposal = null 
                      save cluster_state
                    else
                      @local.errors = proposal.errors
                      save @local

                t('Done')

              SPAN 
                style: 
                  color: '#888'
                  cursor: 'pointer'
                onClick: => cluster_state.adding_new_proposal = null; save(cluster_state)

                t('cancel')



  drawTips : -> 
    # guidelines/tips for good points
    mobile = browser.is_mobile

    guidelines_w = if mobile then 'auto' else 330
    guidelines_h = 300

    tips = customization('proposal_tips')

    DIV 
      style:
        position: if mobile then 'relative' else 'absolute'
        left: 512
        width: guidelines_w
        color: focus_blue
        zIndex: 1
        marginBottom: if mobile then 20
        backgroundColor: if mobile then 'rgba(255,255,255,.85)'
        fontSize: 14


      if !mobile
        SVG
          width: guidelines_w + 28
          height: guidelines_h
          viewBox: "-4 0 #{guidelines_w+20 + 9} #{guidelines_h}"
          style: css.crossbrowserify
            position: 'absolute'
            transform: 'scaleX(-1)'
            left: -20

          DEFS null,
            svg.dropShadow 
              id: "guidelines-shadow"
              dx: '0'
              dy: '2'
              stdDeviation: "3"
              opacity: .5

          PATH
            stroke: focus_blue #'#ccc'
            strokeWidth: 1
            fill: "#FFF"
            filter: 'url(#guidelines-shadow)'

            d: """
                M#{guidelines_w},33
                L#{guidelines_w},0
                L1,0
                L1,#{guidelines_h} 
                L#{guidelines_w},#{guidelines_h} 
                L#{guidelines_w},58
                L#{guidelines_w + 20},48
                L#{guidelines_w},33 
                Z
               """
      DIV 
        style: 
          padding: if !mobile then '14px 18px'
          position: 'relative'
          marginLeft: 5

        SPAN 
          style: 
            fontWeight: 600
            fontSize: if PORTRAIT_MOBILE() then 70 else if LANDSCAPE_MOBILE() then 36
          "Add new"

        UL 
          style: 
            listStylePosition: 'outside'
            marginLeft: 16
            marginTop: 5

          do ->
            tips = customization('proposal_tips')

            for tip in tips
              LI 
                style: 
                  paddingBottom: 3
                  fontSize: if PORTRAIT_MOBILE() then 24 else if LANDSCAPE_MOBILE() then 14
                tip  





window.ClusterFilter = ReactiveComponent
  displayName: 'ClusterFilter'

  render: -> 
    filters = ([k,v] for k,v of customization('cluster_filters'))
    filters.unshift ["Show all", '*']

    cluster_filters = fetch 'cluster_filters'
    if !cluster_filters.filter?
      cluster_filters.filter = customization('cluster_filter_default') or 'Show all'
      for [filter, clusters] in filters 
        if filter == cluster_filters.filter
          cluster_filters.clusters = clusters
          break 
      save cluster_filters


    DIV 
      style: 
        fontSize: 19
        fontWeight: 600
        color: 'white'
        width: '100%'
        zIndex: 2
        position: 'relative'
        top: 2
        marginTop: 20

      DIV 
        style: 
          width: 900 #HOMEPAGE_WIDTH()
          margin: 'auto'
          textAlign: 'center'

        for [filter, clusters], idx in filters 
          do (filter, clusters) =>
            current = cluster_filters.filter == filter 
            hovering = @local.hovering == filter
            SPAN 
              style: 
                #borderLeft: if idx == 0 then '1px solid #CACACA'
                #borderRight: '1px solid #CACACA'
                padding: '10px 30px 4px 30px'
                display: 'inline-block'
                cursor: 'pointer'
                color: if current then 'black' else if hovering then '#F8E71C'
                backgroundColor: if current then 'white'
                position: 'relative'
                borderRadius: '16px 16px 0 0'
                borderLeft: if current then "2px solid #F8E71C"
                borderTop: if current then "2px solid #F8E71C"
                borderRight: if current then "2px solid #F8E71C"

              onMouseEnter: => 
                if cluster_filters.filter != filter 
                  @local.hovering = filter 
                  save @local 
              onMouseLeave: => 
                @local.hovering = null 
                save @local
              onClick: => 
                cluster_filters.filter = filter 
                cluster_filters.clusters = clusters
                save cluster_filters

              filter

              # if current
              #   tw = 45
              #   th = 10
              #   SPAN 
              #     style: cssTriangle 'bottom', '#FF3834', tw, th,
              #       position: 'absolute'
              #       left: -tw / 2
              #       marginLeft: '50%'
              #       bottom: -th + 1
              #       width: tw
              #       height: th
              #       display: 'inline-block'




          # if clusters == '*'




Cluster = ReactiveComponent
  displayName: 'Cluster'


  # cluster of proposals
  render: -> 
    options = @props.options
    cluster = @props.cluster

    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    # subscribe to a key that will alert us to when sort order has changed
    fetch('homepage_you_updated_proposal')

    collapsed = fetch 'collapsed'
    is_collapsed = collapsed.clusters[@props.key]

    proposals = sorted_proposals(cluster.proposals)
    return SPAN null if !proposals || (proposals.length == 0 && !cluster.always_shown)

    DIV
      key: cluster.name
      id: if cluster.name && cluster.name then cluster.name.toLowerCase()
      style: 
        paddingBottom: if !is_collapsed then 45
        position: 'relative'

      @drawClusterHeading cluster, options, is_collapsed

      if !is_collapsed
        DIV null, 
          for proposal,idx in proposals
            DIV 
              key: "collapsed#{proposal.key}"

              CollapsedProposal 
                key: "collapsed#{proposal.key}"
                proposal: proposal
                options: options 

              @drawThreshold(subdomain, cluster, idx)

          if customization('show_new_proposal_button')
            NewProposal 
              cluster_name: cluster.name
              local: @local.key
              label_style: 
                marginLeft: if options.show_proposer_icon then 50 + 18
                borderBottom: "1px solid #{logo_red}"
                color: logo_red
              icons: options.show_proposer_icon



  drawClusterHeading : (cluster, options, is_collapsed) -> 
    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()


    cluster_key = "cluster/#{cluster.name}"

    icons = options.show_proposer_icon
    collapsed = fetch 'collapsed'

    subdomain = fetch '/subdomain'

    tw = if is_collapsed then 15 else 20
    th = if is_collapsed then 20 else 15

    DIV null,
      if options.label || options.description
        DIV 
          style: 
            width: CONTENT_WIDTH()
            marginLeft: if icons then 70


          if options.label
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

              options.description()

      # Header of cluster

      if options.cluster_header
        options.cluster_header()
      else 

        DIV 
          style: 
            position: 'relative'
          H1
            style: _.extend {}, first_header, 
              paddingLeft: if icons then 68 else 0, 
              position: 'relative'
              cursor: if !options.uncollapseable then 'pointer'

            onClick: -> 
              if !options.uncollapseable
                if collapsed.clusters[cluster_key]
                  delete collapsed.clusters[cluster_key]
                else 
                  collapsed.clusters[cluster_key] = 1 
                save collapsed


            options.homepage_label || cluster.name || default_cluster_name

            if !options.uncollapseable
              SPAN 
                style: cssTriangle (if is_collapsed then 'right' else 'bottom'), 'black', tw, th,
                  position: 'absolute'
                  left: -tw - 20 + (if icons then 68 else 0)
                  bottom: 14
                  width: tw
                  height: th
                  display: 'inline-block'

            if subdomain.name == 'RANDOM2015'
              " (#{cluster.proposals.length})"

            if options.one_line_desc
              DIV 
                style: 
                  position: 'absolute'
                  bottom: -12
                  color: '#444'
                  fontSize: 14
                  fontWeight: 400
                options.one_line_desc

          if !is_collapsed
            H1
              style: secnd_header
              # SPAN
              #   style:
              #     position: 'absolute'
              #     bottom: -43
              #     fontSize: 21
              #     color: '#444'
              #     fontWeight: 300
              #   customization("slider_pole_labels.individual.oppose", cluster_key)
              # SPAN
              #   style:
              #     position: 'absolute'
              #     bottom: -43
              #     fontSize: 21
              #     color: '#444'
              #     right: 0
              #     fontWeight: 300
              #   customization("slider_pole_labels.individual.support", cluster_key)
              SPAN 
                style: 
                  position: 'relative'
                  marginLeft: -(widthWhenRendered(options.homie_histo_title, 
                               {fontSize: 36, fontWeight: 600}) - secnd_column.width)/2
                options.homie_histo_title





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

  storeSortOrder: -> 
    p = (p.key for p in sorted_proposals(@props.cluster.proposals))
    c = fetch("cluster-#{slugify(@props.cluster.name)}/sort_order")
    order = JSON.stringify(p)
    if order != c.sort_order
      c.sort_order = order 
      save c

  componentDidMount: -> @storeSortOrder()
  componentDidUpdate: -> @storeSortOrder()


pad = (num, len) -> 
  str = num #.toString()
  dec = str.split('.')
  i = 0 
  while i < len - dec[0].toString().length
    dec[0] = "0" + dec[0]
    i += 1


  dec[0] + if dec.length > 0 then '.' + dec[1] else ''

NewActivity = ReactiveComponent
  displayName: 'NewActivity'

  render: -> 
    proposal = @props.proposal 
    unread = hasUnreadNotifications(proposal)

    if current_user?.logged_in && unread
      A
        title: 'New activity'
        href: proposal_url(proposal)
        style: 
          position: 'absolute'
          left: -66
          top: 11
          width: 8
          height: 8
          textAlign: 'center'
          display: 'inline-block'
          cursor: 'pointer'
          backgroundColor: '#aaa'
          color: 'white'
          fontSize: 14
          borderRadius: '50%'
          padding: 2
          fontWeight: 600

        # I 
        #   className: 'fa-bell fa'
    else 
      SPAN null



window.CollapsedProposal = ReactiveComponent
  displayName: 'CollapsedProposal'

  render : ->
    proposal = fetch @props.proposal
    options = @props.options
    icons = options.show_proposer_icon

    # we want to update if the sort order changes so that we can 
    # resolve @local.keep_in_view
    fetch("cluster-#{slugify(proposal.cluster or default_cluster_name)}/sort_order")

    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

    your_opinion = fetch proposal.your_opinion
    if your_opinion?.published
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    draw_slider = can_opine > 0 || your_opinion?.published

    opinions = opinionsForProposal(proposal)

    if options.show_score 
      score = 0
      filter_out = fetch 'filtered'
      opinions = (o for o in opinions when !filter_out.users?[o.user])

      for o in opinions 
        score += o.stance
      avg = score / opinions.length
      negative = score < 0
      score *= -1 if negative

      score = pad score.toFixed(1),2

      score_w = widthWhenRendered "#{score}", {fontSize: 18, fontWeight: 600}


    if draw_slider
      slider = fetch "homepage_slider#{proposal.key}"
    else 
      slider = null 

    if slider && your_opinion && slider.value != your_opinion.stance && !slider.has_moved 
      # Update the slider value when the server gets back to us
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider

    # sub_creation = new Date(fetch('/subdomain').created_at).getTime()
    # creation = new Date(proposal.created_at).getTime()
    # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

    DIV
      key: proposal.key
      id: proposal.slug.replace('-', '_')
      style:
        minHeight: 70
        position: 'relative'
        marginBottom: if customization('slider_ticks', proposal) then 15 else 15
      onMouseEnter: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onMouseLeave: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local

      DIV style: first_column,

        NewActivity
          proposal: proposal 

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
          if editor 
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
                  # opacity: opacity
          else 
            SPAN 
              style: 
                height: 50
                width: 50
                display: 'inline-block'
                verticalAlign: 'top'
                border: "2px dashed #ddd"

        # Name of Proposal
        DIV
          style:
            display: 'inline-block'
            fontWeight: 400
            marginLeft: if icons then 18
            paddingBottom: 20
            width: first_column.width - 50 + (if icons then -18 else 0)
            marginTop: if icons then 0 #9
            # opacity: opacity
          A
            className: 'proposal proposal_homepage_name'
            style: options.proposal_style
              
            href: proposal_url(proposal)

            proposal.name

          DIV 
            style: 
              fontSize: 16
              color: "#999"
              fontStyle: 'italic'

            if customization('show_meta')
              SPAN 
                style: {}

                prettyDate(proposal.created_at)

                if !icons && (editor = proposal_editor(proposal)) && editor == proposal.user
                  SPAN 
                    style: {}

                    " by #{fetch(editor)?.name}"

                SPAN 
                  style: 
                    paddingRight: 16

            if @props.show_category && proposal.cluster
              cluster = proposal.cluster 
              if fetch('/subdomain').name == 'dao' && proposal.cluster == 'Proposals'
                cluster = 'Ideas'

              SPAN 
                style: 
                  #border: "1px solid #{@props.category_color}"
                  backgroundColor: @props.category_color
                  padding: '1px 2px'
                  color: 'white' #@props.category_color
                  fontStyle: 'normal'
                  fontSize: 12


                cluster


            if !proposal.active
              SPAN 
                style: {}

                t('closed')


      # Histogram for Proposal
      DIV 
        style: 
          display: 'inline-block' 
          position: 'relative'
        # A
        #   href: proposal_url(proposal)

        DIV
          style: secnd_column
                

          Histogram
            key: "histogram-#{proposal.slug}"
            proposal: proposal
            opinions: opinions
            width: secnd_column.width
            height: 50
            enable_selection: false
            draw_base: true
            draw_base_labels: if options['slider_ticks']? 
                                !options['slider_ticks'] 
                              else 
                                true


          Slider 
            base_height: 0
            draw_handle: !!(draw_slider && ( \
                         @local.hover_proposal == proposal.key || browser.is_mobile))
            key: "homepage_slider#{proposal.key}"
            width: secnd_column.width
            polarized: true
            regions: options.slider_regions
            draw_ticks: options['slider_ticks']
            respond_to_click: false
            base_color: 'transparent'
            handle: slider_handle.triangley
            handle_height: 18
            handle_width: 21
            offset: true
            handle_props:
              use_face: false
              
            onMouseUpCallback: (e) =>
              # We save the slider's position to the server only on mouse-up.
              # This way you can drag it with good performance.
              if your_opinion.stance != slider.value

                # save distance from top that the proposal is at, so we can 
                # maintain that position after the save potentially triggers 
                # a re-sort. 
                prev_offset = @getDOMNode().offsetTop
                prev_scroll = window.scrollY

                your_opinion.stance = slider.value
                your_opinion.published = true
                save your_opinion
                window.writeToLog 
                  what: 'move slider'
                  details: {proposal: proposal.key, stance: slider.value}
                @local.slid = 1000

                update = fetch('homepage_you_updated_proposal')
                update.dummy = !update.dummy
                save update

                @local.keep_in_view = 
                  offset: prev_offset
                  scroll: prev_scroll

                scroll_handle = => 
                  @local.keep_in_view = null 
                  window.removeEventListener 'scroll', scroll_handle

                window.addEventListener 'scroll', scroll_handle


              mouse_over_element = closest e.target, (node) => 
                node == @getDOMNode()

              if @local.hover_proposal == proposal.key && !mouse_over_element
                @local.hover_proposal = null 
                save @local
      
      # little score feedback
      if options.show_score
        DIV 
          ref: 'score'
          style: 
            position: 'absolute'
            right: -50 - score_w
            top: 10
          onMouseEnter: => 
            if opinions.length > 0
              tooltip = fetch 'tooltip'
              tooltip.coords = $(@refs.score.getDOMNode()).offset()
              tooltip.tip = "#{opinions.length} opinions. Average score = #{Math.round(avg * 100) / 100} on a -1 to 1 scale."
              save tooltip

          onMouseLeave: => 
            tooltip = fetch 'tooltip'
            tooltip.coords = null
            save tooltip

          SPAN 
            style: 
              color: '#999'
              fontSize: 18
              fontWeight: 600
              cursor: 'pointer'

            if negative
              '–'
            score

          if @local.hover_score
            DIV
              style: 
                position: 'absolute'
                backgroundColor: 'white'
                padding: "4px 10px"
                zIndex: 10
                boxShadow: '0 1px 2px rgba(0,0,0,.3)'
                fontSize: 16
                right: 0
                bottom: 30
                width: 200

  componentDidUpdate: -> 
    if @local.keep_in_view
      prev_scroll = @local.keep_in_view.scroll
      prev_offset = @local.keep_in_view.offset

      target = prev_scroll + @getDOMNode().offsetTop - prev_offset
      if window.scrollTo && window.scrollY != target
        window.scrollTo(0, target)
        @local.keep_in_view = null

    if @local.slid && !@fading 
      @fading = true

      update_bg = => 
        if @local.slid <= 0
          @getDOMNode().style.backgroundColor = ''
          clearInterval int
          @fading = false
        else 
          @getDOMNode().style.backgroundColor = "rgba(253, 254, 216, #{@local.slid / 1000})"

      int = setInterval =>
        @local.slid -= 50
        update_bg() 
      , 50

      update_bg()


