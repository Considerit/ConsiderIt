# handles tab query parameter based on tabs state
window.HomepageTabTransition = ReactiveComponent
  displayName: "HomepageTabTransition"

  render: -> 
    if get_tabs()
      loc = fetch 'location'
      tab_state = fetch 'homepage_tabs'
      default_tab = customization('homepage_default_tab') or 'Show all'

      if !tab_state.active_tab? || (loc.query_params.tab && loc.query_params.tab != tab_state.active_tab)

        if loc.query_params.tab
          tab_state.active_tab = decodeURIComponent loc.query_params.tab
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

window.get_current_tab_name = -> fetch('homepage_tabs').active_tab
window.get_current_tab_view = ->
  custom_view = get_tab()?.render_page or customization('render_page')

  if custom_view
    view = custom_view()
    if typeof(view) == 'function'
      view = view()
    view
  else
    SimpleHomepage()




window.HomepageTabs = ReactiveComponent
  displayName: 'HomepageTabs'

  render: -> 
    homepage_tabs = fetch 'homepage_tabs'
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


        for tab, idx in get_tabs() 
          do (tab) =>
            tab_name = tab.name
            current = homepage_tabs.active_tab == tab_name 
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
                if homepage_tabs.active_tab != tab_name 
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
                  key: if tab_name != 'Show all' then "/translations/#{subdomain.name}"
                  tab_name
                  
              if featured 
                @props.featured_insertion?()
