require './shared'
require './customizations'
require './permissions'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './filter'
require './browser_location'
require './collapsed_proposal'


window.Homepage = ReactiveComponent
  displayName: 'Homepage'
  render: ->
    doc = fetch('document')
    subdomain = fetch('/subdomain')

    return SPAN null if !subdomain.name

    title = subdomain.app_title || subdomain.name
    if doc.title != title
      doc.title = title
      save doc

    DIV 
      key: "homepage_#{subdomain.name}"
      role: 'main'

      SimpleHomepage()

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






window.TagHomepage = ReactiveComponent
  displayName: 'TagHomepage'

  render: -> 
    current_user = fetch('/current_user')

    show_all = fetch('show_all_proposals')

    users = fetch '/users'
    proposals = fetch('/proposals').proposals

    if !proposals || !users.users
      return ProposalsLoading()   

    clusters = get_all_clusters()

    hues = getNiceRandomHues clusters.length
    colors = {}
    for cluster, idx in clusters
      colors[cluster.name] = hues[idx]

    proposals = sorted_proposals(proposals)

    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()


    DIV
      id: 'simplehomepage'
      role: if customization('homepage_tabs') then "tabpanel"
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
          display: 'inline-block'
          verticalAlign: 'top'


      UL null, 
        for proposal,idx in proposals
          continue if idx > 20 && !show_all.show_all
          cluster = proposal.cluster or 'Proposals'

          CollapsedProposal 
            key: "collapsed#{proposal.key}"
            proposal: proposal
            show_category: true
            category_color: hsv2rgb(colors[cluster], .7, .8)

      if !show_all.show_all && proposals.length > 20 
        BUTTON
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
            border: 'none'

          onMouseDown: => 
            show_all.show_all = true
            save(show_all)
          'Show all proposals'




window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    subdomain = fetch('/subdomain')

    homepage_tabs = fetch 'homepage_tabs'
    if subdomain.name == 'dao' && homepage_tabs.clusters == '*'
      return TagHomepage()

    proposals = fetch('/proposals')
    current_user = fetch('/current_user')

    if !proposals.proposals 
      return ProposalsLoading()   

    clusters = clustered_proposals()

    # collapse by default archived clusters
    collapsed = fetch 'collapsed'
    if !collapsed.clusters?
      collapsed.clusters = {}
      for cluster in clusters when cluster.list_is_archived 
        collapsed.clusters[cluster.key] = 1
      save collapsed


    has_proposal_sort = customization('homepage_show_search_and_sort') && proposals.proposals.length > 10

    DIV
      id: 'simplehomepage'
      role: if customization('homepage_tabs') then "tabpanel"
      style: 
        fontSize: 22
        margin: '45px auto'
        width: HOMEPAGE_WIDTH()
        position: 'relative'

      STYLE null,
        '''a.proposal:hover {border-bottom: 1px solid grey}'''

      if has_proposal_sort
        [first_column, secnd_column, first_header, secnd_header] = cluster_styles()
        ProposalFilter
          style: 
            width: first_column.width
            marginBottom: 20
            display: 'inline-block'
            verticalAlign: 'top'

      if customization('opinion_filters')
        [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

        OpinionFilter
          style: 
            width: if has_proposal_sort then secnd_column.width
            marginBottom: 20
            marginLeft: if has_proposal_sort then secnd_column.marginLeft else 0
            display: if has_proposal_sort then 'inline-block'
            verticalAlign: 'top'
            textAlign: 'center' 

      # List all clusters
      for cluster, index in clusters or []
        cluster_key = "list/#{cluster.name}"

        fails_filter = homepage_tabs.filter? && (homepage_tabs.clusters != '*' && !(cluster.name in homepage_tabs.clusters) )
        if fails_filter && ('*' in homepage_tabs.clusters)
          in_others = []
          for filter, clusters of customization('homepage_tabs')
            in_others = in_others.concat clusters 

          fails_filter &&= cluster.name in in_others


        if fails_filter
          SPAN null 
        else 

          Cluster
            key: cluster_key
            cluster: cluster 
            index: index


      if permit('create proposal') > 0 && customization('homepage_show_new_proposal_button')
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



window.HomepageTabs = ReactiveComponent
  displayName: 'HomepageTabs'

  render: -> 
    filters = ([k,v] for k,v of customization('homepage_tabs'))
    filters.unshift ["Show all", '*']

    homepage_tabs = fetch 'homepage_tabs'
    if !homepage_tabs.filter?
      homepage_tabs.filter = customization('homepage_default_tab') or 'Show all'
      for [filter, clusters] in filters 
        if filter == homepage_tabs.filter
          homepage_tabs.clusters = clusters
          break 
      save homepage_tabs

    subdomain = fetch('/subdomain')

    DIV 
      style: 
        width: '100%'
        zIndex: 2
        position: 'relative'
        top: 2
        marginTop: 20

      UL 
        role: 'tablist'
        style: 
          width: 900 #HOMEPAGE_WIDTH()
          margin: 'auto'
          textAlign: 'center'
          listStyle: 'none'

        for [filter, clusters], idx in filters 
          do (filter, clusters) =>
            current = homepage_tabs.filter == filter 
            hovering = @local.hovering == filter


            tab_style = _.defaults {}, (@props.tab_style or {}),
              cursor: 'pointer'
              position: 'relative'
              display: 'inline-block'
              fontSize: 16
              fontWeight: 600        
              color: 'white'
              opacity: if hovering || current then 1 else .8

            if subdomain.name == 'dao'
              _.extend tab_style, 
                padding: '10px 30px 4px 30px'
                color: if current then 'black' else if hovering then '#F8E71C' else 'white'
                backgroundColor: if current then 'white'
                borderRadius: '16px 16px 0 0'
                borderLeft: if current then "2px solid #F8E71C"
                borderTop: if current then "2px solid #F8E71C"
                borderRight: if current then "2px solid #F8E71C"
            else if subdomain.name == 'bradywalkinshaw'
              _.extend tab_style, 
                padding: '10px 20px 4px 20px'
                backgroundColor: if current then 'white'
                color: if current then 'black' else if hovering then '#F8E71C' else 'white'
                borderRadius: '16px 16px 0 0'
            else 
              _.extend tab_style, 
                padding: '10px 20px 4px 20px'
                backgroundColor: if current then 'rgba(255,255,255,.2)'

            LI 
              tabIndex: 0
              role: 'tab'
              style: tab_style
              'aria-controls': 'simplehomepage'
              'aria-selected': current

              onMouseEnter: => 
                if homepage_tabs.filter != filter 
                  @local.hovering = filter 
                  save @local 
              onMouseLeave: => 
                @local.hovering = null 
                save @local
              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  e.currentTarget.click() 
                  e.preventDefault()
              onClick: => 
                homepage_tabs.filter = filter 
                homepage_tabs.clusters = clusters
                save homepage_tabs
                document.activeElement.blur()

              filter



Cluster = ReactiveComponent
  displayName: 'Cluster'


  # cluster of proposals
  render: -> 
    cluster = @props.cluster

    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    # subscribe to a key that will alert us to when sort order has changed
    fetch('homepage_you_updated_proposal')

    collapsed = fetch 'collapsed'
    is_collapsed = collapsed.clusters[@props.key]

    proposals = sorted_proposals(cluster.proposals)
    return SPAN null if !proposals || (proposals.length == 0 && !(cluster.name in customization('homepage_lists_to_always_show')))

    cluster_key = "list/#{cluster.name}"

    DIV
      key: cluster.name
      id: if cluster.name && cluster.name then cluster.name.toLowerCase()
      style: 
        paddingBottom: if !is_collapsed then 45
        position: 'relative'

      @drawClusterHeading cluster, is_collapsed

      if !is_collapsed
        UL null, 
          for proposal,idx in proposals

            CollapsedProposal 
              key: "collapsed#{proposal.key}"
              proposal: proposal

          if customization('list_show_new_button', cluster_key) || current_user.is_admin
            LI 
              key: "new#{cluster_key}"
              style: 
                margin: 0 
                padding: 0
                listStyle: 'none'

              NewProposal 
                cluster_name: cluster.name
                local: @local.key
                label_style: 
                  borderBottom: "1px solid #{logo_red}"
                  color: logo_red



  drawClusterHeading : (cluster, is_collapsed) -> 
    [first_column, secnd_column, first_header, secnd_header] = cluster_styles()


    cluster_key = "list/#{cluster.name}"

    collapsed = fetch 'collapsed'

    subdomain = fetch '/subdomain'

    tw = if is_collapsed then 15 else 20
    th = if is_collapsed then 20 else 15

    ListHeader = customization 'ListHeader', cluster_key
    list_one_line_desc = customization 'list_one_line_desc', cluster_key
    list_uncollapseable = customization 'list_uncollapseable', cluster_key
    list_items_title = customization 'list_items_title', cluster_key

    label = customization 'list_label', cluster_key
    description = customization 'list_description', cluster_key
    label_style = customization 'list_label_style', cluster_key
    description_style = customization 'list_description_style', cluster_key


    DIV null,
      if label || description
        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            marginBottom: 16


          if label
            H1
              style: _.defaults {}, (label_style or {}),
                fontSize: 42
                fontWeight: 300
                marginBottom: 5
              label

          if description

            if _.isFunction(description)                
              description()
            else 
              desc = description
              if typeof desc == 'string'
                desc = [description]

              DIV                
                style: _.defaults {}, (description_style or {}),
                  fontSize: 18
                  fontWeight: 400 
                  color: '#444'
                

                for para, idx in desc
                  DIV 
                    key: idx
                    style:
                      marginBottom: 10
                    dangerouslySetInnerHTML: {__html: para}


      # Header of cluster

      if ListHeader
        ListHeader()
      else 
        heading_text = list_items_title || cluster.name || 'Proposals'
        HEADING = if label then H2 else H1
        toggle_list = ->
          if !list_uncollapseable
            if collapsed.clusters[cluster_key]
              delete collapsed.clusters[cluster_key]
            else 
              collapsed.clusters[cluster_key] = 1 
            save collapsed

        DIV 
          style: 
            position: 'relative'

          HEADING
            style: _.extend {}, first_header, 
              position: 'relative'
              
            BUTTON 
              tabIndex: if list_uncollapseable then -1 else 0
              'aria-label': "#{heading_text}. Expand or collapse list."
              'aria-pressed': !collapsed.clusters[cluster_key]
              style: 
                padding: 0 
                margin: 0 
                border: 'none'
                backgroundColor: 'transparent'
                fontWeight: first_header.fontWeight
                cursor: if !list_uncollapseable then 'pointer'
                textAlign: 'left'
                  
              onKeyDown: (e) -> 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  toggle_list()
                  e.preventDefault()
              onClick: toggle_list

              heading_text 

              if !list_uncollapseable
                SPAN 
                  'aria-hidden': true
                  style: cssTriangle (if is_collapsed then 'right' else 'bottom'), 'black', tw, th,
                    position: 'absolute'
                    left: -tw - 20
                    bottom: 14
                    width: tw
                    height: th
                    display: 'inline-block'

            if list_one_line_desc
              DIV 
                style: 
                  position: 'absolute'
                  bottom: -14
                  color: '#666'
                  fontSize: 14
                  fontWeight: 400
                list_one_line_desc

          if !is_collapsed
            histo_title = customization('list_opinions_title', cluster_key)
            DIV
              style: secnd_header
              SPAN 
                style: 
                  position: 'relative'
                  marginLeft: -(widthWhenRendered(histo_title, 
                               {fontSize: 36, fontWeight: 600}) - secnd_column.width)/2
                histo_title



  storeSortOrder: -> 
    p = (p.key for p in sorted_proposals(@props.cluster.proposals))
    c = fetch("cluster-#{slugify(@props.cluster.name)}/sort_order")
    order = JSON.stringify(p)
    if order != c.sort_order
      c.sort_order = order 
      save c

  componentDidMount: -> @storeSortOrder()
  componentDidUpdate: -> @storeSortOrder()



window.NewProposal = ReactiveComponent
  displayName: 'NewProposal'


  render : -> 
    cluster_name = @props.cluster_name 
    cluster_key = "list/#{cluster_name}"

    cluster_state = fetch(@props.local)


    return SPAN null if cluster_name == 'Blocksize Survey'

    cluster_name = cluster_name or 'Proposals'
    current_user = fetch '/current_user'

    adding = cluster_state.adding_new_proposal == cluster_name 
    cluster_slug = slugify(cluster_name)

    permitted = permit('create proposal')
    needs_to_login = permitted == Permission.NOT_LOGGED_IN
    permitted = permitted > 0

    return SPAN null if !permitted && !needs_to_login

    DIV null,


      if !adding 

        BUTTON 
          style: _.defaults @props.label_style,
            cursor: 'pointer'
            backgroundColor: 'transparent'
            border: 'none'
            fontSize: 'inherit'
            padding: 0
            textDecoration: 'underline'

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
        w = first_column.width
        
        DIV 
          style:
            position: 'relative'

          if customization('new_proposal_tips', cluster_key)
            @drawTips customization('new_proposal_tips', cluster_key)

          if customization('show_proposer_icon', cluster_key) 
            editor = current_user.user
            # Person's icon
            Avatar
              key: editor
              user: editor
              style:
                position: 'absolute'
                left: -18 - 50
                height: 50
                width: 50
                borderRadius: 0
                backgroundColor: '#ddd'


          DIV 
            style: 
              display: 'inline-block'
            TEXTAREA 
              id:"#{cluster_slug}-name"
              name:'name'
              pattern:'^.{3,}'
              'aria-label': t('proposal_summary_instr')
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
              'aria-label': "Add #{t('details')} here"
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
                role: 'alert'
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

              BUTTON 
                style: 
                  backgroundColor: focus_blue
                  color: 'white'
                  cursor: 'pointer'
                  borderRadius: 16
                  padding: '4px 16px'
                  display: 'inline-block'
                  marginRight: 12
                  border: 'none'
                  fontSize: 'inherit'

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

              BUTTON 
                style: 
                  color: '#888'
                  cursor: 'pointer'
                  backgroundColor: 'transparent'
                  border: 'none'
                  padding: 0
                  fontSize: 'inherit'                  
                onClick: => cluster_state.adding_new_proposal = null; save(cluster_state)

                t('cancel')



  drawTips : (tips) -> 
    # guidelines/tips for good points
    mobile = browser.is_mobile

    guidelines_w = if mobile then 'auto' else 330
    guidelines_h = 300

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
            tips = customization('new_proposal_tips')

            for tip in tips
              LI 
                style: 
                  paddingBottom: 3
                  fontSize: if PORTRAIT_MOBILE() then 24 else if LANDSCAPE_MOBILE() then 14
                tip  






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


