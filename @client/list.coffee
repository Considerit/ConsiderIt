require './modal'
require './edit_list'


window.styles += """

  [data-widget="List"], [data-widget="NewList"], .draggable-wrapper {
    background-color: white;
    /* border: 1px solid #e1e1e1; */
    border: none;
    border-radius: 8px;
    box-shadow: -1px 1px 2px rgb(0 0 0 / 15%);
    border-top: 1px solid #f3f3f3;
  }

  .one-col [data-widget="List"], .one-col [data-widget="NewList"] {
    border-top: none;
    box-shadow: none;
  }

  .LIST-header {
    font-size: 32px;
    font-weight: 700;
    text-align: left;     
  }

  .LIST-header button {
    border: none;
    background-color: transparent;
    padding: 0; 
    margin: 0; 
    
  }
"""

get_list_padding = ->
  top = if ONE_COL() then 12 else 48
  bottom = if ONE_COL() then 12 else 48 

  if WINDOW_WIDTH() <= 955
    right = Math.max 36, LIST_PADDING()
    left  = Math.max 36, LIST_PADDING()
  else 
    right = Math.max 36, LIST_PADDING() + LIST_PADDING() / 6
    left  = Math.max 36, LIST_PADDING() - LIST_PADDING() / 6

  "#{top}px #{right}px #{bottom}px #{left}px"

window.list_link = (list_key) ->
  list_key.substring(5).toLowerCase().replace(/ /g, '_')


SHOW_FIRST_N_PROPOSALS = 6

window.List = ReactiveComponent
  displayName: 'List'


  # list of proposals
  render: -> 
    current_user = fetch '/current_user'
    list = @props.list
    if !list.key?
      list = get_list(@props.list)


    list_key = list.key

    # subscribe to a key that will alert us to when sort order has changed
    fetch('homepage_you_updated_proposal')

    proposals = list.proposals or []

    list_state = fetch list_key
    list_state.show_first_num_items ?= @props.show_first_num_items or SHOW_FIRST_N_PROPOSALS
    list_state.collapsed ?= customization('list_is_archived', list_key)

    is_collapsed = list_state.collapsed

    sty =         
      marginBottom: 40
      position: 'relative'
      padding: get_list_padding()

    if screencasting()
      _.extend sty,
        boxShadow: 'none'
        borderTop: 'none'
        paddingTop: 0 

    ARTICLE
      key: list_key
      id: list_key.substring(5).toLowerCase()
      style: sty

      A name: list_link(list_key)

      ListHeader 
        list: list
        combines_these_lists: @props.combines_these_lists 
        proposals_count: proposals.length
        fresh: @props.fresh
        allow_editing: !@props.allow_editing? || @props.allow_editing

      if !is_collapsed && !@props.fresh
        
        permitted = permit('create proposal', list_key)
        DIV null, 

          ListItems 
            list: list 
            key: "#{list.key}-items"
            fresh: @props.fresh
            show_first_num_items: if list_state.show_all_proposals then 999999 else list_state.show_first_num_items
            combines_these_lists: @props.combines_these_lists
            # show_new_button: (list_state.show_all_proposals || proposals.length <= list_state.show_first_num_items) && \
            #    ((@props.combines_these_lists && lists_current_user_can_add_to(@props.combines_these_lists).length > 0) || (permitted > 0 || permitted == Permission.NOT_LOGGED_IN) )
            show_new_button: (@props.combines_these_lists && lists_current_user_can_add_to(@props.combines_these_lists).length > 0) || (permitted > 0 || permitted == Permission.NOT_LOGGED_IN)
            proposal_focused_on: @props.proposal_focused_on

      if customization('footer', list_key) && !is_collapsed
        customization('footer', list_key)()



styles += """

  .show-all-proposals {
    list-style: none;
    position: relative;
    margin-top: -105px;
    width: 105%;
    z-index: 10;    
  }

  .show-all-proposals button {
    background: linear-gradient(0deg, rgba(255,255,255,1) 0%, rgba(255,255,255,1) 60%, rgba(255,255,255,0) 100%);
    width: 100%;
    cursor: pointer;
    padding: 32px 0 22px 0;
    font-weight: 700;
    text-align: center;
    border: none;
    font-size: 22px;
    color: #446ae3;
    padding-top: 96px;
    margin-top: 12px;
    margin-bottom: 8px;
  }
"""


ListItems = ReactiveComponent
  displayName: 'ListItems'

  render: ->
    list = @props.list 
    list_key = list.key

    sort_key = "sorted-proposals-#{list_key}"
    proposals = if !@props.fresh then sorted_proposals(list.proposals, sort_key, true) or [] else []

    if @props.proposal_focused_on
      proposals = proposals.slice()
      for proposal,idx in proposals
        if proposal.key == @props.proposal_focused_on.key
          proposals.splice idx, 1
          proposals.unshift proposal
          break



    if @props.combines_these_lists
      hues = getNiceRandomHues @props.combines_these_lists.length
      colors = {}
      for aggregated_list, idx in @props.combines_these_lists
        colors[aggregated_list] = hues[idx]



    show_all_button = => 

      LI
        className: 'show-all-proposals'
        key: "show-all-#{list_key}"
        style:
          listStyle: 'none'

        BUTTON
          onClick: => 
            list_state = fetch list_key
            list_state.show_all_proposals = true
            save list_state

          SPAN 
            style: 
              textDecoration: 'underline'

            translator "engage.show_hidden_proposals", 'Show all'

          SPAN 
            className: 'monospaced'
            style: 
              paddingLeft: 18
              color: '#444'
              fontWeight: 400
            "+#{proposals.length - @props.show_first_num_items}"



    render_new = =>
      LI 
        key: "new#{list_key}"
        style: 
          margin: 0 
          padding: 0
          listStyle: 'none'
          display: 'inline-block'
          marginBottom: 20
          marginTop: 6
          
        NewProposal 
          list_key: list_key
          combines_these_lists: @props.combines_these_lists  

    proposals_to_render = (p for p,idx in proposals when idx < @props.show_first_num_items && passes_running_timelapse_simulation(p.created_at))

    sorted_key = (p.key for p in proposals_to_render).join('###')

    DIV null,

      FLIPPER
        flipKey: sorted_key

        UL null, 
          for proposal,idx in proposals_to_render

            CollapsedProposal
              key: "collapsed#{proposal.key}"
              proposal: proposal.key
              show_category: !!@props.combines_these_lists
              category_color: if @props.combines_these_lists then hsv2rgb(colors["list/#{(proposal.cluster or 'Proposals')}"], .9, .8)
              focused_on: @props.proposal_focused_on && @props.proposal_focused_on.key == proposal.key


          if proposals.length > @props.show_first_num_items 
            show_all_button()


          if @props.show_new_button
            render_new()




__remove_this_list = (list_key, page) ->
  subdomain = fetch '/subdomain'
  list_key = list_key.key or list_key
  tabs = get_tabs()

  customizations = subdomain.customizations

  if tabs
    for tab in tabs
      if (idx = tab.lists.indexOf(list_key)) > -1
        tab.lists.splice idx, 1

  else 
    ol = customizations.lists
    if ol 
      idx = ol.indexOf(list_key)
      if idx > -1
        ol.splice idx, 1
        if ol.length == 0
          delete customizations.lists

  list_in_other_pages = false
  if tabs
    for tab in tabs
      if tab.lists.indexOf(list_key) > -1 
        list_in_other_pages = true 
        break

  if !list_in_other_pages
    delete customizations[list_key] 
          
  save subdomain


window.delete_list = (list_key, page, suppress_confirmation) ->
  subdomain = fetch '/subdomain'

  list_key = list_key.key or list_key

  tabs = get_tabs()

  list_in_num_pages = 0
  if tabs
    for tab in tabs
      if tab.lists.indexOf(list_key) > -1 
        list_in_num_pages += 1
  else 
    list_in_num_pages = 1 

  if list_in_num_pages <= 1

    proposals = get_proposals_in_list(list_key)

    if proposals?.length > 0 
      has_permission = true 
      for proposal in proposals 
        has_permission &&= permit('delete proposal', proposal) > 0 

      if !has_permission
        alert "You apparently don't have permission to delete one or more of the proposals in this list"
      else if has_permission && (suppress_confirmation || confirm(translator('engage.list-config-delete-confirm', 'Are you sure you want to delete this list? All of the proposals in it will also be permanently deleted. If you want to get rid of the list, but not delete the proposals, you could move the proposals first.')))
        for proposal in proposals
          destroy proposal.key
        __remove_this_list(list_key, page)  

    else if suppress_confirmation || confirm(translator('engage.list-config-delete-confirm-when-no-proposals', 'Are you sure you want to delete this list? This is irreversable.'))
      __remove_this_list(list_key, page)  

  else
    __remove_this_list(list_key, page)  















window.ListHeader = ReactiveComponent
  displayName: 'ListHeader'

  render: -> 
    list = @props.list 
    list_key = list.key
    list_state = fetch list_key

    is_collapsed = list_state.collapsed

    subdomain = fetch '/subdomain'

    description = customization('list_description', list_key, subdomain)

    DIVIDER = customization 'list_divider', list_key, subdomain

    wrapper_style = 
      width: HOMEPAGE_WIDTH()
      marginBottom: if !is_collapsed then 16 #24
      position: 'relative'

    DIV 
      style: wrapper_style 

      DIVIDER?()

      DIV 
        style: 
          position: 'relative'


        DIV 
          style: 
            width:  HOMEPAGE_WIDTH()
            margin:  'auto'

          EditableTitle
            list: @props.list
            fresh: @props.fresh

          if !is_collapsed
            DIV null, 
              if description?.length > 0 || typeof(description) == 'function'
                EditableDescription
                  list: @props.list
                  fresh: @props.fresh


      if @props.allow_editing
        EditList
          list: @props.list
          fresh: @props.fresh
          combines_these_lists: @props.combines_these_lists

      if @props.proposals_count > 0 && !is_collapsed && !customization('list_no_filters', list_key, subdomain)
        list_actions
          list: @props.list
          add_new: !@props.combines_these_lists && customization('list_permit_new_items', list_key, subdomain) && !is_collapsed && @props.proposals_count > 4
          can_sort: customization('homepage_show_search_and_sort', null, subdomain) && @props.proposals_count > 1 
          fresh: @props.fresh





styles += """
  button[data-widget="NewList"] {
    text-align: left;
    margin-top: 55px;
    display: block;
    position: relative;
    width: 100%;
    border-radius: 8px;

  }
  button[data-widget="NewList"] h1.LIST-header {
    position: relative;
    left: -42px;
    display: flex;
    align-items: center;
  }

  button[data-widget="NewList"] h1.LIST-header svg {
    margin-right: 13px;
  }


  button[data-widget="NewList"] .subbutton_button {
    color: #{focus_blue};
    font-weight: 700;
  }

  button[data-widget="NewList"]:hover .subbutton_button, button[data-widget="NewList"]:hover .separator {
    text-decoration: underline;
  }

  button[data-widget="NewList"] .separator {
    // padding: 0 12px;
    font-weight: 300;
    color: #{focus_blue};
  }
  button[data-widget="NewList"] .subheader {
    color: #656565;
    font-size: 16px;
    position: relative;
  }
"""


window.NewList = ReactiveComponent
  displayName: 'NewList'

  render: -> 
    subdomain = fetch '/subdomain'

    wide_layout = WINDOW_WIDTH() > 1250 

    @local.hovering ?= false

    if @local.editing
      ModalNewList 
        fresh: true
        default_open_ended: @local.default_open_ended
        done_callback: =>
          @local.editing = false 
          save @local


    else 
      BUTTON 
        style: 
          padding: if !@props.no_padding then get_list_padding()

        onClick: (e) =>
          @local.editing = true 
          @local.default_open_ended = e.target.classList.contains('open')
          save @local

        H1
          className: 'LIST-header'

          plus_icon focus_blue

          SPAN 
            className: 'subbutton_button open'
            'Add a request for feedback' 

          if wide_layout
            SPAN null,
              SPAN 
                className: 'separator'
                dangerouslySetInnerHTML: __html: "&nbsp;&nbsp;#{t('or', 'or')}&nbsp;&nbsp;"
              SPAN 
                className: 'subbutton_button closed'
                'an open-ended question'

        if wide_layout
          DIV 
            className: 'subheader'

            SPAN 
              style: 
                position: 'relative'
                left: 250 

              'on a fixed set of proposals'

            SPAN 
              style: 
                position: 'relative'
                left: 539
              'for community ideation'

        else 
          DIV 
            className: 'subheader'

            SPAN 
              style: 
                position: 'relative'
                left: 0 

              'on a fixed set of proposals or in response to an open-ended question'




window.list_i18n = ->
  button: translator('engage.create_new_list_button', "Create a new call for ideas or feedback")
  explanation: translator 'engage.create_new_list_explanation', 'Ask an open-ended question like "What are your ideas?" or establish a category like "Recommendations."'
  new_response_label: (list_key) ->
    item_name = customization('list_item_name', list_key)
    if item_name
      item_name = capitalize item_name
    if item_name == 'proposal' or !item_name
      translator "engage.add_new_proposal_to_list", 'Add new proposal'
    else 
      translator 
        id: "engage.add_new_#{item_name}_to_list"
        key: "/translations/#{fetch('/subdomain').name}"
      , "Add new #{item_name}"
  opinion_header: (list_key) ->
    item_name = customization('list_item_name', list_key)
    if item_name
      item_name = capitalize item_name
    if item_name == 'proposal' or !item_name
      translator "engage.opinion_header_results", 'Opinions about this proposal'
    else 
      translator 
        id: "engage.opinion_header_results_#{item_name}"
        key: "/translations/#{fetch('/subdomain').name}"
      , "Opinions about this #{item_name}"


EditableTitle = ReactiveComponent
  displayName: 'EditableTitle'

  render: -> 
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = list.key

    list_state = fetch list_key
    is_collapsed = list_state.collapsed

    subdomain = fetch '/subdomain'

    title = get_list_title list_key, true, subdomain

    list_uncollapseable = customization 'list_uncollapseable', list_key, subdomain

    toggle_list = ->
      if !list_uncollapseable
        list_state.collapsed = !list_state.collapsed
        save list_state


    DIV null, 

      H1 
        className: 'LIST-header'
        style: # ugly...we only want to show the expand/collapse icon
          fontSize: if title.replace(/^\s+|\s+$/g, '').length == 0 then 0

        DIV
          onMouseEnter: => @local.hover_label = true; save @local 
          onMouseLeave: => @local.hover_label = false; save @local
          className: 'LIST-header'          
          style: _.defaults {}, customization('list_label_style', list_key, subdomain) or {}, 
            fontFamily: header_font()              
            position: 'relative'
            textAlign: 'left'
            outline: 'none'


          title 

          if !list_uncollapseable
            tw = 15   

            BUTTON 
              tabIndex: if !list_uncollapseable then 0
              'aria-label': "#{title}. #{translator('accessibility-expand-or-collapse-list', 'Expand or collapse list.')}"
              'aria-pressed': !is_collapsed

              onClick: if !list_uncollapseable then (e) -> 
                toggle_list()
                document.activeElement.blur()

              'aria-hidden': true
              style: 
                position: 'absolute'
                left: -tw - 20
                top: if is_collapsed then -14 else 5
                paddingRight: 20
                paddingTop: 12
                display: 'inline-block'
                cursor: 'pointer'
                transform: if !is_collapsed then 'rotate(90deg)'
                transition: 'transform .25s, top .25s'

              ChevronRight(tw)

        


styles += """
  .LIST-description {
    font-size: 16px;
    font-weight: 400;
    color: black;
    margin-top: 8px;
    margin-bottom: 18px;
    font-style: italic;
  }

"""

EditableDescription = ReactiveComponent
  displayName: 'EditableDescription'
  render: -> 
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = list.key

    description = customization('list_description', list_key)
    if Array.isArray(description)
      description = description.join('\n')

    description_style = customization 'list_description_style', list_key

    return SPAN null if !description

    DIV
      style: _.defaults {}, (description_style or {})
      className: "LIST-description #{if typeof description != 'function' then 'wysiwyg_text' else ''}"

      if typeof description == 'function'
        description()        
      else 
        desc = description
        if typeof desc == 'string'
          desc = [description]

        for para, idx in desc
          DIV 
            key: idx
            style:
              marginBottom: 10
            dangerouslySetInnerHTML: {__html: para}


window.list_actions = (props) -> 
  list_key = props.list.key

  DIV   
    className: 'list_actions'
    style: 
      marginBottom: 50
      marginTop: 24
      display: 'flex'
      alignItems: 'baseline'

    DIV 
      style: 
        width: column_sizes().first + 58
        marginRight: column_sizes().gutter
        display: 'flex'


      if props.can_sort
        # [ SortProposalsMenu(), FilterProposalsMenu() ]
        SortProposalsMenu()


      if !props.fresh
        sort_key = "sorted-proposals-#{list_key}"
        SPAN 
          style: 
            display: 'inline-block'
            marginLeft: 12
          
          ManualProposalResort {sort_key}

        

    OpinionViews
      style: 
        width: if ONE_COL() then 400 else column_sizes().second

      more_views_positioning: 'right'

      additional_width: column_sizes().gutter + column_sizes().first




window.get_list_title = (list_key, include_category_value, subdomain) -> 
  title = customization('list_title', list_key, subdomain)
  if include_category_value
    title ?= category_value list_key, null, subdomain

  if title == 'Show all' || !title?
    title = translator "engage.all_proposals_list", "All Proposals"
  else if title == 'Proposals'
    title = translator "engage.default_proposals_list", "Proposals"

  title 


category_value = (list_key, fresh, subdomain) -> 

  category = customization('list_category', list_key, subdomain)
  if !category && !customization(list_key, null, subdomain) && !fresh # if we haven't customized this list, take the proposal category
    category ?= list_key.substring(5)
  category ?= translator 'engage.default_proposals_list', 'Proposals'
  category


window.get_all_lists = ->
  all_lists = []

  # Give primacy to specified order of lists in tab config or ordered_list customization
  subdomain = fetch('/subdomain')
  if get_tabs()
    for tab in get_tabs()
      all_lists = all_lists.concat (l for l in tab.lists when l != '*' && l != '*-')
  else if customization 'lists'
    all_lists = (l for l in customization('lists') when l != '*' && l != '*-')

  # lists might also just be defined as a customization, without any proposals in them yet
  subdomain_name = subdomain.name?.toLowerCase()
  config = customizations[subdomain_name]
  for k,v of config 
    if k.match( /list\// )
      all_lists.push k

  proposals = fetch '/proposals'
  all_lists = all_lists.concat("list/#{(p.cluster or 'Proposals').trim()}" for p in proposals.proposals)

  all_lists = _.uniq all_lists
  all_lists


window.get_list_sort_method = (tab) ->
  tab ?= get_current_tab_name()
  get_tab(tab)?.list_sort_method or customization('list_sort_method') or \
    (if customization('lists') || get_tabs() then 'fixed' else 'newest_item')



lists_ordered_by_most_recent_update = {}
lists_ordered_by_randomized = {}

window.get_lists_for_page = (tab) -> 
  homepage_tabs = fetch 'homepage_tabs'
  tab ?= get_current_tab_name()
  tabs_config = get_tabs()

  if tabs_config
    eligible_lists = get_tab(tab)?.lists
  else
    eligible_lists = customization 'lists'
    if eligible_lists && '*-' in eligible_lists
      console.error "Illegal wildcard *- in lists customization"
      

  if !eligible_lists
    eligible_lists = ['*']

  ##################################################
  # lists_in_tab will be the list_keys for the tab, in the specified 
  # fixed order, with wildcards substituted

  lists_in_tab = []

  for list in eligible_lists

    if list == '*' || (list == '*-' && !tabs_config)
      for ll in get_all_lists()
        if ll not in eligible_lists
          lists_in_tab.push ll      

    # '*-' matches all lists that are not already referenced in other tabs
    else if list == '*-'
      referenced_elsewhere = {}

      for a_tab in tabs_config
        continue if a_tab.name == tab
        for ll in a_tab.lists 
          if ll != '*' && ll != '*-'
            referenced_elsewhere[ll] = true

      for ll in get_all_lists()
        if ll not of referenced_elsewhere && ll not in eligible_lists
          lists_in_tab.push ll

    else 
      lists_in_tab.push list



  ######################################################
  # now we'll flesh the lists out with proposals
  proposals = fetch '/proposals'
  lists_with_proposals = {}

  for list_key in lists_in_tab
    lists_with_proposals[list_key] = 
      key: list_key
      proposals: []

  for proposal in proposals.proposals 
    list_key = "list/#{(proposal.cluster or 'Proposals').trim()}"
    if list_key of lists_with_proposals
      lists_with_proposals[list_key].proposals.push proposal


  ######################################################
  # ...and finally, let's sort the lists if there's a different sorted order other than fixed

  list_sort_method = get_list_sort_method(tab)

  lists_in_order = (lists_with_proposals[list_key] for list_key in lists_in_tab) # this is already fixed sort

  if list_sort_method == 'newest_item'

    # Sort lists by the newest of its proposals.
    # But we'll only do this on page load or if the number of lists has changed, 
    # so that lists don't move around when someone adds a new proposal.
    lists_ordered_by_most_recent_update[tab] ?= {}
    by_recency = lists_ordered_by_most_recent_update[tab]

    if Object.keys(by_recency).length != lists_in_order.length
      for lst in lists_in_order 
        by_recency[lst.key] = -1 # in case there aren't any proposals in it
        for proposal in lst.proposals 
          time = (new Date(proposal.created_at).getTime())
          if !by_recency[lst.key] || time > by_recency[lst.key]
            by_recency[lst.key] = time 

    for lst in lists_in_order
      if by_recency[lst.key] && by_recency[lst.key] > 0
        lst.order = (new Date()).getTime() - by_recency[lst.key]
      else 
        lst.order = 9999999999999

    lists_in_order.sort (a,b) -> a.order - b.order

  else if list_sort_method == 'randomized'
    lists_ordered_by_randomized[tab] ?= {}
    by_random = lists_ordered_by_randomized[tab]
    if Object.keys(by_random).length != lists_in_order.length
      for lst in lists_in_order
        by_random[lst.key] = Math.random()

    for lst in lists_in_order
      if by_random[lst.key]
        lst.order = by_random[lst.key]
      else 
        lst.order = 9999999999999

    lists_in_order.sort (a,b) -> a.order - b.order


  lists_in_order


window.get_proposals_in_list = (list_key) -> 
  proposals = fetch '/proposals'

  (p for p in proposals.proposals when "list/#{(p.cluster or 'Proposals').trim()}" == list_key)


window.get_list = (list_key) ->
  lst = _.extend {}, customization(list_key),
    key: list_key
    proposals: get_proposals_in_list(list_key)

window.lists_current_user_can_add_to = (lists) -> 
  appendable = []
  for list_key in lists 
    if permit('create proposal', list_key) > 0
      appendable.push list_key 
  appendable















