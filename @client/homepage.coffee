require './shared'
require './customizations'
require './permissions'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './filter'
require './browser_location'
require './collapsed_proposal'
require './new_proposal'
require './lists'


window.AuthCallout = ReactiveComponent
  displayName: 'AuthCallout'

  render: ->
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    return SPAN null if current_user.logged_in

    DIV  
      style: 
        width: '100%'
        paddingBottom: 16

      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: 'auto'
        DIV 
          style: 
            fontSize: 24
            fontWeight: 600


          if subdomain.SSO_domain
            TRANSLATE
              id: 'create_account.call_out'
              BUTTON1: 
                component: A 
                args: 
                  href: '/login_via_saml'
                  treat_as_external_link: true
                  style: 
                    backgroundColor: 'transparent'
                    border: 'none'
                    fontWeight: 800
                    textDecoration: 'underline'
                    #color: 'white'
                    textTransform: 'lowercase'
                    padding: 0

              "Please <BUTTON1>create an account</BUTTON1> to participate"
          else 
            TRANSLATE
              id: 'create_account.call_out'
              BUTTON1: 
                component: BUTTON 
                args: 
                  'data-action': 'create'
                  onClick: (e) =>
                    reset_key 'auth',
                      form: 'create account'
                      ask_questions: true
                  style: 
                    backgroundColor: 'transparent'
                    border: 'none'
                    fontWeight: 800
                    textDecoration: 'underline'
                    #color: 'white'
                    textTransform: 'lowercase'
                    padding: 0

              "Please <BUTTON1>create an account</BUTTON1> to participate"


window.Homepage = ReactiveComponent
  displayName: 'Homepage'
  render: ->
    doc = fetch('document')
    subdomain = fetch('/subdomain')

    return SPAN null if !subdomain.name

    title = customization('banner')?.title or "#{subdomain.name} considerit forum"

    if doc.title != title
      doc.title = title
      save doc

    DIV 
      key: "homepage_#{subdomain.name}"      

      SimpleHomepage()


window.proposal_editor = (proposal) ->
  editors = (e for e in proposal.roles.editor when e != '*')
  editor = editors.length > 0 and editors[0]

  return editor != '-' and editor


window.column_sizes = (args) ->
  args ||= {}
  width = args.width or HOMEPAGE_WIDTH()

  return {
    first: width * .6 - 50
    second: width * .4
    gutter: 50
  }


window.TagHomepage = ReactiveComponent
  displayName: 'TagHomepage'

  render: -> 
    current_user = fetch('/current_user')

    show_all = fetch('show_all_proposals')

    users = fetch '/users'
    proposals = fetch '/proposals'
    proposals = proposals.proposals

    if !proposals || !users.users
      return ProposalsLoading()   

    clusters = get_all_clusters()

    hues = getNiceRandomHues clusters.length
    colors = {}
    for cluster, idx in clusters
      colors[cluster] = hues[idx]

    proposals = sorted_proposals(proposals, @local.key, true)

    homepage_tabs = fetch 'homepage_tabs'

    dummy_cluster = homepage_tabs.filter

    collapsed = fetch 'collapsed_clusters'      
    if !collapsed["list/#{dummy_cluster}"]?
      collapsed["list/#{dummy_cluster}"] = customization('list_is_archived', "list/#{dummy_cluster}")
      save collapsed



    DIV
      id: 'homepagetab'
      role: if customization('homepage_tabs') then "tabpanel"
      style: 
        margin: '45px auto'
        width: HOMEPAGE_WIDTH()
        position: 'relative'

      if customization('auth_callout')
        AuthCallout()

      ManualProposalResort sort_key: @local.key

      ListHeading 
        cluster: 
          key: "list/#{dummy_cluster}"
          name: dummy_cluster
          proposals: []
          list_is_archived: customization('list_is_archived', "list/#{dummy_cluster}")
        proposals_count: proposals.length 




      UL null, 

        for proposal,idx in proposals
          continue if idx > 20 && !show_all.show_all
          cluster = proposal.cluster or 'Proposals'

          CollapsedProposal 
            key: "collapsed#{proposal.key}"
            proposal: proposal
            show_category: true
            category_color: hsv2rgb(colors[cluster], .7, .8)

        if (show_all.show_all || proposals.length <= 20) && customization('list_show_new_button', "list/#{dummy_cluster}")
          LI 
            key: "newlist/#{dummy_cluster}"
            style: 
              margin: 0 
              padding: 0
              listStyle: 'none'
              display: 'inline-block'
              marginBottom: 20
              marginTop: 6
              

            NewProposal 
              cluster_name: dummy_cluster
              local: @local.key
              label_style: {}

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
            fontSize: 22

          onMouseDown: => 
            show_all.show_all = true
            save(show_all)

          translator "engage.show_hidden_proposals", 'Show all proposals'


#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into clusters. 

window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    subdomain = fetch('/subdomain')

    homepage_tabs = fetch 'homepage_tabs'

    if customization('homepage_tab_views')?[homepage_tabs.filter]
      view = customization('homepage_tab_views')[homepage_tabs.filter]()
      if typeof(view) == 'function'
        view = view()
      return view

    proposals = fetch '/proposals'
    current_user = fetch('/current_user')

    if !proposals.proposals 
      return ProposalsLoading()   

    clusters = clustered_proposals_with_tabs()

    collapsed = fetch 'collapsed_clusters'
    for cluster in clusters
      if !collapsed[cluster.key]?
        collapsed[cluster.key] = customization('list_is_archived', cluster.key)
        save collapsed

    DIV
      id: 'homepagetab'
      role: if customization('homepage_tabs') then "tabpanel"
      style: 
        margin: '45px auto'
        width: HOMEPAGE_WIDTH()
        position: 'relative'

      if customization('homepage_tabs') && customization('homepage_tab_headers')?[homepage_tabs.filter]
        customization('homepage_tab_headers')[homepage_tabs.filter]()

      if customization('auth_callout') && homepage_tabs.filter not in ['About', 'FAQ']
        AuthCallout()


      
      DIV null, 
        # List all clusters
        for cluster, index in clusters or []
          List
            key: "list/#{cluster.name}"
            list: cluster 
            index: index


        if permit('create proposal') > 0 && customization('homepage_show_new_proposal_button') \
            && homepage_tabs.filter not in ['About', 'FAQ'] && ( !subdomain.SSO_domain || current_user.logged_in)
          A 
            style: 
              color: logo_red
              marginTop: 35
              display: 'inline-block'
              borderBottom: "1px solid #{logo_red}"
            href: '/proposal/new'

            translator 'engage.add_new_proposal_button', "Create new proposal"

  typeset : -> 
    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && $('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,".proposal_homepage_name"])

  componentDidMount : -> @typeset()
  componentDidUpdate : -> @typeset()



window.HomepageTabTransition = ReactiveComponent
  displayName: "HomepageTabTransition"

  render: -> 
    if customization('homepage_tabs')
      loc = fetch 'location'
      homepage_tab = fetch('homepage_tabs')
      filters = ([k,v] for k,v of customization('homepage_tabs'))

      if !customization('homepage_tabs_no_show_all') && !customization('homepage_tabs')['Show all']
        filters.unshift ["Show all", '*']

      homepage_tabs = fetch 'homepage_tabs'
      if !homepage_tabs.filter? || (loc.query_params.tab && loc.query_params.tab != homepage_tabs.filter)
        if loc.query_params.tab
          homepage_tab.filter = decodeURI loc.query_params.tab
        else 
          homepage_tabs.filter = customization('homepage_default_tab') or 'Show all'
        for [filter, clusters] in filters 
          if filter == homepage_tabs.filter
            homepage_tabs.clusters = clusters
            break 
        save homepage_tabs

      if loc.url != '/' && loc.query_params.tab
        delete loc.query_params.tab
        save loc
      else if loc.url == '/' && loc.query_params.tab != homepage_tab.filter 
        loc.query_params.tab = homepage_tab.filter
        save loc

    SPAN null


window.HomepageTabs = ReactiveComponent
  displayName: 'HomepageTabs'

  render: -> 
    homepage_tabs = fetch 'homepage_tabs'
    filters = ([k,v] for k,v of customization('homepage_tabs'))
    if !customization('homepage_tabs_no_show_all') && !customization('homepage_tabs')['Show all']
      filters.unshift ["Show all", '*']

    subdomain = fetch('/subdomain')

    DIV 
      style: _.defaults {}, (@props.wrapper_style or {}),
        width: '100%'
        zIndex: 2
        position: 'relative'
        top: 2
        marginTop: 20

      A 
        name: 'active_tab'

      UL 
        role: 'tablist'
        style: _.defaults {}, (@props.list_style or {}),
          width: @props.width or 900 #HOMEPAGE_WIDTH()
          margin: 'auto'
          textAlign: if subdomain.name == 'HALA' then 'left' else 'center'
          listStyle: 'none'

        for [filter, clusters], idx in filters 
          do (filter, clusters) =>
            current = homepage_tabs.filter == filter 
            hovering = @local.hovering == filter
            featured = @props.featured == filter

            tab_name = customization('homepage_tab_render')?[filter]?() or filter

            tab_style = _.defaults {}, (@props.tab_style or {}),
              cursor: 'pointer'
              position: 'relative'
              fontSize: 16
              fontWeight: 600        
              color: 'white'
              padding: '10px 20px 4px 20px'

            tab_wrapper_style = _.defaults {}, (@props.tab_wrapper_style or {}),
              display: 'inline-block'
              position: 'relative'

            if current
              _.extend tab_style, {backgroundColor: 'rgba(255,255,255,.2)', opacity: 1}, (@props.active_style or {})
              _.extend tab_wrapper_style, @props.active_tab_wrapper_style or {}
            
            if hovering
              _.extend tab_style, {opacity: 1}, (@props.hover_style or @props.active_style or {})
              _.extend tab_wrapper_style, @props.hovering_tab_wrapper_style or {}


            LI 
              tabIndex: 0
              role: 'tab'
              style: tab_wrapper_style
              'aria-controls': 'homepagetab'
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
                loc = fetch 'location'
                loc.query_params.tab = filter 
                save loc  
                document.activeElement.blur()

              H4 
                style: tab_style

                translator
                  id: "homepage_tab.#{tab_name}"
                  key: "/translations/#{subdomain.name}"
                  tab_name

              if featured 
                @props.featured_insertion?()



window.ManualProposalResort = ReactiveComponent
  displayName: 'ManualProposalResort'

  render: -> 
    sort = fetch 'sort_proposals'

    if !sort.sorts?[@props.sort_key].stale 
      return SPAN null 

    DIV 
      style: 
        position: 'fixed'
        width: '100%'
        bottom: 0
        left: 0
        zIndex: 100
        backgroundColor: '#ddd'
        textAlign: 'center'
        fontSize: 26
        padding: '8px 0'


      TRANSLATE
        id: "engage.re-sort_list"
        button: 
          component: BUTTON
          args: 
            style: 
              color: focus_color()
              fontSize: 26
              textDecoration: 'underline'
              fontWeight: 'bold'
              border: 'none'
              backgroundColor: 'transparent'
              padding: 0
            onClick: invalidate_proposal_sorts
            onKeyDown: (e) => 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                invalidate_proposal_sorts()
                e.preventDefault()
        "<button>Re-sort this list</button> if you want. It is out of order."


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
        
        drawLogo 
          height: 50
          main_text_color: logo_red
          o_text_color: logo_red
          clip: false
          draw_line: true 
          line_color: logo_red
          i_dot_x: if negative then 284 - @local.cnt % 284 else @local.cnt % 284
          transition: false


      translator "loading_indicator", "Loading...there is much to consider!"

  componentWillMount: -> 
    @int = setInterval => 
      @local.cnt += 1 
      save @local 
    , 10

  componentWillUnmount: -> 
    clearInterval @int 


