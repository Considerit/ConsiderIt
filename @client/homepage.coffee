require './shared'
require './customizations'
require './permissions'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './filter'
require './browser_location'
require './collapsed_proposal'
require './new_proposal'
require './list'


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
                    fontWeight: 700
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
                  style: 
                    backgroundColor: 'transparent'
                    border: 'none'
                    fontWeight: 700
                    textDecoration: 'underline'
                    #color: 'white'
                    textTransform: 'lowercase'
                    padding: 0

              "Please <BUTTON1>create an account</BUTTON1> to participate"


window.Homepage = ReactiveComponent
  displayName: 'Homepage'
  render: ->
    doc = fetch 'document'
    subdomain = fetch '/subdomain'
    homepage_tabs = fetch 'homepage_tabs'

    return SPAN null if !subdomain.name

    title = customization('banner')?.title or "#{subdomain.name} considerit forum"

    if title.indexOf('<') > -1 
      tmp = document.createElement "DIV"
      tmp.innerHTML = title
      title = tmp.textContent or tmp.innerText or title

    if doc.title != title
      doc.title = title
      save doc

    messages = []
    if customization('frozen')
      messages.push translator "engage.frozen_message", "The forum host has frozen this forum so no changes can be made."
    if customization('anonymize_everything')
      messages.push translator "engage.anonymize_message", "The forum host has participation set to anonymous in this forum, so you won't be able to see the identity of others at this time."
    if customization('hide_opinions')
      messages.push translator "engage.hide_opinions_message", "The forum host has hidden the opinions of other participants, so you won't be able to see their specific opinions at this time."

    DIV 
      key: "homepage_#{subdomain.name}"      

      STYLE 
        dangerouslySetInnerHTML: __html: """
            #homepagetab {
              margin: 45px auto;
              width: #{HOMEPAGE_WIDTH()}px;
              position: relative;       
            }
          """

      DIV
        id: 'homepagetab'
        role: if customization('homepage_tabs') then "tabpanel"

        if customization('auth_callout')
          AuthCallout()

        for message in messages
          DIV 
            style: 
              marginBottom: 24 
              fontStyle: 'italic'
            message


        if !fetch('/proposals').proposals
          ProposalsLoading()   
        else 
          if customization('homepage_tab_views')?[homepage_tabs.filter]
            view = customization('homepage_tab_views')[homepage_tabs.filter]()
            if typeof(view) == 'function'
              view = view()
            view
          else
            SimpleHomepage()

  typeset : -> 
    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && $('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset", MathJax.Hub, ".proposal_homepage_name"])

  componentDidMount : -> @typeset()
  componentDidUpdate : -> @typeset()


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
    proposals = sorted_proposals(fetch('/proposals').proposals, @local.key, true)

    homepage_tabs = fetch 'homepage_tabs'
    aggregate_list_key = homepage_tabs.filter

    List
      key: aggregate_list_key
      combines_these_lists: get_all_lists()
      list: 
        key: "list/#{aggregate_list_key}"
        name: aggregate_list_key
        proposals: proposals


#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into lists. 

window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    current_user = fetch('/current_user')
    homepage_tabs = fetch 'homepage_tabs'
    lists = lists_for_tab(homepage_tabs.filter)

    DIV null, 
      for list, index in lists or []
        List
          key: list.key
          list: list 

      if current_user.is_admin && homepage_tabs.filter not in ['About', 'FAQ']
        NewList()
          


window.HomepageTabTransition = ReactiveComponent
  displayName: "HomepageTabTransition"

  render: -> 
    if customization('homepage_tabs')
      loc = fetch 'location'
      tab_state = fetch 'homepage_tabs'
      tab_config = customization('homepage_tabs')
      default_tab = customization('homepage_default_tab') or 'Show all'

      tabs = ([k,v] for k,v of tab_config)

      if !customization('homepage_tabs_no_show_all') && !tab_config['Show all']
        tabs.unshift ["Show all", '*']

      if !tab_state.filter? || (loc.query_params.tab && loc.query_params.tab != tab_state.filter)
        if loc.query_params.tab
          tab_state.filter = decodeURI loc.query_params.tab
        else 
          tab_state.filter = default_tab
        for [tab, lists] in tabs 
          if tab == tab_state.filter
            tab_state.clusters = lists
            break 
        save tab_state

      if loc.url != '/' && loc.query_params.tab
        delete loc.query_params.tab
        save loc
      else if loc.url == '/' && loc.query_params.tab != tab_state.filter 
        loc.query_params.tab = tab_state.filter
        save loc

    SPAN null




styles += """
  #tabs {
    width: 100%;
    z-index: 2;
    position: relative;
    top: 2px;
    margin-top: 20px;
  }
  #tabs > ul {
    margin: auto;
    text-align: center;
    list-style: none;
    width: 900px;
  }
  #tabs > ul > li {
    display: inline-block;
    position: relative;
    outline: none;
  }          
  #tabs > ul > li > h4 {
    cursor: pointer;
    position: relative;
    font-size: 16px;
    font-weight: 600;        
    color: white;
    padding: 10px 20px 4px 20px;
  }
  #tabs > ul > li.selected > h4 {
    background-color: rgba(255,255,255,.2);
    opacity: 1;
  }
  #tabs > ul > li.hovering > h4 {
    opacity: 1;
  }
"""

window.HomepageTabs = ReactiveComponent
  displayName: 'HomepageTabs'

  render: -> 
    homepage_tabs = fetch 'homepage_tabs'
    filters = ([k,v] for k,v of customization('homepage_tabs'))
    if !customization('homepage_tabs_no_show_all') && !customization('homepage_tabs')['Show all']
      filters.unshift ["Show all", '*']

    subdomain = fetch('/subdomain')

    DIV 
      id: 'tabs'
      style: @props.wrapper_style

      A 
        name: 'active_tab'

      UL 
        role: 'tablist'
        style: _.defaults {}, @props.list_style,
          width: @props.width


        for [tab_name, clusters], idx in filters 
          do (tab_name, clusters) =>
            current = homepage_tabs.filter == tab_name 
            hovering = @local.hovering == tab_name
            featured = @props.featured == tab_name

            tab_style = _.extend {}, @props.tab_style
            tab_wrapper_style = _.extend {}, @props.tab_wrapper_style

            if current
              _.extend tab_style, @props.active_style
              _.extend tab_wrapper_style, @props.active_tab_wrapper_style
            
            if hovering
              _.extend tab_style, @props.hover_style or @props.active_style
              _.extend tab_wrapper_style, @props.hovering_tab_wrapper_style

            LI 
              className: if current then 'selected' else if hovering then 'hovered'
              tabIndex: 0
              role: 'tab'
              style: tab_wrapper_style
              'aria-controls': 'homepagetab'
              'aria-selected': current

              onMouseEnter: => 
                if homepage_tabs.filter != tab_name 
                  @local.hovering = tab_name 
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
                loc.query_params.tab = tab_name 
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


