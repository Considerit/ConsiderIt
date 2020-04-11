

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


window.DropMenu = ReactiveComponent
  displayName: 'DropMenu'

  render : ->

    open_menu_on = @props.open_menu_on or 'focus' #other option is 'activation'

    wrapper_style = _.defaults {}, @props.wrapper_style, 
      position: 'relative'

    anchor_style = _.defaults {}, @props.anchor_style,
      position: 'relative'
      background: 'transparent'
      border: 'none'
      cursor: 'pointer'
      fontSize: 'inherit'

    anchor_when_open_style = _.defaults {}, @props.anchor_open_style, anchor_style
    
    menu_style = _.defaults {}, @props.menu_style,
      listStyle: 'none'
      position: 'absolute'
      zIndex: 999999

    menu_when_open_style = _.defaults {}, @props.menu_when_open_style, menu_style


    option_style = _.defaults {}, @props.option_style,
      cursor: 'pointer'
      outline: 'none'
    active_option_style = _.defaults {}, @props.active_option_style, option_style

    options = @props.options

    render_anchor = @props.render_anchor
    render_option = @props.render_option

    set_active = (idx) => 
      idx = 0 if !idx?
      @local.active_option = idx 
      save @local 
      setTimeout => 
        @refs["menuitem-#{idx}"].getDOMNode().focus()
      , 0


    trigger = (e) => 
      selection = options[@local.active_option]

      @props.selection_made_callback? selection

      if selection.href 
        e.currentTarget.click()

      close_menu()
      e.stopPropagation()
      e.preventDefault()


    close_menu = => 
      document.activeElement.blur()
      @local.show_menu = false
      save @local

    # wrapper
    DIV 
      ref: 'menu_wrap'
      key: 'dropmenu-wrapper'
      style: wrapper_style

      onTouchEnd: => 
        @local.show_menu = !@local.show_menu
        save @local

      onMouseLeave: close_menu

      onBlur: (e) => 
        setTimeout => 
          # if the focus isn't still on an element inside of this menu, 
          # then we should close the menu
          if @refs.menu_wrap && $(document.activeElement).closest(@refs.menu_wrap?.getDOMNode()).length == 0
            @local.sort_menu = false; save @local
        , 0

      onKeyDown: (e) => 
        if e.which == 13 || e.which == 32 || e.which == 27 # ENTER or ESC
          close_menu()
          e.preventDefault()            
        else if e.which == 38 || e.which == 40 # UP / DOWN ARROW
          @local.active_option = -1 if !@local.active_option?
          if e.which == 38
            @local.active_option--
            if @local.active_option < 0 
              @local.active_option = options.length - 1
          else 
            @local.active_option++
            if @local.active_option > options.length - 1
              @local.active_option = 0 
          set_active @local.active_option
          e.preventDefault() # prevent window from scrolling too


      # anchor

      BUTTON 
        tabIndex: 0
        'aria-haspopup': "true"
        'aria-owns': "dropMenu-#{@local.key}"
        style: if @local.show_menu then anchor_when_open_style else anchor_style


        onMouseEnter: if open_menu_on == 'focus' then (e) => 
                @local.show_menu = true
                set_active(0)
                save @local 

        onClick: if open_menu_on != 'focus' then (e) => 
                @local.show_menu = !@local.show_menu
                set_active(0) if @local.show_menu
                save @local

        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32  
            @local.show_menu = !@local.show_menu
            if @local.show_menu
              set_focus(0) 
            save @local
            e.preventDefault()
            e.stopPropagation() 

        render_anchor @local.show_menu 

      # drop menu

      UL
        id: "dropMenu-#{@local.key}" 
        role: "menu"
        'aria-hidden': !@local.show_menu
        hidden: !@local.show_menu
        style: if @local.show_menu then menu_when_open_style else menu_style



        for option, idx in options
          do (option, idx) =>
            LI 
              key: option.label
              role: "presentation"

              A
                ref: "menuitem-#{idx}"
                role: "menuitem"
                tabIndex: if @local.active_option == idx then 0 else -1
                href: option.href #optional
                key: "#{option.label}-activate" 
                'data-action': option['data-action'] #optional
                
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
                  @local.active_option = null 
                  save @local  

                onMouseExit: (e) => 
                  @local.active_option = null 
                  save @local
                  e.stopPropagation()

                render_option option, @local.active_option == idx

                  



