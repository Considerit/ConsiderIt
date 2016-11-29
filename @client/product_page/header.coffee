

menu_options = nav_links = [
  {
    href: '/tour'
    label: 'Features'
  }
  { 
    href: '/pricing'
    label: 'Pricing'
  }
  {
    href: '/contact'
    label: 'Contact'
  }
  {
    href: '/create_forum'
    label: 'Create a Forum'
  }
]


window.Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")
    loc = fetch('location')

    w = SAAS_PAGE_WIDTH()
    h = 80

    compact = browser.is_mobile || w < 860


    @local.dot_x ?= 0
    dot_size = 10

    homepage = loc.url == '/'

    main_color = if homepage then seattle_salmon else 'white'

    HEADER
      style:
        position: "relative"
        margin: "0 auto 5px auto"

      DIV
        style:
          width: w
          margin: 'auto'
          borderBottom: "1px solid #{main_color}"
          transition: 'border 500ms'


        # logo
        A 
          ref: 'logo'
          href: '/'
          style:
            display: 'inline-block'
            position: "relative"
            top: 12

          drawLogo h - 10, main_color, 'transparent'


        SVG 
          width: dot_size 
          height: dot_size 
          viewBox: "0 0 #{dot_size} #{dot_size}" 
          version: "1.1" 
          xmlns: "http://www.w3.org/2000/svg" 
          style: _.extend css.crossbrowserify({transition: 'left 500ms'}), 
            position: 'absolute'
            left: @local.dot_x - dot_size / 2
            zIndex: 2
            bottom: -dot_size / 2


          G null,

            CIRCLE 
              style: 
                transition: 'fill 500ms'
              fill: main_color
              cx: dot_size / 2
              cy: dot_size / 2
              r: dot_size / 2
                 


        # nav menu
        DIV 
          style: 
            position: 'relative'
            bottom: -39
            display: 'inline-block'
            float: 'right'
            #marginRight: -6
            #right: -8
            #float: 'right'


          if compact
            HamburgerMenu {nav_links}

          else 
            for nav,idx in nav_links
              A 
                ref: nav.href
                key: idx
                style: _.extend {}, base_text,
                  fontWeight: 600
                  fontSize: 18
                  color: main_color
                  marginLeft: 25
                  cursor: 'pointer'
                  border: '1px solid transparent'
                  borderColor: if idx == nav_links.length - 1 then main_color
                  borderRadius: '8px 8px 0px 0'
                  borderBottom: 'none'
                  padding: if idx == nav_links.length - 1 then '14px 20px' else '14px 10px'
                  transition: 'border 500ms, color 500ms'

                href: nav.href
                nav.label

  positionDot: -> 
    url = fetch('location').url
        
    link = @refs[url]?.getDOMNode()

    if link
      rect = link.getBoundingClientRect()
      dot_x = rect.left + (rect.right - rect.left) / 2
    else  
      link = @refs.logo?.getDOMNode()
      rect = link.getBoundingClientRect()
      dot_x = rect.right - 38

    if dot_x != @local.dot_x

      @local.dot_x = dot_x
      save @local 

  componentDidMount: -> @positionDot()
  componentDidUpdate: -> @positionDot()

HamburgerMenu = ReactiveComponent
  displayName: 'HamburgerMenu'

  render : -> 

    set_focus = (idx) => 
      idx = 0 if !idx?
      @local.focus = idx 
      save @local 
      setTimeout => 
        @refs["menuitem-#{idx}"].getDOMNode().focus()
      , 0

    close_menu = => 
      document.activeElement.blur()
      @local.menu = false
      save @local


    homepage = fetch('location').url == '/'
    main_color = if homepage then seattle_salmon else 'white'
    link_color = if homepage then seattle_salmon else primary_color()

    DIV
      key: 'hamburger'
      ref: 'menu_wrap'
      style:
        position: 'relative'

      onTouchEnd: => 
        @local.menu = !@local.menu
        save(@local)

      onMouseEnter: (e) => @local.menu = true; save(@local)
      onMouseLeave: close_menu

      onBlur: (e) => 
        setTimeout => 
          # if the focus isn't still on an element inside of this menu, 
          # then we should close the menu
          if $(document.activeElement).closest(@refs.menu_wrap.getDOMNode()).length == 0
            @local.menu = false; save @local
        , 0

      onKeyDown: (e) => 
        if e.which == 13 || e.which == 32 || e.which == 27 # ENTER or ESC
          close_menu()
          e.preventDefault()
        else if e.which == 38 || e.which == 40 # UP / DOWN ARROW
          @local.focus = -1 if !@local.focus?
          if e.which == 38
            @local.focus--
            if @local.focus < 0 
              @local.focus = menu_options.length 
          else
            @local.focus++
            if @local.focus > menu_options.length 
              @local.focus = 0 
          set_focus(@local.focus)
          e.preventDefault() # prevent window from scrolling too

      BUTTON 
        tabIndex: 0
        'aria-haspopup': "true"
        'aria-owns': "hamburger_popup"

        style: 
          border: "1px solid #{main_color}"
          borderBottom: 'none'
          borderRadius: '8px 8px 0px 0'
          padding: '0px 6px'
          position: 'relative'
          top: -13
          backgroundColor: 'transparent'

        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32
            @local.menu = true
            save(@local)
            if !@local.focus? 
              set_focus(0)
            e.preventDefault()
            e.stopPropagation()

        SVG 
          height: 44 
          viewBox: "0 0 32 24" 
          width: 44

          PATH 
            fill: main_color
            d: "M4,10h24c1.104,0,2-0.896,2-2s-0.896-2-2-2H4C2.896,6,2,6.896,2,8S2.896,10,4,10z M28,14H4c-1.104,0-2,0.896-2,2  s0.896,2,2,2h24c1.104,0,2-0.896,2-2S29.104,14,28,14z M28,22H4c-1.104,0-2,0.896-2,2s0.896,2,2,2h24c1.104,0,2-0.896,2-2  S29.104,22,28,22z"


      UL 
        id: 'hamburger_popup'
        role: "menu"
        'aria-hidden': !@local.menu
        hidden: !@local.menu
        style: 
          listStyle: 'none'
          position: 'absolute'
          left: 'auto'
          right: if !@local.menu then -9999 else 8
          margin: '-10px 0 0 -8px'
          padding: "16px 14px 8px 8px"
          backgroundColor: 'white'
          textAlign: 'right'
          zIndex: 999999
          boxShadow: '0 1px 2px rgba(0,0,0,.2)'


        for option, idx in menu_options
          LI 
            key: option.label
            role: "presentation"
            A
              ref: "menuitem-#{idx}"
              role: "menuitem"
              tabIndex: if @local.focus == idx then 0 else -1
              href: option.href
              key: option.href
              style: 
                color: if @local.focus == idx then link_color else '#303030'
                outline: 'none'
                position: 'relative'
                bottom: 8
                padding: '10px 0 10px 27px'
                display: 'block'
                whiteSpace: 'nowrap'
                fontSize: 30
                borderBottom: if idx != menu_options.length - 1 then '1px solid #eaeaea'

              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  e.currentTarget.click()
                  e.preventDefault()
              onFocus: do(idx) => (e) => 
                if @local.focus != idx 
                  set_focus idx
                e.stopPropagation()
              onMouseEnter: do(idx) => => 
                if @local.focus != idx                         
                  set_focus idx

              onBlur: (e) => 
                @local.focus = null 
                save @local  

              onMouseExit: (e) => 
                @local.focus = null 
                save @local
                e.stopPropagation()


              option.label
