require './customizations'

window.ProfileMenu = ReactiveComponent
  displayName: 'ProfileMenu'

  render : -> 
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    is_super = current_user.is_super_admin
    menu_options = [
      {href: '/edit_profile', label: 'Edit Profile'},
      {href: '/dashboard/email_notifications', label: 'Email Settings'},
      if is_admin then {href: '/dashboard/import_data', label: 'Import / Export Data'} else null,
      if is_admin then {href: '/dashboard/application', label: 'App Settings'} else null,
      if is_super then {href: '/dashboard/customizations', label: 'Customizations'} else null,      
      if is_admin then {href: '/dashboard/roles', label: 'User Roles'} else null,
      if is_super then {href: '/dashboard/tags', label: 'User Tags'} else null,      
      if is_moderator then {href: '/dashboard/moderate', label: 'Moderate'} else null,
    ]

    menu_options = _.compact menu_options

    hsl = parseCssHsl(subdomain.branding.primary_color)
    light_background = hsl.l > .75

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

    DIV
      id: 'user_nav'
      style: _.defaults {}, (customization('profile_menu_style') or {}), (@props.style or {}),
        position: 'absolute'
        zIndex: 5
        right: 30
        fontSize: 26
        top: 17

      if current_user.logged_in

        DIV null,

          if subdomain.name in ['bitcoin', 'bitcoinclassic'] && \
             current_user.logged_in && \
             (!current_user.tags['verified']? || current_user.tags['verified'] in ['no', 'false'])
            
            @bitcoinVerification()

          DIV
            key: 'profile_menu'
            ref: 'menu_wrap'
            className: 'profile_menu_wrap'
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
              'aria-owns': "profile_menu_popup"

              style: 
                color: if !light_background then 'white'
                position: 'relative'
                zIndex: 9999999999
                backgroundColor: if !@local.menu then 'rgba(255,255,255, .1)' else 'transparent'
                boxShadow: if !@local.menu then '0px 1px 1px rgba(0,0,0,.1)'
                borderRadius: 8
                padding: '3px 4px'
                border: 'none'

              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32
                  @local.menu = true
                  save(@local)
                  if !@local.focus? 
                    set_focus(0)
                  e.preventDefault()
                  e.stopPropagation()

              Avatar 
                key: current_user.user
                hide_tooltip: true
                className: 'userbar_avatar'
                style: 
                  height: 35
                  width: 35
                  marginRight: 7
                  marginTop: 1
              I 
                className: 'fa fa-caret-down'
                style: 
                  visibility: if @local.menu then 'hidden'

            UL 
              id: 'profile_menu_popup'
              role: "menu"
              'aria-hidden': !@local.menu
              hidden: !@local.menu
              style: 
                listStyle: 'none'
                position: 'absolute'
                left: 'auto'
                right: if !@local.menu then -9999 else 0
                margin: '-42px 0 0 -8px'
                padding: "56px 14px 8px 8px"
                backgroundColor: '#eee'
                textAlign: 'right'
                zIndex: 999999


              for option, idx in menu_options
                LI 
                  key: option.label
                  role: "presentation"
                  A
                    ref: "menuitem-#{idx}"
                    role: "menuitem"
                    tabIndex: if @local.focus == idx then 0 else -1
                    className: 'menu_link'
                    href: option.href
                    key: option.href
                    style: 
                      color: if @local.focus == idx then 'black' else focus_color()
                      outline: 'none'

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

                    translator "user_menu.option.#{option.label}", option.label

              LI 
                role: "presentation"
                key: 'logout'
                A 
                  ref: "menuitem-#{menu_options.length}"
                  role: "menuitem"
                  tabIndex: -1
                  'data-action': 'logout'
                  className: 'menu_link'
                  style: 
                    color: if @local.focus == idx then 'black' else focus_color()
                    outline: 'none'
                    
                  onClick: logout
                  onTouchEnd: logout
                  onKeyDown: (e) => 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      logout() 
                      e.preventDefault()
                  onFocus: (e) => 
                    if @local.focus != menu_options.length 
                      set_focus menu_options.length
                    e.stopPropagation()
                  onMouseEnter: => 
                    if @local.focus != menu_options.length                         
                      set_focus menu_options.length
                  onBlur: => 
                    @local.focus = null 
                    save @local                      
                  onMouseExit: => 
                    @local.focus = null 
                    save @local

                  translator "auth.log_out", "Log out"


      else


        if fetch('/subdomain').SSO_domain
          A
            href: '/login_via_saml'
            treat_as_external_link: true
            style: 
              color: if !light_background then 'white'
              backgroundColor: 'transparent'
              border: 'none'
              textDecoration: 'none'

            translator "auth.log_in", "Log in"
        else 
          BUTTON
            className: 'profile_anchor login'
            'data-action': 'login'
            onClick: (e) =>
              reset_key 'auth',
                form: 'login'
                ask_questions: true

            style: 
              color: if !light_background then 'white'
              backgroundColor: 'transparent'
              border: 'none'

            translator "auth.log_in", "Log in"
    
  bitcoinVerification: -> 
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    DIV 
      style: 
        position: 'absolute'
        zIndex: 10
        left: -315
      onMouseEnter: => @local.show_verify = true; save @local
      onMouseLeave: => @local.show_verify = false; save @local 

      DIV 
        style: 
          backgroundColor: focus_color()
          color: 'white'
          fontWeight: 600
          padding: '4px 12px'
          fontSize: 21
          borderRadius: if ! @local.show_verify then 8
          position: 'relative'
          cursor: 'pointer'


        SPAN 
          style: cssTriangle 'right', focus_color(), 10, 12,
            position: 'absolute'
            right: -10
            top: 12

        'Please verify you are human!'

      if @local.show_verify

        today = new Date()
        dd = today.getDate()
        mm = today.getMonth() + 1
        yyyy = today.getFullYear()

        dd = '0' + dd if dd < 10
        mm = '0' + mm if mm < 10

        today = yyyy + '/' + mm + '/' + dd

        DIV 
          style: 
            width: 650
            position: 'absolute'
            right: 0
            zIndex: 999
            padding: 40
            backgroundColor: 'white'
            boxShadow: '0 1px 2px rgba(0,0,0,.3)'
            fontSize: 21

          DIV style: marginBottom: 20,
            "To verify you are human, write on a piece of paper:"

          DIV style: marginBottom: 20, marginLeft: 50,

            current_user.name
            BR null
            "bitcoin.consider.it"
            BR null
            today

          DIV style: marginBottom: 20,

            "Then take a photo of yourself with it, and email the photo to "

            A 
              href: 'mailto:verify@consider.it'
              style: 
                textDecoration: 'underline'
              'verify@consider.it' 

            ". This photo will be publicly visible proof that you are real!"

          DIV style: marginBottom: 20,
            "Yours,"
            BR null
            "The Admins"

          IMG 
            src: asset('bitcoin/verify example.jpg')
            style: 
              width: 570

          IMG 
            src: asset('bitcoin/verification-travis.jpg')
            style: 
              width: 570

          IMG 
            src: asset('bitcoin/KevinBitcoin.jpg')
            style: 
              width: 570    


styles += """
.menu_link {
  position: relative;
  bottom: 8px;
  padding-left: 27px;
  display: block;
  white-space: nowrap; }

.profile_menu_wrap:hover .profile_anchor{ color: inherit; }
"""