require './customizations'
require './drop_menu'

window.ProfileMenu = ReactiveComponent
  displayName: 'ProfileMenu'

  render : -> 
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'
    loc = fetch 'location'

    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    is_super = current_user.is_super_admin
    menu_options = [
      {href: '/dashboard/edit_profile', label: 'Edit Profile'},
      {href: '/dashboard/email_notifications', label: 'Email Settings'},
      if is_admin then {href: '/dashboard/data_import_export', label: 'Import / Export Data'} else null,
      if is_admin then {href: '/dashboard/application', label: 'Forum Settings'} else null,
      if is_super then {href: '/dashboard/customizations', label: 'Customizations'} else null,      
      if is_admin then {href: '/dashboard/roles', label: 'Permissions & Roles'} else null,
      if is_super then {href: '/dashboard/tags', label: 'User Tags'} else null,      
      if is_moderator then {href: '/dashboard/moderate', label: 'Moderate'} else null,
      {label: 'Log out', 'data-action': 'logout'}

    ]

    menu_options = _.compact menu_options

    light_background = loc.url.match('/dashboard/') or is_light_background() 

    DIV
      id: 'user_nav'
      style: _.defaults {}, (customization('profile_menu_style') or {}), (@props.style or {}),
        position: 'absolute'
        zIndex: 5
        right: 30
        fontSize: 26
        top: 17

      if current_user.logged_in
        DropMenu
          options: menu_options
          
          selection_made_callback: (option) ->
            if option.label == 'Log out'
              logout()
          
          render_anchor: (menu_showing) -> 
            [
              Avatar 
                key: current_user.user
                hide_tooltip: true
                className: 'userbar_avatar'
                style: 
                  height: 35
                  width: 35
                  marginRight: 12
                  marginTop: 1

              SPAN 
                style: 
                  color: if menu_showing then '#777'
                  fontSize: 18
                  position: 'relative'
                  top: -4
                  paddingRight: 12
                current_user.name
              I 
                className: 'fa fa-caret-down'
                style: 
                  visibility: if menu_showing then 'hidden'
            ]            
          render_option: (option) -> 
            if option.label == 'Log out'
              translator "auth.log_out", "Log out"
            else 
              translator "user_menu.option.#{option.label}", option.label
          
          anchor_style: 
            color: if !light_background then 'white'
            zIndex: 9999999999
            backgroundColor: 'rgba(255,255,255, .1)'
            # boxShadow: '0px 1px 1px rgba(0,0,0,.1)'
            borderRadius: 8
            padding: '3px 4px'
            fontWeight: 600
          
          anchor_when_open_style: 
            backgroundColor: 'transparent'
            boxShadow: 'none'
            color: '#666'
          
          menu_style: 
            left: 'auto'
            right: -9999
            margin: '-42px 0 0 -8px'
            padding: "56px 14px 8px 8px"
            backgroundColor: '#eee'
            textAlign: 'right'
            minWidth: '100%'
          
          menu_when_open_style: 
            right: 0
          
          option_style: 
            color: focus_color()
            position: 'relative'
            bottom: 8
            paddingLeft: 27
            display: 'block'
            whiteSpace: 'nowrap'  

          active_option_style: 
            color: 'black'


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
          DIV 
            style: 
              fontSize: 22  

            BUTTON
              className: 'profile_anchor create_account'
              'data-action': 'create_account'
              onClick: (e) =>
                reset_key 'auth',
                  form: 'create account'

              style: 
                color: if !light_background then 'white'
                backgroundColor: 'transparent'
                border: 'none'

              translator "auth.sign_up", "Sign up"

            SPAN 
              style: 
                color: if !light_background then 'white' else 'black'
                padding: '0 6px'
                opacity: .3
              "|"

            BUTTON
              className: 'profile_anchor login'
              'data-action': 'login'
              onClick: (e) =>
                reset_key 'auth',
                  form: 'login'

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


styles += """.profile_menu_wrap:hover .profile_anchor{ color: inherit; }
"""