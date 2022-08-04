
window.SubdomainSaveRateLimiter =  

  save_customization_with_rate_limit: ({fields, config, force_save, on_save_callback, wait_for}) ->
    subdomain = fetch '/subdomain'

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
      loc = fetch 'location'
      tab_state = fetch 'homepage_tabs'
      default_tab = customization('homepage_default_tab') or get_tabs()[0]?.name or 'Show all'

      if !tab_state.active_tab? || (loc.query_params.tab && loc.query_params.tab != tab_state.active_tab)

        if loc.query_params.tab && get_tab(decodeURIComponent(loc.query_params.tab))
          tab_state.active_tab = decodeURIComponent(loc.query_params.tab)
        else 
          tab_state.active_tab = default_tab



        save tab_state

      if loc.url != '/' && loc.query_params.tab
        delete loc.query_params.tab
        save loc
      else if loc.url == '/' && loc.query_params.tab != tab_state.active_tab
        loc.query_params.tab = tab_state.active_tab
        save loc

    SPAN null







window.get_tabs = -> 
  if customization('homepage_tabs')?.length > 0
    fetch('/subdomain').customizations.homepage_tabs
  else 
    null

window.get_tab = (name) -> 
  name ?= get_current_tab_name()
  for tab in (get_tabs() or [])
    if tab.name == name 
      return tab
  return null

window.get_current_tab_name = -> fetch('homepage_tabs').active_tab or null
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
  subdomain = fetch('/subdomain')

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
      loc = fetch 'location'
      loc.query_params.tab = new_tab_name
      save loc 


window.delete_tab = (tab_name, skip_confirmation) ->
  subdomain = fetch('/subdomain')

  if skip_confirmation || \
     (get_tab(tab_name).type in [null, undefined, PAGE_TYPES.DEFAULT] && get_lists_for_page(tab_name)?.length == 0) || \
     confirm translator "homepage_tab.confirm-tab-deletion", "Are you sure you want to delete this tab? None of the lists in it will be deleted."
    
    idx = -1
    for tab,idx in (get_tabs() or [])
      if tab.name == tab_name 
        break

    if get_current_tab_name() == tab_name
      tab_state = fetch 'homepage_tabs'
      tab_state.active_tab = null 
      save tab_state

    if subdomain.customizations.homepage_default_tab == tab_name
      delete subdomain.customizations.homepage_default_tab

    subdomain.customizations.homepage_tabs.splice idx, 1

    if subdomain.customizations.homepage_tabs.length == 0
      delete subdomain.customizations.homepage_tabs

    save subdomain




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
    width: 900px;
  }

  #tabs.editing > ul {
    padding-top: 26px;
  }

"""

window.HomepageTabs = ReactiveComponent
  displayName: 'HomepageTabs'

  render: -> 
    homepage_tabs = fetch 'homepage_tabs'

    edit_forum = fetch 'edit_forum'
    subdomain = fetch '/subdomain'

    tabs = get_tabs()?.slice()

    return DIV null if !edit_forum.editing && !tabs

    #return DIV style:{paddingBottom:36} if edit_forum.editing && !fetch('/current_user').is_super_admin && permit('configure paid feature') < 0

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
        tabs.push {name: "add new tab", add_new: true}

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
                  loc = fetch 'location'
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
              backgroundColor: if is_light then 'rgba(255,255,255,.4)' else 'rgba(0,0,0,.4)'
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
            hovering_tab_wrapper_style: @props.hovering_tab_wrapper_style
            featured: @props.featured == tab.name            
            featured_insertion: @props.featured_insertion
            go_to_hash: @props.go_to_hash



styles += """
  #tabs > ul > li {
    display: inline-block;
    position: relative;
    outline: none;
  }  

  .dragging-list #tabs > ul > li[data-accepts-lists="true"] {
    outline: 4px solid black;
  }

  .dragging-list .dark #tabs > ul > li[data-accepts-lists="true"] {
    outline: 4px solid white;
  }

  .dragging-list #tabs > ul > li.draggedOver-by_list[data-accepts-lists="true"] {
    outline: 4px solid red;
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
    color: white;
  }
  #tabs > ul > li.selected > h4 {
    opacity: 1;
    color: black;
  }
  #tabs > ul > li.hovering > h4 {
    opacity: 1;
  }

  #tabs > ul > li > h4 > input {
    background-color: transparent;
    border: 1px solid #ccc;
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
    color: black;
  }  
  .dark #tabs > ul > li[draggable="false"].demo.add_new > h4 {
    color: white;
  }

"""


window.Tab = ReactiveComponent
  displayName: 'Tab'
  mixins: [SubdomainSaveRateLimiter]


  render: -> 
    subdomain = fetch('/subdomain')
    edit_forum = fetch 'edit_forum'

    tab = @props.tab
    tab_name = tab.name

    current = @props.current
    hovering = @local.hovering == tab_name
    featured = @props.featured

    tab_style = _.extend {display: 'inline-block'}, @props.tab_style
    tab_wrapper_style = _.extend {}, @props.tab_wrapper_style


    if current
      _.extend tab_style, @props.active_style
      _.extend tab_wrapper_style, @props.active_tab_wrapper_style
    
    if hovering
      _.extend tab_style, @props.hover_style or @props.active_style
      _.extend tab_wrapper_style, @props.hovering_tab_wrapper_style

    accepts_lists = @props.tab.type not in [PAGE_TYPES.ABOUT, PAGE_TYPES.ALL] && !tab.demo && !tab.add_new

    LI 
      className: "#{if current then 'selected' else if hovering then 'hovered' else ''} #{if tab.demo then 'demo' else ''} #{if tab.add_new then 'add_new' else ''}"
      tabIndex: 0
      role: 'tab'
      style: tab_wrapper_style
      'data-tab': tab.name
      'aria-controls': 'homepagetab'
      'aria-selected': current
      draggable: edit_forum.editing && !tab.add_new && !tab.demo 
      'data-accepts-lists': accepts_lists

      onMouseEnter: => 
        return if tab.add_new || tab.demo
        homepage_tabs = fetch 'homepage_tabs'
        if homepage_tabs.active_tab != tab_name 
          @local.hovering = tab_name 
          save @local 
      onMouseLeave: => 
        @local.hovering = null 
        save @local
      onClick: =>
        return if tab.demo && !tab.add_new

        loc = fetch 'location'

        if tab.add_new
          tab_name = new_tab_name = prompt("What is the name of the tab?")
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
        document.activeElement.blur()


      if edit_forum.editing  && !tab.add_new && !tab.demo && get_tabs().length > 1
        BUTTON 
          style: 
            cursor: 'move'
            backgroundColor: 'transparent'
            border: 'none'                    
          drag_icon 15, '#888'

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
            
            # prevent dragging when editing the tab name
            draggable: true
            onDragStart: (e) =>
              e.preventDefault()
              e.stopPropagation()

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
                    loc = fetch 'location'
                    loc.query_params.tab = tab.name 
                    save loc


        else 
          translator
            id: "homepage_tab.#{tab_name}"
            key: if tab_name != 'Show all' then "/translations/#{subdomain.name}"
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
          trash_icon 15, 15, '#888'

      if featured 
        @props.featured_insertion?()


  makeTabDraggable: ->

    return if @tab_draggable || !fetch('edit_forum').editing || @props.tab.add_new
    @tab_draggable = true 

    tab = ReactDOM.findDOMNode(@)

    drag_data = fetch 'list/tab_drag'


    reassign_list_to_page = (source, target, dragging) =>
      subdomain = fetch '/subdomain'

      dragging = parseInt(dragging)
      source_lists = get_tab(source).lists
      target_lists = get_tab(target).lists

      list_key = source_lists[dragging]

      if source_lists && target_lists
        source_lists.splice dragging, 1
        if target_lists.indexOf(list_key) == -1
          target_lists.push list_key 
        save subdomain
      else 
        console.error "Could not move list #{list_key} from #{source} to #{target}"

    reorder_tab = (from, to) =>
      subdomain = fetch '/subdomain'

      tabs = subdomain.customizations.homepage_tabs
      tabs.splice(to, 0, tabs.splice(from, 1)[0])

      save subdomain



    accepts_lists = @props.tab.type not in [PAGE_TYPES.ABOUT, PAGE_TYPES.ALL] && !tab.demo && !tab.add_new

    @onDragStartTab ?= (e) =>

      _.extend drag_data,
        type: 'tab'
        id: @props.idx
      save drag_data

      document.body.classList.add('dragging-tab')
      el = e.currentTarget
      setTimeout ->
        if !el.classList.contains('dragging')
          el.classList.add('dragging')

    @onDragEndTab ?= (e) =>

      delete drag_data.type
      delete drag_data.id
      save drag_data

      document.body.classList.remove('dragging-tab')
      if e.currentTarget.classList.contains('dragging')
        e.currentTarget.classList.remove('dragging')


    @onDragOverTab ?= (e) =>
      if drag_data.type == 'list' && accepts_lists
        e.preventDefault()
        if !e.currentTarget.classList.contains('draggedOver-by_list') 
          e.currentTarget.classList.add('draggedOver-by_list')
      else if drag_data.type == 'tab'
        e.preventDefault()
        if !e.currentTarget.classList.contains('draggedOver-by_tab')
          e.currentTarget.classList.add('draggedOver-by_tab')

    @onDragLeaveTab ?= (e) =>
      if drag_data.type == 'list' && accepts_lists
        e.preventDefault()
        if e.currentTarget.classList.contains('draggedOver-by_list')
          e.currentTarget.classList.remove('draggedOver-by_list')
      else if drag_data.type == 'tab'
        e.preventDefault()
        if !e.currentTarget.classList.contains('draggedOver-by_tab')
          e.currentTarget.classList.remove('draggedOver-by_tab')


    @onDropTab ?= (e) =>
      if drag_data.type == 'list' && accepts_lists
        reassign_list_to_page drag_data.source_page, @props.tab.name, drag_data.id

        delete drag_data.type
        delete drag_data.source_page
        delete drag_data.id
        save drag_data

        if e.currentTarget.classList.contains('draggedOver-by_list')
          e.currentTarget.classList.remove('draggedOver-by_list')
        document.body.classList.remove('dragging-list')
      else if drag_data.type == 'tab'

        reorder_tab drag_data.id, @props.idx

        delete drag_data.type
        delete drag_data.id
        save drag_data

        if !e.currentTarget.classList.contains('draggedOver-by_tab')
          e.currentTarget.classList.remove('draggedOver-by_tab')
        document.body.classList.remove('dragging-tab')


    tab.addEventListener('dragstart', @onDragStartTab) 
    tab.addEventListener('dragend', @onDragEndTab) 
    tab.addEventListener('dragover', @onDragOverTab)
    tab.addEventListener('dragleave', @onDragLeaveTab)      
    tab.addEventListener('drop', @onDropTab) 

  removeTabDraggability: -> 
    return if !@tab_draggable || fetch('edit_forum').editing || @props.tab.add_new
    @tab_draggable = false
    tab = ReactDOM.findDOMNode(@)


    tab.removeEventListener('dragstart', @onDragStartTab) 
    tab.removeEventListener('dragend', @onDragEndTab) 


    tab.removeEventListener('dragover', @onDragOverTab)
    tab.removeEventListener('dragleave', @onDragLeaveTab)      
    tab.removeEventListener('drop', @onDropTab) 

  componentDidMount: -> 
    @makeTabDraggable()
  componentDidUpdate: -> 
    @makeTabDraggable()
  componentWillUnmount: -> 
    @removeTabDraggability()


