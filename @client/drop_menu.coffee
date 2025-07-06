

# DropMenu

# structure: 

#   DropMenu

#     Wrapper

#       Anchor (triggers menu open)

#       Menu (a list)

#         Option

#         (...)


# props: 

#   open_menu_on (focus | activation)  (common case is hover vs click) 

#   wrapper_style
#   anchor_style
#   anchor_when_open_style
#   menu_style
#   option_style
#   active_option_style

#   selection_made_callback (option) -> 

#   options [{}, {}]   # each option needs a label. Structure will be LI -> A. If href is present, will be added to A
#   render_option (option, is_active) -> 
#   render_anchor -> 

# state: 
#   - open
#   - active_option ("focus" in other code)


styles += """

[data-widget="DropMenu"] .dropmenu-wrapper {
  position: relative;
}

[data-widget="DropMenu"] .dropMenu-anchor {
  position: relative;
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: inherit;
}

[data-widget="DropMenu"] .dropmenu-menu {
  list-style: none;
  position: absolute;
  z-index: 999999;
}

[data-widget="DropMenu"] .menu-item {
  cursor: pointer;
  outline: none;
  text-decoration: none;
}


"""


window.DropMenu = ReactiveComponent
  displayName: 'DropMenu'

  render : ->
    @local.active_option ?= -1
    open_menu_on = @props.open_menu_on or 'focus' #other option is 'activation'

    wrapper_style = @props.wrapper_style or {}

    anchor_style = @props.anchor_style or {}

    anchor_when_open_style = _.defaults {}, (@props.anchor_open_style or {}), anchor_style
    
    menu_style = @props.menu_style or {}

    menu_when_open_style = _.defaults {}, (@props.menu_when_open_style or {}), menu_style

    option_style = @props.option_style or {}
    active_option_style = _.defaults {}, (@props.active_option_style or {}), option_style

    options = @props.options

    render_anchor = @props.render_anchor
    render_option = @props.render_option

    set_active = (idx) => 
      idx = -1 if !idx?
      if @local.active_option != idx 
        @local.active_option = idx 
        save @local 
        if idx != -1
          setTimeout =>
            if idx == @local.active_option && @refs["menuitem-#{idx}"]?
              ReactDOM.findDOMNode(@refs["menuitem-#{idx}"]).focus()           
          , 0


    trigger = (e) => 
      selection = options[@local.active_option]

      @props.selection_made_callback? selection

      if selection.href 
        e.currentTarget.click()

      close_menu(e)
      e.stopPropagation()
      e.preventDefault()


    close_menu = (e) => 
      document.activeElement.blur()
      @local.show_menu = false
      save @local
      @props.close_callback?()
      e?.stopPropagation()

    # wrapper
    id = "drop-menu-#{@local.key.replace(/\//g, '__')}"
    DIV 
      id: id
      className: "dropmenu-wrapper #{if @props.className then @props.className}"
      ref: 'menu_wrap'
      key: 'dropmenu-wrapper'
      style: wrapper_style

      onMouseLeave: (e) =>
        close_menu(e)

      onBlur: (e) => 
        setTimeout => 
          # if the focus isn't still on an element inside of this menu, 
          # then we should close the menu

          el = document.getElementById(id)
          if el && !$$.closest(document.activeElement, "##{id}")
            close_menu(e)

        , 0

      onKeyDown: (e) =>
        @props.onKeyDown?(e)
        if e.which == 13 || e.which == 32 || e.which == 27 # ENTER or ESC
          close_menu(e)
          e.preventDefault()            
        else if e.which == 38 || e.which == 40 # UP / DOWN ARROW
          active_option = @local.active_option
          active_option = -1 if !active_option?
          if e.which == 38
            active_option--
            if active_option < 0 
              active_option = options.length - 1
          else 
            active_option++
            if active_option > options.length - 1
              active_option = 0 
          set_active active_option
          e.preventDefault() # prevent window from scrolling too


      # anchor

      BUTTON 
        key: 'drop-anchor'
        tabIndex: 0
        'aria-haspopup': "true"
        'aria-owns': "dropMenu-#{@local.key}"
        style: if @local.show_menu then anchor_when_open_style else anchor_style
        className: "dropMenu-anchor #{if @props.anchor_class_name then @props.anchor_class_name else ''}"

        onMouseEnter: if open_menu_on == 'focus' && !browser.touch then (e) => 
          @local.show_menu = true
          set_active(-1)
          save @local 

        onClick: if open_menu_on != 'focus' || browser.touch then (e) => 
          if bus_fetch('tooltip').tip
            clear_tooltip()     
          @local.show_menu = !@local.show_menu
          set_active(-1) if @local.show_menu
          save @local
          e.stopPropagation()
          e.preventDefault()

        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32  
            @local.show_menu = !@local.show_menu
            if @local.show_menu
              set_active(0) 
            save @local
            e.preventDefault()
            e.stopPropagation() 

        "data-tooltip": @props.anchor_tooltip

        render_anchor @local.show_menu 

      # drop menu

      UL
        key: 'dropMenu-menu'
        className: "dropmenu-menu #{if @local.show_menu then 'dropmenu-menu-open'}"
        id: "dropMenu-#{@local.key}" 
        role: "menu"
        'aria-hidden': !@local.show_menu
        hidden: !@local.show_menu
        style: if @local.show_menu then menu_when_open_style else menu_style

        for option, idx in options
          do (option, idx) =>
            LI 
              key: "#{option.label}-#{idx}"
              role: "presentation"

              A
                ref: "menuitem-#{idx}"
                role: "menuitem"
                tabIndex: if @local.active_option == idx then 0 else -1
                href: option.href #optional
                key: "#{option.label}-activate" 
                'data-action': option['data-action'] #optional
                className: "menu-item #{if @local.active_option == idx then 'active-menu-item'}"

                style: if @local.active_option == idx then active_option_style else option_style

                onClick: (e) => 
                  if @local.active_option != idx 
                    set_active idx 
                  trigger(e)

                onTouchEnd: (e) =>
                  if @local.active_option != idx 
                    set_active idx 
                  trigger(e)

                onKeyDown: (e) => 
                  if e.which == 13 || e.which == 32 # ENTER or SPACE
                    trigger(e)

                onFocus: (e) => 
                  if @local.active_option != idx 
                    set_active idx
                  e.stopPropagation()

                onMouseEnter: => 
                  if @local.active_option != idx   
                    set_active idx

                onBlur: (e) => 
                  if @local.active_option == idx 
                    @local.active_option = -1 
                    save @local  

                onMouseLeave: (e) => 
                  @local.active_option = -1 
                  save @local
                  e.stopPropagation()

                render_option option, @local.active_option == idx


styles += """
  .default_drop[data-widget="DropMenu"] {
    display: inline-block;
    min-width: 170px;
  }
  .default_drop[data-widget="DropMenu"] .dropMenu-anchor {
    display: flex;
  }

  .default_drop[data-widget="DropMenu"] .dropmenu-menu {
    left: -9999px;
    top: 26px;
    border-radius: 8px;
    overflow: hidden;
    font-style: normal;
    width: 280px;
    box-shadow: 0 2px 5px #{shadow_dark_50};
    background-color: #{bg_lightest_gray};
    padding: 8px 0;
  }

  .default_drop[data-widget="DropMenu"] .dropmenu-menu.dropmenu-menu-open {
    left: 0;
  }

  .default_drop[data-widget="DropMenu"] .menu-item {
    padding: 8px 20px;
    display: block;
    font-weight: 600;
    font-size: 18px;
    text-transform: capitalize;
    color: var(--focus_color);
  }

  .default_drop[data-widget="DropMenu"] .menu-item.active-menu-item {
    color: #{text_dark};
  }
"""


                  
