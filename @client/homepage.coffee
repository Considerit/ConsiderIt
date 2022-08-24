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


styles += """
  .main_background {
    background-color: #{main_background_color};
  }

  .main_background.one-col, .main_background .one-col, .one-col.navigation_wrapper {
    background-image: none;
    background-color: white;
  }


  #homepagetab {
    margin: 0px auto;
    position: relative;
    padding: 24px 0px 140px 0;
  }

  .one-col #homepagetab {
    padding: 24px 0px 140px 12px;
  }

  :not(.one-col) #homepagetab {
    width: calc(var(--HOMEPAGE_WIDTH) + var(--LIST_PADDING-RIGHT) + var(--LIST_PADDING-LEFT));
  }

  .sized_for_homepage {
    margin: auto;
    width: var(--HOMEPAGE_WIDTH);
    padding: 0px var(--LIST_PADDING-RIGHT) 0px var(--LIST_PADDING-LEFT);
  }


"""
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
      messages.push translator "engage.hide_opinions_message", "The forum host has hidden the opinions of other participants."

    DIV 
      key: "homepage_#{subdomain.name}"      
      className: "main_background #{if ONE_COL() then 'one-col' else ''}"

      DIV
        id: 'homepagetab'
        role: if get_tabs() then "tabpanel"

        if !fetch('/proposals').proposals
          DIV 
            className: 'sized_for_homepage'
            ProposalsLoading()   
        else 

          if fetch('edit_forum').editing
            for page in get_tabs() or [{name: null}]
              EditPage
                key: "#{page?.name}-#{!!get_tabs()}"
                page_name: page?.name
          else 
            DIV null,
              DIV 
                className: 'sized_for_homepage'                  

                if customization('auth_callout')
                  DIV 
                    style: 
                      marginBottom: 36
                    AuthCallout()

                NewForumOnBoarding()

                for message in messages
                  DIV 
                    key: message
                    style: 
                      marginBottom: 24 
                      fontStyle: 'italic'
                    message

                if preamble = get_page_preamble()
                  DIV
                    style: 
                      marginBottom: 24
                    dangerouslySetInnerHTML: __html: preamble


              if (proposal_editing = fetch('proposal_editing')).editing
                EditProposal 
                  proposal: proposal_editing.editing
                  done_callback: (e) =>
                    proposal_editing.editing = null
                    save proposal_editing

              get_current_tab_view()

              if get_tabs()
                DIV 
                  style: 
                    paddingTop: 68

                  DIV 
                    style: 
                      textAlign: 'center'
                      color: selected_color
                      fontWeight: 600
                    translator 'tabs.footer_label', "Find more proposals on a different page:"
                    
                  HomepageTabs
                    go_to_hash: 'active_tab'
                    active_style: 
                      backgroundColor: '#666'
                      color: 'white'
                    tab_style: 
                      backgroundColor: 'transparent'
                      margin: 4
                      padding: "8px 20px"
                      color: '#555'


  typeset : -> 
    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && !document.querySelector('.MathJax')
      MathJax.Hub.Queue(["Typeset", MathJax.Hub, ".proposal_homepage_name"])

  componentDidMount : -> @typeset()
  componentDidUpdate : -> @typeset()


window.proposal_editor = (proposal) ->
  editors = (e for e in proposal.roles.editor when e != '*')
  editor = editors.length > 0 and editors[0]

  return editor != '-' and editor



window.TagHomepage = ReactiveComponent
  displayName: 'TagHomepage'

  render: -> 
    current_user = fetch('/current_user')

    aggregate_list_key = get_current_tab_name()

    DIV null,

      List
        key: aggregate_list_key
        proposal_focused_on: @props.proposal_focused_on
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
    
    lists = get_lists_for_page(current_tab).slice()

    if @props.proposal_focused_on
      list_focused_on = "list/#{@props.proposal_focused_on.cluster or 'Proposals'}"
      for list,idx in lists 
        if list.key == list_focused_on
          lists.splice idx, 1 
          lists.unshift list
          break

    DIV null, 
      for list, index in lists or []
        List
          proposal_focused_on: if @props.proposal_focused_on && list.key == list_focused_on then @props.proposal_focused_on
          key: list.key
          list: list 

      if !@props.proposal_focused_on && current_user.is_admin && current_tab not in ['About', 'FAQ'] && get_tab(current_tab)?.type not in [PAGE_TYPES.ABOUT, PAGE_TYPES.ALL]
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

  UNSAFE_componentWillMount: -> 
    @int = setInterval => 
      @local.cnt += 1 
      save @local 
    , 25

  componentWillUnmount: -> 
    clearInterval @int 


