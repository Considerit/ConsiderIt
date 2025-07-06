
window.SubdomainSaveRateLimiter =  

  save_customization_with_rate_limit: ({fields, config, force_save, on_save_callback, wait_for}) ->
    subdomain = bus_fetch '/subdomain'

    config ?= subdomain.customizations
    fields ?= []
    
    changed = force_save
    for f in fields
      val = @local[f]

      if val? && JSON.stringify(val) != JSON.stringify(config[f])
        if val == '*delete*'
          if config[f]?
            delete config[f] 
            changed = true 
        else 
          config[f] = val
          changed = true

    if changed
      @save_in = wait_for or 1000
      @save_interval ?= setInterval =>
        @save_in -= 500
        if @save_in <= 0
          console.log "SAVING SUBDOMAIN", fields
          save subdomain, =>
            on_save_callback?()
          clearInterval(@save_interval)
          @save_interval = undefined
      , 500




# handles tab query parameter based on tabs state
window.HomepageTabTransition = ReactiveComponent
  displayName: "HomepageTabTransition"

  render: -> 
    if get_tabs()
      loc = bus_fetch 'location'
      tab_state = bus_fetch 'homepage_tabs'
      default_tab = customization('homepage_default_tab') or get_tabs()[0]?.name or 'Show all'

      tab_state_changing = (loc.query_params.tab && loc.query_params.tab != tab_state.active_tab)

      if !tab_state.active_tab? || tab_state_changing

        if loc.query_params.tab && get_tab(decodeURIComponent(loc.query_params.tab))
          tab_state.active_tab = decodeURIComponent(loc.query_params.tab)
        else if is_a_dialogue_page() && loc.url != '/' # if we have a focus on a particular item
          slug = loc.url.substring(1)
          find_tab = null

          look_for_tab_for_proposal = =>
            key = "/page/#{slug}"
            page = arest.cache[key]
            @checked_times += 1
            proposal = null

            if page?.proposal

              proposal = bus_fetch(page.proposal)
              if proposal.name
                list = get_list_for_proposal proposal
                tab = get_page_for_list list

                tab_state.active_tab = tab
                save tab_state

                if find_tab != null
                  clearInterval find_tab

            if @checked_times > 100 && find_tab != null
              clearInterval find_tab

            !!proposal

          result = look_for_tab_for_proposal()
          if !result 
            @checked_times = 0
            find_tab = setInterval look_for_tab_for_proposal, 100

        else 
          tab_state.active_tab = default_tab

        if tab_state_changing
          # clear out all records of expanded proposals
          for k,v of arest.cache 
            if k.startsWith 'proposal_expansions-'
              for kk, vv of v
                v[kk] = false



        save tab_state



      if loc.query_params.tab != tab_state.active_tab
        loc.query_params.tab = tab_state.active_tab
        save loc

    SPAN null







window.get_tabs = -> 
  if bus_fetch('/subdomain').customizations?.homepage_tabs?.length > 0 
    tabs = bus_fetch('/subdomain').customizations.homepage_tabs
    
    # hack to fix a bug I haven't found where a tab can have a null name
    idx = tabs.length - 1
    while idx >= 0 
      if tabs[idx].name == null
        tabs.splice idx, 1
      idx -= 1

    tabs
  else 
    null

window.get_tab = (name) -> 
  name ?= get_current_tab_name()
  for tab in (get_tabs() or [])
    if tab.name == name 
      return tab
  return null

window.get_current_tab_name = -> bus_fetch('homepage_tabs').active_tab or null
window.get_current_tab_view = (args) ->
  tabs = customization('homepage_tabs') 
  if !tabs
    return SimpleHomepage(args)

  custom_view = null
  for tab in tabs
    if tab.name == get_current_tab_name()
      if tab.render_page
        custom_view = tab.render_page
      break
  if !custom_view
    custom_view = customization('render_page')

  if custom_view
    view = custom_view(args)
    if typeof(view) == 'function'
      view = view(args)
    view
  else
    SimpleHomepage(args)

window.get_page_preamble = (tab_name) -> 
  if tab = get_tab(tab_name)
    preamble = tab.page_preamble
  else 
    preamble = customization('page_preamble')


window.create_new_tab = (tab_name) ->
  subdomain = bus_fetch('/subdomain')

  tabs = get_tabs()

  idx = 2
  new_tab_name = tab_name

  while !!get_tab(new_tab_name)
    new_tab_name = "#{tab_name}-#{idx}"
    idx += 1

  if !tabs
    tabs = subdomain.customizations.homepage_tabs = []


  new_tab =
    name: new_tab_name
    lists: []

  if tabs.length == 0
    new_tab.lists = get_all_lists()


  tabs.push new_tab 
  save subdomain, ->
    setTimeout ->
      loc = bus_fetch 'location'
      loc.query_params.tab = new_tab_name
      save loc 


window.delete_tab = (tab_name, skip_confirmation) ->
  subdomain = bus_fetch('/subdomain')

  if skip_confirmation || \
     (get_tab(tab_name).type in [null, undefined, PAGE_TYPES.DEFAULT] && get_lists_for_page(tab_name)?.length == 0) || \
     confirm translator "homepage_tab.confirm-tab-deletion", "Are you sure you want to delete this tab? None of the lists in it will be deleted."
    
    idx = -1
    for tab,idx in (get_tabs() or [])
      if tab.name == tab_name 
        break

    if get_current_tab_name() == tab_name
      tab_state = bus_fetch 'homepage_tabs'
      tab_state.active_tab = null 
      save tab_state

    if subdomain.customizations.homepage_default_tab == tab_name
      delete subdomain.customizations.homepage_default_tab

    subdomain.customizations.homepage_tabs.splice idx, 1

    if subdomain.customizations.homepage_tabs.length == 0
      delete subdomain.customizations.homepage_tabs

    save subdomain

window.get_page_for_list = (list_key) -> 
  for page in get_tabs() or []    
    for list in get_lists_for_page(page.name)
      if list == list_key
        return page.name

  return null


styles += """
  #tabs {
    width: 100%;
    z-index: 2;
    margin-bottom: -2px;
    margin-top: 20px;
    position: relative;
  }
  #tabs > ul {
    margin: auto;
    text-align: center;
    list-style: none;
    max-width: 900px;
  }

  #tabs.editing > ul {
    padding-top: 26px;
  }


"""

window.HomepageTabs = ReactiveComponent
  displayName: 'HomepageTabs'

  render: -> 
    homepage_tabs = bus_fetch 'homepage_tabs'

    edit_forum = bus_fetch 'edit_forum'
    subdomain = bus_fetch '/subdomain'

    tabs = get_tabs()?.slice()

    return DIV null if !edit_forum.editing && !tabs

    #return DIV style:{paddingBottom:36} if edit_forum.editing && !bus_fetch('/current_user').is_super_admin && permit('configure paid feature') < 0

    is_light = is_light_background()


    demo = false 
    if edit_forum.editing 

      if !tabs || tabs.length == 0
        demo = true
        tabs ?= []
        tabs.push {name: "Tabs", demo: true}
        tabs.push {name: "Help Organize", demo: true}
        tabs.push {name: "Your Forum", demo: true, default: true}
      else 
        tabs.push {name: "add new Page", add_new: true}

    paid = permit('configure paid feature') > 0

    DIV 
      id: 'tabs'
      className: "#{if demo then 'demo' else ''} #{if edit_forum.editing then 'editing' else ''}" 
      style: @props.wrapper_style


      if edit_forum.editing 
        DIV 
          style:
            display: 'flex'
            justifyContent: 'center'

          
          LABEL 
            className: 'toggle_switch'
            style: 
              pointerEvents: if !paid then 'none'
              opacity: if !paid then .4

            INPUT 
              id: 'enable_tabs'
              type: 'checkbox'
              name: 'enable_tabs'
              checked: !!get_tabs()
              onChange: (ev) -> 
                if ev.target.checked
                  loc = bus_fetch 'location'
                  new_tab_name = prompt("What is the name of the first tab? You'll be able to add more later.")
                  if new_tab_name
                    create_new_tab new_tab_name
                    loc.query_params.tab = new_tab_name
                    if subdomain.customizations.lists?
                      delete subdomain.customizations.lists
                      save subdomain
                else
                  if confirm(translator "homepage_tab.disable_confirmation", "Are you sure you want to disable tabs? Existing tabs will be deleted. All existing lists will still be visible.")
                    for tab in get_tabs()?.slice() or []
                      delete_tab(tab.name, true)

                
            
            SPAN 
              className: 'toggle_switch_circle'


          LABEL 
            className: 'toggle_switch_label'
            style:
              backgroundColor: if is_light then "var(--bg_light_trans_25)" else "var(--bg_dark_trans_25)"
            htmlFor: if paid then 'enable_tabs'
            B null,
              'Enable Tabs.'
            
            DIV null,

              "Tabs help organize your forum into different pages."

          if !paid
            UpgradeForumButton
              text: 'upgrade'


      A 
        name: 'active_tab'

      UL 
        ref: 'tablist'
        role: 'tablist'
        style: _.defaults {}, @props.list_style,
          width: @props.width


        for tab, idx in tabs

          Tab
            key: tab.name
            tab: tab
            idx: idx
            current: homepage_tabs.active_tab == tab.name || (demo && tab.default)
            tab_style: @props.tab_style 
            tab_wrapper_style: @props.tab_wrapper_style
            active_style: @props.active_style
            active_tab_wrapper_style: @props.active_tab_wrapper_style
            featured: @props.featured == tab.name            
            featured_insertion: @props.featured_insertion
            go_to_hash: @props.go_to_hash


  isDraggable: ->
    edit_forum = bus_fetch 'edit_forum'
    edit_forum.editing

  componentDidMount : ->    
    @initializeDragging()

  componentDidUpdate : -> 
    @initializeDragging()

  initializeDragging: ->
    if !@isDraggable() && @drag_initialized
      @drag_initialized = false
      @draggable.destroy()

    else if @isDraggable() && !@drag_initialized
      @drag_initialized = true

      tab_root = @refs.tablist

      @draggable = new Draggable.Sortable tab_root,
        draggable: '.tab.tab-added.not-demo'
        distance: 1 # don't start drag unless moved a bit, otherwise click event gets swallowed up

      @draggable.on 'sortable:stop', ({data}) => 
        from = data.oldIndex
        to = data.newIndex

        subdomain = bus_fetch '/subdomain'

        tabs = subdomain.customizations.homepage_tabs
        tabs.splice(to, 0, tabs.splice(from, 1)[0])

        save subdomain


styles += """
  #tabs > ul > li {
    display: inline-block;
    position: relative;
    outline: none;
  }  

  .dragging-list #tabs > ul > li[data-accepts-lists="true"] {
    outline: 4px solid var(--brd_dark);
  }

  .dragging-list .dark #tabs > ul > li[data-accepts-lists="true"] {
    outline: 4px solid var(--brd_light);
  }

  .dragging-list #tabs > ul > li.draggedOver-by_list[data-accepts-lists="true"],
  .dragging-list .dark #tabs > ul > li.draggedOver-by_list[data-accepts-lists="true"] {
    outline: 4px solid #{attention_orange};
  }

  #tabs > ul > li[draggable="false"].demo:not(.add_new):not(.selected) {
    opacity: .5;
    pointer-events: none;
  }


  #tabs > ul > li > h4 {
    cursor: pointer;
    position: relative;
    padding: 10px 20px 4px 20px;
    font-size: 16px;
    font-weight: 600;        
    color: var(--text_light);
  }
  #tabs > ul > li.selected > h4 {
    opacity: 1;
    color: var(--text_dark);
  }
  #tabs > ul > li:hover > h4,
  #tabs > ul > li:focus-within > h4 {
    opacity: 1;
  }

  #tabs > ul > li > h4 > input {
    background-color: transparent;
    border: 1px solid var(--brd_light_gray);
    letter-spacing: inherit;
    font-size: inherit;
    font-weight: inherit;
    color: inherit;
    font-style: inherit;
    min-width: 50px;
    padding: 2px 4px;
  }

  #tabs > ul > li[draggable="false"].demo.add_new {
    background-color: transparent;
  }
  #tabs > ul > li[draggable="false"].demo.add_new > h4 {
    color: var(--text_dark);
  }  
  .dark #tabs > ul > li[draggable="false"].demo.add_new > h4 {
    color: var(--text_light);
  }

  .tab.draggable-source--is-dragging {
    opacity: .7;
  }

"""


window.Tab = ReactiveComponent
  displayName: 'Tab'
  mixins: [SubdomainSaveRateLimiter]



  render: -> 
    subdomain = bus_fetch('/subdomain')
    edit_forum = bus_fetch 'edit_forum'

    tab = @props.tab
    tab_name = tab.name

    current = @props.current
    featured = @props.featured

    tab_style = _.extend {display: 'inline-block'}, @props.tab_style
    tab_wrapper_style = _.extend {}, @props.tab_wrapper_style


    if current
      _.extend tab_style, @props.active_style
      _.extend tab_wrapper_style, @props.active_tab_wrapper_style

    
    accepts_lists = @props.tab.type not in [PAGE_TYPES.ABOUT, PAGE_TYPES.ALL] && !tab.demo && !tab.add_new

    LI 
      className: "tab #{if current then 'selected' else ''} #{if tab.demo then 'demo' else 'not-demo'} #{if tab.add_new then 'add_new' else 'tab-added'}"
      ref: 'tab'
      tabIndex: 0
      role: 'tab'
      style: tab_wrapper_style
      'data-tab': tab.name
      'aria-controls': 'homepagetab'
      'aria-selected': current
      'data-accepts-lists': accepts_lists
      'data-page-name': tab_name

      onClick: =>
        return if tab.demo && !tab.add_new

        loc = bus_fetch 'location'

        if tab.add_new
          tab_name = new_tab_name = prompt("What is the name of the tab?")
          if tab_name
            create_new_tab new_tab_name
        else 
          tab_name = tab.name
          if @props.go_to_hash
            el = document.querySelector("[name='#{@props.go_to_hash}']")
            if el
              $$.ensureInView el, 
                position: 'top'
                scroll: true


        loc.query_params.tab = tab_name
        save loc  
        if loc.url != '/'
          loadPage '/', loc.query_params

        document.activeElement.blur()


      if edit_forum.editing  && !tab.add_new && !tab.demo && get_tabs().length > 1
        BUTTON 
          style: 
            cursor: 'move'
            backgroundColor: 'transparent'
            border: 'none'                    
          drag_icon 15, "var(--text_neutral)"

      H4 
        className: if current then 'main_background'
        style: tab_style

        if tab.add_new
          SPAN null,
            if !tab.demo
              "+ "
            SPAN 
              style: 
                textDecoration: 'underline'

              translator
                id: "homepage_tab.#{if get_tabs()?.length > 0 then "add_more" else "enable"}.#{tab_name}"
                tab_name

        else if edit_forum.editing && tab_name == get_current_tab_name()
          INPUT
            className: "tab_name_input"
            type: 'text'
            defaultValue: tab_name
            style: 
              fontSize: 'inherit'
              color: 'inherit'
              fontWeight: 'inherit'
              fontDecoration: 'inherit'
              fontStyle: 'inherit'
            

            onKeyDown: (e) => 
              e.stopPropagation()

            onClick: (e) =>
              e.stopPropagation()
              # e.preventDefault()

            # onChange: (e) =>
            onBlur: (e) =>
              if e.target.value != ""
                if subdomain.customizations.homepage_default_tab == tab.name
                  subdomain.customizations.homepage_default_tab = e.target.value

                tab.name = e.target.value
                el = e.target
                @save_customization_with_rate_limit 
                  force_save: true
                  wait_for: 10
                  on_save_callback: => 
                    loc = bus_fetch 'location'
                    loc.query_params.tab = tab.name 
                    save loc


        else 
          if !subdomain.name
            '...'
          else 
            translator
              id: "homepage_tab.name.#{tab_name}"
              local: tab_name != 'Show all'
              tab_name
      
      if edit_forum.editing && tab_name == get_current_tab_name() && !tab.demo
        BUTTON 
          style:
            display: 'inline-block'
            backgroundColor: 'transparent'
            border: 'none'
            cursor: 'pointer'
          onClick: ->
            delete_tab tab.name
          trash_icon 15, 15, "var(--text_neutral)"

      if featured 
        @props.featured_insertion?()


