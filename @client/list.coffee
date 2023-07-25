require './modal'
require './edit_list'
require './item'


PROPOSAL_AUTHOR_AVATAR_SIZE = 40
PROPOSAL_AVATAR_GUTTER = 18
PROPOSAL_AUTHOR_AVATAR_SIZE_SMALL = 20
PROPOSAL_AVATAR_GUTTER_SMALL = 12


window.styles += """
  :after,
  :root {
    --PROPOSAL_BULLET_GUTTER: 12px; 
    --AVATAR_SIZE_AND_GUTTER: calc(var(--PROPOSAL_AUTHOR_AVATAR_SIZE) + var(--PROPOSAL_AUTHOR_AVATAR_GUTTER));

    --LIST_PADDING_FULL: var(--LIST_PADDING_TOP) var(--LIST_PADDING_RIGHT) var(--LIST_PADDING_BOTTOM) var(--LIST_PADDING_LEFT);
  }


  @media #{LAPTOP_MEDIA} {
    :root, :before, :after {
      --ITEM_TEXT_WIDTH:    calc( .6 * (var(--HOMEPAGE_WIDTH) - var(--LIST_PADDING_LEFT) - var(--AVATAR_SIZE_AND_GUTTER) - var(--PROPOSAL_AUTHOR_AVATAR_SIZE)) );
      --ITEM_OPINION_WIDTH: calc( .4 * (var(--HOMEPAGE_WIDTH) - var(--LIST_PADDING_RIGHT)) );      
    
      --LIST_PADDING_TOP: 48px;
      --LIST_PADDING_BOTTOM: 48px;
      --LIST_PADDING_RIGHT: 66px;
      --LIST_PADDING_LEFT: 66px;

    }
  }

  @media #{TABLET_MEDIA} {
    :root, :before, :after {
      --ITEM_TEXT_WIDTH:    calc( var(--HOMEPAGE_WIDTH) - var(--AVATAR_SIZE_AND_GUTTER) );
      --ITEM_OPINION_WIDTH: calc( var(--HOMEPAGE_WIDTH) - var(--AVATAR_SIZE_AND_GUTTER) );  

      --LIST_PADDING_TOP: 0px;
      --LIST_PADDING_BOTTOM: 0px;
      --LIST_PADDING_RIGHT: 4px;
      --LIST_PADDING_LEFT: 4px;

    }
  }


  @media #{PHONE_MEDIA} {
    :root, :before, :after {
      --PROPOSAL_AUTHOR_AVATAR_SIZE: #{PROPOSAL_AUTHOR_AVATAR_SIZE_SMALL}px;
      --PROPOSAL_AUTHOR_AVATAR_GUTTER: #{PROPOSAL_AVATAR_GUTTER_SMALL}px;
      --ITEM_TEXT_WIDTH:    calc( var(--HOMEPAGE_WIDTH) - var(--AVATAR_SIZE_AND_GUTTER) );
      --ITEM_OPINION_WIDTH: calc( var(--HOMEPAGE_WIDTH) - var(--AVATAR_SIZE_AND_GUTTER) );  

      --LIST_PADDING_TOP: 0px;
      --LIST_PADDING_BOTTOM: 0px;
      --LIST_PADDING_RIGHT: 2px;
      --LIST_PADDING_LEFT: 2px;
    }
  }

  @media #{NOT_PHONE_MEDIA} {
    :root, :before, :after {
      --PROPOSAL_AUTHOR_AVATAR_SIZE: #{PROPOSAL_AUTHOR_AVATAR_SIZE}px;
      --PROPOSAL_AUTHOR_AVATAR_GUTTER: #{PROPOSAL_AVATAR_GUTTER}px;
    }
  }
"""

responsive_style_registry.unshift (responsive_vars) -> 
  homepage_width = responsive_vars.HOMEPAGE_WIDTH
  tablet_size = responsive_vars.TABLET_SIZE
  phone_size = responsive_vars.PHONE_SIZE

  # list padding; keep in sync with LIST_PADDING_* vars defined above in list.coffee
  if tablet_size
    right = left = 4
    top = bottom = 0
  else 
    right = 90
    left = 66
    top = bottom = 48

  if phone_size 
    avatar_spacing = PROPOSAL_AUTHOR_AVATAR_SIZE_SMALL + PROPOSAL_AVATAR_GUTTER_SMALL
  else 
    avatar_spacing = PROPOSAL_AUTHOR_AVATAR_SIZE + PROPOSAL_AVATAR_GUTTER


  {
    LIST_PADDING_TOP: top
    LIST_PADDING_RIGHT: right
    LIST_PADDING_LEFT: left
    LIST_PADDING_BOTTOM: bottom

    # keep in sync with css variables of same name defined above in list.coffee
    AVATAR_SIZE_AND_GUTTER: avatar_spacing
    AVATAR_SIZE: if phone_size then PROPOSAL_AUTHOR_AVATAR_SIZE_SMALL else PROPOSAL_AUTHOR_AVATAR_SIZE
    ITEM_TEXT_WIDTH:    if tablet_size then homepage_width - avatar_spacing else .6 * (homepage_width - left - avatar_spacing - PROPOSAL_AUTHOR_AVATAR_SIZE)
    ITEM_OPINION_WIDTH: if tablet_size then homepage_width - avatar_spacing else .4 * (homepage_width - right)
    LIST_ITEM_EXPANSION_SCALE: if tablet_size then 1 else 1.25
  }







window.styles += """
  .List, .NewList, .draggable-wrapper {
    background-color: white;
    border: none;
    border-radius: 16px;
    box-shadow: -1px 1px 2px rgb(0 0 0 / 15%);
    border-top: 1px solid #f3f3f3;
  }


  .List {
    margin-bottom: 60px;
    position: relative; 
    padding: var(--LIST_PADDING_FULL);   
  }

  .one-col .List, .one-col .NewList, .embedded-demo .List, .embedded-demo .NewList {
    border-top: none;
    box-shadow: none;
  }

  # .embedded-demo .List {
  #   padding: 0;
  # }


  .LIST_item_connector {
    display: none;
    /* position: absolute;
    height: calc(100% - var(--PROPOSAL_AUTHOR_AVATAR_SIZE) - 28px);
    width: 1px;
    background-color: #ccc;
    left: calc(50% - var(--HOMEPAGE_WIDTH) / 2 + var(--PROPOSAL_AUTHOR_AVATAR_SIZE)/2);
    top: 28px;  /* half the line height of the list header */
    z-index: 0; */ 
  }
"""

window.list_link = (list_key) ->
  list_key.substring(5).toLowerCase().replace(/ /g, '_')

window.SHOW_FIRST_N_PROPOSALS = 6

window.List = ReactiveComponent
  displayName: 'List'


  # list of proposals
  render: -> 
    current_user = fetch '/current_user'
    
    list = get_list(@props.list)


    list_key = list.key

    # subscribe to a key that will alert us to when sort order has changed
    fetch('homepage_you_updated_proposal')

    proposals = list.proposals or []

    list_state = fetch list_key
    list_state.show_first_num_items ?= @props.show_first_num_items or customization('show_first_n_proposals', list_key) or SHOW_FIRST_N_PROPOSALS
    list_state.collapsed ?= customization('list_is_archived', list_key)

    is_collapsed = list_state.collapsed

    edit_list = fetch "edit-#{list_key}"

    if edit_list.editing
      return  EditNewList
                list: list
                fresh: false
                combines_these_lists: @props.combines_these_lists
                done_callback: => 
                  edit_list.editing = false 
                  save edit_list

    ARTICLE
      key: list_key
      className: "List"
      id: list_key.substring(5).toLowerCase()
      style:  if screencasting()
                boxShadow: 'none'
                borderTop: 'none'
                paddingTop: 0 

      A name: list_link(list_key)

      DIV
        ref: 'LIST_item_connector'
        className: 'LIST_item_connector'

      ListHeader 
        list: list
        combines_these_lists: @props.combines_these_lists 
        proposals_count: proposals.length
        fresh: @props.fresh
        allow_editing: !@props.allow_editing? || @props.allow_editing

      if !is_collapsed && !@props.fresh
        
        permitted = permit('create proposal', list_key)

        ListItems 
          list: list 
          key: "#{list.key}-items"
          fresh: @props.fresh
          show_first_num_items: if list_state.show_all_proposals then 999999 else list_state.show_first_num_items
          combines_these_lists: @props.combines_these_lists
          # show_new_button: (list_state.show_all_proposals || proposals.length <= list_state.show_first_num_items) && \
          #    ((@props.combines_these_lists && lists_current_user_can_add_to(@props.combines_these_lists).length > 0) || (permitted > 0 || permitted == Permission.NOT_LOGGED_IN) )
          show_new_button: (@props.combines_these_lists && lists_current_user_can_add_to(@props.combines_these_lists).length > 0) || (permitted > 0 || permitted == Permission.NOT_LOGGED_IN)
          expansion_key: @props.expansion_key


      if customization('footer', list_key) && !is_collapsed
        customization('footer', list_key)()



styles += """

  .show-all-proposals {
    list-style: none;
    position: relative;
    margin-top: -105px;
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

  .ListItems {
    min-height: 0px;
    transition: min-height 0s ease-out;
  }
"""


ListItems = ReactiveComponent
  displayName: 'ListItems'

  render: ->
    list = @props.list 
    list_key = list.key

    sort_key = "sorted-proposals-#{list_key}"

    proposals = if !@props.fresh then sorted_proposals(list.proposals, sort_key, true) or [] else []


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
              paddingLeft: "var(--PROPOSAL_AUTHOR_AVATAR_GUTTER)"
              color: '#444'
              fontWeight: 400
            "+#{proposals.length - @props.show_first_num_items}"



    render_new = =>
      LI 
        key: "new#{list_key}"
        style: 
          padding: 0
          listStyle: 'none'
          margin: "24px auto"
          position: 'relative'
          
        NewProposal 
          list_key: list_key
          combines_these_lists: @props.combines_these_lists  

    loc = fetch 'location'
    proposals_to_render = []
    for p, idx in proposals
      passes_idx_test = idx < @props.show_first_num_items && passes_running_timelapse_simulation(p.created_at)
      passes_url_test = loc.url == "/#{p.slug}"
      if passes_idx_test || passes_url_test
        proposals_to_render.push p
      if idx >= @props.show_first_num_items && loc.url == '/'
        break 

    sorted_key = md5 (p.key for p in proposals_to_render).join('###')
    list_order_has_changed = @last_sorted_key? && @last_sorted_key != sorted_key
    @last_sorted_key = sorted_key

    if list_order_has_changed
      schedule_viewport_position_check()

    expansion_key = @get_expansion_key()

    more_expanded = @last_expansion_key? && expansion_key.length > @last_expansion_key.length
    expansion_state_changed = @last_expansion_key? && @last_expansion_key != expansion_key 

    @last_expansion_key = expansion_key

    expanded_state = fetch "proposal_expansions-#{list.key}"

    len = proposals_to_render.length

    url = fetch('location').url

    # This flipper tracks list order and proposal expansion. 
    # Be wary of a bug in react-flip-toolkit that interferes 
    # with nested flippers working.

    FLIPPER
      flipKey: sorted_key + expansion_key
      spring: PROPOSAL_ITEM_SPRING

      onStart: (el) => 
        el.classList.add "flipping"
        if expansion_state_changed
          el.classList.add "expansion_event"
          if !more_expanded && @last_expanded_height?
            @refs.list_wrapper.style.transitionDuration = "0s"
            @refs.list_wrapper.style.minHeight = "#{@last_expanded_height}px"

            setTimeout =>
              requestAnimationFrame => 
                @refs.list_wrapper.style.transitionDuration = "1s"
                @refs.list_wrapper.style.minHeight = null
            , 600

        if list_order_has_changed
          el.classList.add "list_order_event"

      onComplete: (el) => 
        el.classList.remove "flipping", "expansion_event", "list_order_event"

        if expansion_state_changed && more_expanded
          @last_expanded_height = @refs.list_wrapper.clientHeight
        

      UL 
        className: 'ListItems'
        ref: 'list_wrapper'

        if !list.proposals
          LI 
            style: 
              listStyle: 'none'
            className: 'sized_for_homepage'
            ProposalsLoading()  

        for proposal,idx in proposals_to_render
          ProposalItem
            key: "collapsed#{proposal.key}"
            proposal: proposal.key
            list_key: list_key
            list_order: sorted_key
            show_list_title: !!@props.combines_these_lists
            list_title_color: if @props.combines_these_lists then hsv2rgb(colors["list/#{(proposal.cluster or 'Proposals')}"], 1, .7)
            is_expanded: !!expanded_state[proposal.key]
            accessed_by_url: url == "/#{proposal.slug}"
            num_proposals: len


        if proposals.length > @props.show_first_num_items 
          FLIPPED 
            flipId: "show-all-#{list_key}"
            translate: true
            shouldFlip: => expansion_state_changed

            show_all_button()


        if @props.show_new_button
          FLIPPED 
            flipId: "new-button-#{list_key}"
            translate: true
            shouldFlip: => expansion_state_changed

            render_new()


  get_expansion_key: ->

    expanded_state = fetch "proposal_expansions-#{@props.list.key}"
    expansion_key = ("#{key}-#{state}" for key, state of expanded_state when key != 'key').join('###')
    expansion_key    


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












styles += """
  .ListHeader-wrapper {
    display: flex;
  }

  @media #{NOT_LAPTOP_MEDIA} {

    .ListHeader-wrapper {
      padding-top: 12px;
      padding-bottom: 12px;
      position: relative;
      margin-left: calc(-1 * var(--LIST_PADDING_LEFT) - var(--homepagetab_left_padding) );
      padding-left: calc(var(--LIST_PADDING_LEFT) + var(--homepagetab_left_padding) );
      width: calc(100% + var(--LIST_PADDING_LEFT) + var(--LIST_PADDING_RIGHT) + var(--homepagetab_left_padding));
    }

    .ListHeader-wrapper, button.NewList {
      background-color: #eee;
    }

  }


  .text-wrapper {
    // padding-left: var(--AVATAR_SIZE_AND_GUTTER);    
    position: relative;
    width: 100%;
  }

  @media #{TABLET_MEDIA} {
    .text-wrapper {
      width: calc(var(--AVATAR_SIZE_AND_GUTTER) + var(--ITEM_TEXT_WIDTH) - 24px);
      margin-left: 24px;
    }
  }

  @media #{PHONE_MEDIA} {
    .text-wrapper {
      margin-left: 24px;
      width: calc(var(--AVATAR_SIZE_AND_GUTTER) + var(--ITEM_TEXT_WIDTH) - 24px);
    }
  }


  .avatar-spacing {
    width: var(--AVATAR_SIZE_AND_GUTTER);
    min-height: 1px;
    flex-grow: 0;
    flex-shrink: 0;
  }

"""




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

      

    DIV 
      className: 'ListHeader'
      style: 
        marginBottom: if !is_collapsed then 16 #24 

      DIVIDER?()


      DIV 
        className: 'ListHeader-wrapper'

        CollapseList list_key          

        # DIV 
        #   className: 'avatar-spacing'


        DIV 
          className: 'text-wrapper'

          EditableTitle
            list: @props.list
            fresh: @props.fresh

          if !is_collapsed && (description?.length > 0 || typeof(description) == 'function')
            EditableDescription
              list: @props.list
              fresh: @props.fresh


        if @props.allow_editing
          EditList
            list: @props.list
            fresh: @props.fresh
            combines_these_lists: @props.combines_these_lists

      if @props.proposals_count > 0 && !is_collapsed && !customization('list_no_filters', list_key, subdomain)
        ListActions
          list: @props.list
          add_new: !@props.combines_these_lists && customization('list_permit_new_items', list_key, subdomain) && !is_collapsed && @props.proposals_count > 4
          can_sort: customization('homepage_show_search_and_sort', null, subdomain) && @props.proposals_count > 1 
          fresh: @props.fresh





styles += """
  .NewList, .EditingNewList {
    border: 3px dashed #{focus_color()}aa;
    transition: border 500ms;    
    box-shadow: none;
  }

  .NewList {
    text-align: left;
    margin-top: 55px;
    display: block;
    position: relative;
    padding: var(--LIST_PADDING_TOP) 56px var(--LIST_PADDING_BOTTOM) 56px;
    width: 100%;
  }

  .NewList:hover, .EditingNewList:hover,
  .NewList:focus-within, .EditingNewList:focus-within {
    border-color: #{focus_blue};
  }

  @media #{NOT_LAPTOP_MEDIA} {
    button.NewList, .EditingNewList {
      border-radius: 0px;
      border: none;
    }
    button.NewList {
      padding: 24px 12px;
    }

  }

  .NewList .LIST-title {
    text-align: center;
  }


  .NewList .LIST-title span {
    position: relative;
    color: #{focus_blue};
    border-bottom-width: 2px;
    border-bottom-color: #{focus_blue}aa;
    border-bottom-style: solid;
    transition: border-bottom 500ms;
  }

  .NewList:hover .LIST-title span,
  .NewList:focus-within .LIST-title span {
    border-bottom-color: #{focus_blue};
  }

  .NewList .LIST-description {
    text-align: center;
  }

  .NewList.draggable-list .LIST-description {
    display: none;
  }

  .NewList.draggable-list .LIST-title {
    text-align: left;
    padding-left: 45px;
  }

"""


window.NewList = ReactiveComponent
  displayName: 'NewList'

  render: -> 
    subdomain = fetch '/subdomain'

    wide_layout = WINDOW_WIDTH() > 1090 

    @local.hovering ?= false

    DIV null, 
      if @local.editing
        EditNewList 
          fresh: true
          default_open_ended: @local.default_open_ended
          done_callback: =>
            @local.editing = false 
            save @local

      else 
        BUTTON
          className: "NewList #{if @props.wrapper_clss then @props.wrapper_clss else ''} " 

          onClick: (e) =>
            @local.editing = true 
            @local.default_open_ended = e.target.classList.contains('open')
            save @local

          H1
            className: 'LIST-title'

            SPAN null, 

              translator "engage.create_new_focus", "Create a New Focus"
            
          DIV 
            className: 'LIST-description'

            translator "engage.focus_description", "Focus your community on evaluating specific proposals. Or pose an open-ended question to focus your community on generating ideas."



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
      subdomain = fetch('/subdomain')
      translator 
        id: "engage.add_new_#{item_name}_to_list"
        local: true
      , "Add a new #{item_name}"
  opinion_header: (list_key) ->
    item_name = customization('list_item_name', list_key)
    if item_name
      item_name = capitalize item_name
    if !item_name || item_name.toLowerCase() == 'proposal' 
      translator "engage.opinion_header_results", 'Opinions about this proposal'
    else 
      subdomain = fetch('/subdomain')
      translator 
        id: "engage.opinion_header_results_#{item_name}"
        local: true
      , "Opinions about this #{item_name}"



styles += """
  .LIST-title {
    font-size: 35px;
    font-weight: 600;
    text-align: left;
  }

  .LIST-title-wrapper {
    position: relative;
    text-align: center;
    outline: none;
  }

  @media #{TABLET_MEDIA} {
    .LIST-title {
      font-size: 28px;
    }  
  }
  @media #{PHONE_MEDIA} {
    .LIST-title {
      font-size: 22px; 
      // margin-left: 28px; 
    }  

    .EditableTitle {
      // margin-right: 24px;
    }

  }


"""

EditableTitle = ReactiveComponent
  displayName: 'EditableTitle'

  render: -> 
    list = @props.list 
    list_key = list.key

    subdomain = fetch '/subdomain'

    title = get_list_title list_key, true, subdomain

    DIV 
      className: 'EditableTitle'

      H1 
        className: 'LIST-title'
        style: # ugly...we only want to show the expand/collapse icon
          fontSize: if title.replace(/^\s+|\s+$/g, '').length == 0 then 0

        DIV
          className: 'LIST-title-wrapper condensed'
          style: customization('list_label_style', list_key, subdomain) or {}

          title 



COLLAPSE_ICON_SIZE = 40

styles += """

  .CollapseList {
    border: none;
    background-color: transparent;
    padding: 0; 
    margin: 0; 
    line-height: 0;
    cursor: pointer;
  }

  .embedded-demo .CollapseList {
    display: none;
  }

  @media #{LAPTOP_MEDIA} {
    .CollapseList {
      transition: transform .25s, top .25s;
      position: absolute;
      left: calc(50% - #{COLLAPSE_ICON_SIZE / 2}px);
      bottom: #{-COLLAPSE_ICON_SIZE / 2}px;
    }

    .CollapseList svg {

    }

    .CollapseList.collapsed {
      transform: scaleY(-1);
    }

    .CollapseList.expanded {
    }    
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .CollapseList {
      border: none;
      background-color: transparent;
      padding: 0; 
      margin: 0; 
      position: absolute;
      cursor: pointer;
      transition: transform .25s, top .25s;
      top: 22px;
      left: 6px;
    }

    .CollapseList svg {
      position: relative;
      left: 0;
    }

    .CollapseList.collapsed {
    }

    .CollapseList.expanded {
      transform: rotate(90deg);
    }

    .embedded-demo .CollapseList {
      display: none;
    }

  }


"""


CollapseList = (list_key) -> 
  subdomain = fetch '/subdomain'

  list_uncollapseable = customization 'list_uncollapseable', list_key, subdomain
  return SPAN null if list_uncollapseable

  list_state = fetch list_key
  is_collapsed = list_state.collapsed

  toggle_list = (collapse_button) ->
    list_el = collapse_button.closest('.List')
    el = list_el.querySelector('.LIST-title')
    $$.ensureInView el,
      # extra_height: if !expanded_state[proposal.key] then 400 else 0
      # force: mode == 'crafting'
      offset_buffer: 120


      callback: ->

        if !list_state.collapsed

          # google translate widget causes weird behavior when animating height of document
          google_translate = document.querySelector('[data-widget="GoogleTranslate"]')
          google_translate?.style.display = "none"

          list_el.style.transition = "max-height 1000ms ease"
          padding_el = if TABLET_SIZE() then list_el.querySelector('.ListHeader-wrapper') else list_el
          sty = getComputedStyle padding_el

          list_el.style.maxHeight = "#{list_el.clientHeight}px"
          list_el.style.overflow = 'hidden'

          # this maxheight calculation isn't right anymore...padding is now elsewhere :-(
          list_el.style.maxHeight = "calc(#{el.clientHeight}px + #{sty.paddingTop} + #{sty.paddingBottom})"

          setTimeout ->

            list_state.collapsed = !list_state.collapsed
            save list_state

            setTimeout ->
              list_el.style.transition = ''
              list_el.style.maxHeight = ''
              list_el.style.overflow = ''
              setTimeout -> 
                google_translate?.style.display = ""     
              , 1000
            , 100

          , 1000
        else 
          list_state.collapsed = !list_state.collapsed
          save list_state


  BUTTON 
    className: "CollapseList #{if is_collapsed then 'collapsed' else 'expanded'}"
    'aria-label': translator('accessibility-expand-or-collapse-list', 'Expand or collapse list.')
    'aria-pressed': !is_collapsed
    # 'data-tooltip': translator('accessibility-expand-or-collapse-list', 'Expand or collapse list.')

    onClick: (e) -> 
      toggle_list(e.target)
      document.activeElement.blur()
      e.stopPropagation()

    'aria-hidden': true

    if !TABLET_SIZE()
      double_up_icon(COLLAPSE_ICON_SIZE)
    else 
      ChevronRight 18






styles += """
  .LIST-description {
    font-size: 16px;
    font-weight: 400;
    color: black;
    margin-top: 14px;
    margin-bottom: 18px;
    padding: 0px var(--AVATAR_SIZE_AND_GUTTER);
    /* font-style: italic; */
  }

  @media #{PHONE_MEDIA} {
    .LIST-description {
      padding: 0px 0px;
    }
  }

  .LIST-description.single-line {
    text-align: center;
  }

"""

EditableDescription = ReactiveComponent
  displayName: 'EditableDescription'

  getDescription: -> 
    list = @props.list 
    list_key = list.key

    description = customization('list_description', list_key)
    if Array.isArray(description)
      description = description.join('\n')

    description

  setAlignment: ->
    description = @getDescription()
    is_func = typeof description == 'function'

    if !is_func
      return if !@refs.description
      height = @refs.description.clientHeight
      single_line = height < 24

      if single_line
        @refs.description.classList.add 'single-line'
      else
        @refs.description.classList.remove 'single-line'

  componentDidMount: -> @setAlignment()
  componentDidUpdate: -> @setAlignment()

  render: -> 
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = list.key

    description = @getDescription()
  
    return SPAN null if !description

    is_func = typeof description == 'function'

    description_style = customization 'list_description_style', list_key

    WINDOW_WIDTH() # subscribe to window size changes for alignment
    
    DIV
      style: _.defaults {}, (description_style or {})
      className: "LIST-description #{if !is_func then 'wysiwyg_text' else ''}"
      ref: 'description'

      if is_func
        description()        
      else 
        DIV 
          style:
            marginBottom: 10
          dangerouslySetInnerHTML: {__html: description}






styles += """
  .list_actions_wrapper {
    margin: 24px 0;
  }
  .ListActions {
    display: flex;
    align-items: baseline;

    flex-direction: row;

    position: relative;
    left: calc(-1 * var(--LIST_PADDING_LEFT));
    width: calc(100% + var(--LIST_PADDING_LEFT) + var(--LIST_PADDING_RIGHT) );
  }

  .opinion-view-container {
    flex-shrink: 0;  
    width: var(--ITEM_OPINION_WIDTH);  
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .ListActions {
      flex-direction: column;
      align-items: center;
      width: calc(var(--AVATAR_SIZE_AND_GUTTER) + var(--ITEM_TEXT_WIDTH));
      left: 0;
      margin: auto;
    }

    .opinion-view-container {  
      width: auto;  
    }
  }

  .sort_menu_wrapper {
    width: 100%;
    margin-left: var(--AVATAR_SIZE_AND_GUTTER); 
    display: flex;
  }

"""

window.ListActions = (props) -> 
  list_key = props.list.key

  DIV 
    className: 'list_actions_wrapper'

    DIV   
      className: 'ListActions'

      DIV 
        className: 'proposal-left-spacing'
          
      DIV 
        className: 'sort_menu_wrapper'

        if !TABLET_SIZE() && props.can_sort
          # [ SortProposalsMenu(), FilterProposalsMenu() ]
          SortProposalsMenu()


        if !props.fresh
          sort_key = "sorted-proposals-#{list_key}"
          SPAN 
            style: 
              display: 'inline-block'
              marginLeft: 12
            
            ManualProposalResort {sort_key}

      DIV 
        className: 'proposal-slidergram-spacing'        

      DIV 
        className: 'opinion-view-container'

        OpinionViews
          ui_key: "opinion-views-#{list_key}"
          style: 
            marginBottom: 20


      DIV 
        className: "proposal-score-spacing"

    DIV null,
      OpinionViewInteractionWrapper
        ui_key: "opinion-views-#{list_key}"
        more_views_positioning: if TABLET_SIZE() then 'centered' else 'right'      
        width: ITEM_OPINION_WIDTH() + AVATAR_SIZE_AND_GUTTER() + ITEM_TEXT_WIDTH()


window.get_list_title = (list_key, include_category_value, subdomain) -> 
  subdomain ?= fetch('/subdomain')
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
  fetch('/lists').lists or []

window.get_all_lists_not_configured_for_a_page = ->
  lists = fetch('/lists').lists or []

  if get_tabs()
    all_configured_lists = {}
    unconfigured_lists = {}
    for tab in get_tabs()
      for l in tab.lists 
        if l != '*' && l != '*-'
          all_configured_lists[l] = 1


    for lst in lists
      if lst not of all_configured_lists
        unconfigured_lists[k] = 1

    Object.keys(unconfigured_lists)

  else 
    return []



window.get_list_sort_method = (tab) ->
  tab ?= get_current_tab_name()
  get_tab(tab)?.list_sort_method or customization('list_sort_method') or \
    (if customization('lists') || get_tabs() then 'fixed' else 'newest_item')

window.get_list_for_proposal = (proposal) ->
  if !proposal.key
    proposal = fetch proposal
  "list/#{(proposal.cluster or 'Proposals').trim()}"  

lists_ordered_by_most_recent_update = {}
lists_ordered_by_randomized = {}

window.get_lists_for_page = (tab) -> 
  homepage_tabs = fetch 'homepage_tabs'
  tab ?= get_current_tab_name()
  tabs_config = get_tabs()
  lists = get_all_lists()

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
      for ll in lists
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

      for ll in lists
        if ll not of referenced_elsewhere && ll not in eligible_lists
          lists_in_tab.push ll

    else 
      lists_in_tab.push list


  ######################################################
  # ...and finally, let's sort the lists if there's a different sorted order other than fixed

  list_sort_method = get_list_sort_method(tab)

  if list_sort_method == 'newest_item'

    # Sort lists by the newest of its proposals.
    # But we'll only do this on page load or if the number of lists has changed, 
    # so that lists don't move around when someone adds a new proposal.
    lists_ordered_by_most_recent_update[tab] ?= {}
    by_recency = lists_ordered_by_most_recent_update[tab]
    current_time = (new Date()).getTime()

    ready = true 

    for lst in lists_in_tab
      server_lst = '/' + lst
      if !arest.cache[server_lst]?.proposals
        fetch(server_lst).proposals or []
        ready = false

    return lists_in_tab if !ready || lists_in_tab.length == 0 


    if Object.keys(by_recency).length != lists_in_tab.length
      for lst in lists_in_tab
        proposals = fetch('/' + lst).proposals or []
        by_recency[lst] = -1 # in case there aren't any proposals in it
        for proposal in proposals
          time = (new Date(proposal.created_at).getTime())
          if !by_recency[lst] || time > by_recency[lst]
            by_recency[lst] = time

    lists_in_tab.sort (a,b) -> ( (current_time - by_recency[a]) or 99999999999) - ( (current_time - by_recency[b]) or 99999999999)

  else if list_sort_method == 'randomized'
    lists_ordered_by_randomized[tab] ?= {}
    by_random = lists_ordered_by_randomized[tab]
    if Object.keys(by_random).length != lists_in_tab.length
      for lst in lists_in_tab
        by_random[lst] = Math.random()

    lists_in_tab.sort (a,b) -> (by_random[a] or 99999999999) - (by_random[b] or 99999999999)


  lists_in_tab


window.get_proposals_in_list = (list_key) -> 
  list = fetch "/#{list_key}"
  list.proposals


window.get_list = (list_key) ->
  return list_key if list_key.key
  lst = _.extend {}, customization(list_key),
    key: list_key
    proposals: get_proposals_in_list(list_key)

window.lists_current_user_can_add_to = (lists) -> 
  appendable = []
  for list_key in lists 
    if permit('create proposal', list_key) > 0
      appendable.push list_key 
  appendable















