require './shared'
require './customizations'
require './permissions'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './proposal_sort_and_search'
require './opinion_views'
require './browser_location'
require './collapsed_proposal'
require './new_proposal'
require './list'
require './tabs'



window.Homepage = ReactiveComponent
  displayName: 'Homepage'
  render: ->
    doc = fetch 'document'
    subdomain = fetch '/subdomain'

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
    phase = customization('contribution_phase')
    if phase == 'frozen'
      messages.push translator "engage.frozen_message", "The forum host has frozen this forum so no changes can be made."
    else if phase == 'ideas-only'
      messages.push translator "engage.ideas_only_message", "The forum host has set this forum to be ideas only. No opinions for now."
    else if phase == 'opinions-only'
      messages.push translator "engage.opinions_only_message", "The forum host has set this forum to be opinions only. No new ideas for now."

    if customization('anonymize_everything')
      messages.push translator "engage.anonymize_message", "The forum host has set participation to anonymous, so you won't be able to see the identity of others at this time."
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
        role: if get_tabs() then "tabpanel"

        if customization('auth_callout')
          DIV 
            style: 
              marginBottom: 36
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

          if fetch('edit_forum').editing
            for page in get_tabs() or [null]
              DIV 
                style: 
                  marginBottom: 80

                ChangeListOrder
                  page_name: page?.name
          else 
            get_current_tab_view()

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

    aggregate_list_key = get_current_tab_name()

    List
      key: aggregate_list_key
      combines_these_lists: get_all_lists()
      list: 
        key: "list/#{aggregate_list_key}"
        name: aggregate_list_key
        proposals: fetch('/proposals').proposals


#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into lists. 

window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    current_user = fetch('/current_user')
    current_tab = get_current_tab_name()
    
    lists = lists_for_page(current_tab)

    DIV null, 
      for list, index in lists or []
        List
          key: list.key
          list: list 

      if current_user.is_admin && current_tab not in ['About', 'FAQ']
        NewList()
          







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
    , 25

  componentWillUnmount: -> 
    clearInterval @int 


