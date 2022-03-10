require './modal'
require './edit_list'


window.styles += """

  [data-widget="List"], [data-widget="NewList"] {
    background-color: white;
    /* border: 1px solid #e1e1e1; */
    border: none;
    border-radius: 8px;
    box-shadow: -1px 1px 2px rgb(0 0 0 / 15%);
    border-top: 1px solid #f3f3f3;
  }

  .one-col [data-widget="List"] {
    border-top: none;
    box-shadow: none;
  }

  .LIST-header {
    font-size: 32px;
    font-weight: 500;
    text-align: left;     
  }

  .LIST-header button {
    border: none;
    background-color: transparent;
    padding: 0; 
    margin: 0; 
    
  }

  .LIST-fat-header-field {
    background-color: white;
    border: 1px solid #eaeaea;
    border-radius: 8px;
    outline-color: #ccc;
    line-height: 1.4;
    padding: 8px 12px;
    /* margin-top: -9px; */
    margin-left: -13px;

  }

  .LIST-field-edit-label {
    font-size: 14px;
    display: inline-block;
    font-weight: 400;
    margin-top: 18px;
  }

"""

get_list_padding = ->
  top = if ONE_COL() then 12 else 48
  bottom = top 

  right = LIST_PADDING() + LIST_PADDING() / 6
  left = LIST_PADDING() - LIST_PADDING() / 6

  "#{top}px #{right}px #{bottom}px #{left}px"

list_link = (list_key) ->
  list_key.substring(5).toLowerCase().replace(/ /g, '_')

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
    list_state.show_first_num_items ?= @props.show_first_num_items or 12
    list_state.collapsed ?= customization('list_is_archived', list_key)

    is_collapsed = list_state.collapsed

    ARTICLE
      key: list_key
      id: list_key.substring(5).toLowerCase()
      style: 
        marginBottom: 40
        position: 'relative'
        padding: get_list_padding()

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
            show_new_button: (list_state.show_all_proposals || proposals.length <= list_state.show_first_num_items) && \
               ((@props.combines_these_lists && lists_current_user_can_add_to(@props.combines_these_lists).length > 0) || (permitted > 0 || permitted == Permission.NOT_LOGGED_IN) )

          if !list_state.show_all_proposals && proposals.length > list_state.show_first_num_items 
            BUTTON
              style:
                backgroundColor: '#f9f9f9'
                width: HOMEPAGE_WIDTH()
                cursor: 'pointer'
                paddingTop: 10
                paddingBottom: 10
                fontWeight: 600
                textAlign: 'center'
                marginTop: 12
                marginBottom: 28
                border: 'none'
                fontSize: 22

              onClick: => 
                list_state.show_all_proposals = true
                save list_state

              SPAN 
                style: 
                  textDecoration: 'underline'

                translator "engage.show_hidden_proposals", 'Show all'

              SPAN 
                style: 
                  paddingLeft: 8
                "(+#{proposals.length - list_state.show_first_num_items})"


      if customization('footer', list_key) && !is_collapsed
        customization('footer', list_key)()

ListItems = ReactiveComponent
  displayName: 'ListItems'

  render: ->
    list = @props.list 
    list_key = list.key

    sort_key = "sorted-proposals-#{list_key}"
    proposals = if !@props.fresh then sorted_proposals(list.proposals, sort_key, true) or [] else []

    RenderListItem = customization('RenderListItem') or CollapsedProposal

    if @props.combines_these_lists
      hues = getNiceRandomHues @props.combines_these_lists.length
      colors = {}
      for aggregated_list, idx in @props.combines_these_lists
        colors[aggregated_list] = hues[idx]

    DIV null, 

      UL null, 
        for proposal,idx in proposals
          continue if idx > @props.show_first_num_items - 1

          RenderListItem
            key: "collapsed#{proposal.key}"
            proposal: proposal.key
            show_category: !!@props.combines_these_lists
            category_color: if @props.combines_these_lists then hsv2rgb(colors["list/#{(proposal.cluster or 'Proposals')}"], .9, .8)

        if @props.show_new_button

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




__remove_this_list = (list_key, page) ->
  subdomain = fetch '/subdomain'
  list_key = list_key.key or list_key
  tabs = get_tabs()

  customizations = subdomain.customizations

  if tabs
    page ?= get_current_tab_name()
    for tab in tabs
      if tab.name == page
        if (idx = tab.lists.indexOf(list_key)) > -1
          tab.lists.splice idx, 1
        break

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
      marginBottom: 16 #24
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

      if @props.proposals_count > 0 && !customization('questionaire', list_key, subdomain) && !is_collapsed && !customization('list_no_filters', list_key, subdomain)
        list_actions
          list: @props.list
          add_new: !@props.combines_these_lists && customization('list_permit_new_items', list_key, subdomain) && !is_collapsed && @props.proposals_count > 4
          can_sort: customization('homepage_show_search_and_sort', null, subdomain) && @props.proposals_count > 1 
          fresh: @props.fresh



window.NewList = ReactiveComponent
  displayName: 'NewList'

  render: -> 
    subdomain = fetch '/subdomain'

    @local.hovering ?= false

    if @local.editing
      ModalNewList 
        fresh: true
        done_callback: =>
          @local.editing = false 
          save @local


    else 
      BUTTON 
        style: 
          textAlign: 'left'
          marginTop: 35
          display: 'block'
          padding: get_list_padding()
          position: 'relative'
          # left: -24
          width: '100%'
          borderRadius: 8
          backgroundColor: if @local.hovering then '#eaeaea' # else 'white'
          # border: '1px solid'
          # borderColor: if @local.hovering then '#bbb' else '#ddd'

        onMouseEnter: =>
          @local.hovering = true 
          save @local 
        onMouseLeave: => 
          @local.hovering = false
          save @local 

        onClick: =>
          @local.editing = true 
          save @local

        H1
          className: 'LIST-header'
          style: 
            color: if @local.hovering then '#444' else '#666'
            textDecoration: 'underline'
          translator 'engage.create_new_list_button', "Create a new Topic"

        DIV 
          style: 
            fontSize: 14
            marginTop: 4
          'A Topic collects proposals under a category like "Recommendations" or in response to an open-ended question like "What are your ideas?"'




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
              'aria-label': "#{title}. #{translator('Expand or collapse list.')}"
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

  add_new = props.add_new
  if add_new 
    permitted = permit('create proposal', list_key)
    add_new &&= permitted > 0 || permitted == Permission.NOT_LOGGED_IN


  DIV   
    className: 'list_actions'
    style: 
      marginBottom: 50
      marginTop: 24
      display: 'flex'

    DIV 
      style: 
        width: column_sizes().first + 58
        marginRight: column_sizes().gutter
        display: 'flex'

      if add_new

        SPAN 
          style: 
            minWidth: 78

          A
            style: 
              fontSize: 14
              color: focus_color()
              fontFamily: customization('font')
              fontStyle: 'normal'
              fontWeight: 700
            onClick: (e) => 
              list_state = fetch list_key
              list_state.show_all_proposals = true 
              save list_state
              e.stopPropagation()

              wait_for = ->
                add_new_button = $("[name='new_#{props.list.key.substring(5)}']")
                if add_new_button.length > 0 
                  add_new_button.ensureInView()
                  add_new_button.click()
                else 
                  setTimeout wait_for, 1

              wait_for()

            '+ '

            SPAN 
              style: 
                textDecoration: 'underline'
              translator "engage.add_new_proposal_to_list", 'add new'

      if props.can_sort && add_new
        SPAN 
          style: 
            padding: '0 12px'

      if props.can_sort
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
    eligible_lists = get_tab(tab).lists
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















