window.ProfileMenu = ReactiveComponent
  displayName: 'ProfileMenu'

  render : -> 
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    is_evaluator = subdomain.assessment_enabled && current_user.is_evaluator
    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    menu_options = [
      {href: '/edit_profile', label: t('Edit Profile')},
      {href: '/dashboard/email_notifications', label: t('Email Settings')},
      if is_admin then {href: '/dashboard/import_data', label: 'Import Data'} else null,
      if is_admin then {href: '/dashboard/application', label: 'App Settings'} else null,
      if is_admin then {href: '/dashboard/roles', label: 'User Roles'} else null,
      if is_admin then {href: '/dashboard/tags', label: 'User Tags'} else null,      
      if is_moderator then {href: '/dashboard/moderate', label: 'Moderate'} else null,
      if is_evaluator then {href: '/dashboard/assessment', label: 'Fact-check'} else null 
    ]

    menu_options = _.compact menu_options

    hsl = parseCssHsl(subdomain.branding.primary_color)
    light_background = hsl.l > .75

    DIV
      id: 'user_nav'
      style:
        _.extend(
          position: 'absolute'
          zIndex: 1
          right: 30
          fontSize: 26
          top: 17,
          _.clone(@props.style))

      if current_user.logged_in

        DIV null,

          if subdomain.name == 'bitcoin' && \
             current_user.logged_in && \
             (!current_user.tags['verified']? || current_user.tags['verified'] in ['no', 'false'])
              
            DIV 
              style: 
                position: 'absolute'
                zIndex: 10
                left: -315
              onMouseEnter: => @local.show_verify = true; save @local
              onMouseLeave: => @local.show_verify = false; save @local 

              DIV 
                style: 
                  backgroundColor: focus_blue
                  color: 'white'
                  fontWeight: 600
                  padding: '4px 12px'
                  fontSize: 21
                  borderRadius: if ! @local.show_verify then 8
                  position: 'relative'
                  cursor: 'pointer'


                SPAN 
                  style: cssTriangle 'right', focus_blue, 10, 12,
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

          SPAN
            className: 'profile_menu_wrap'
            style:
              position: 'relative'

            onTouchEnd: => 
              @local.menu = !@local.menu
              save(@local)

            onMouseEnter: => @local.menu = true; save(@local)
            onMouseLeave: => @local.menu = false; save(@local)

            DIV 
              style: 
                display: if not @local.menu then 'none'
                position: 'absolute'
                marginTop: -8
                marginLeft: -8
                padding: 8
                paddingTop: 70
                paddingRight: 14
                backgroundColor: '#eee'
                right: 0
                textAlign: 'right'
                zIndex: 999999

              for option in menu_options
                A
                  className: 'menu_link'
                  href: option.href
                  key: option.href
                  option.label

              A 
                'data-action': 'logout'
                className: 'menu_link'
                onClick: logout
                onTouchEnd: logout
                t('Log out')

            SPAN 
              style: 
                color: if !light_background then 'white'
                position: 'relative'
                zIndex: 9999999999
                backgroundColor: if !@local.menu then 'rgba(255,255,255, .1)'
                boxShadow: if !@local.menu then '0px 1px 1px rgba(0,0,0,.1)'
                borderRadius: 8
                padding: '3px 4px'

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
                  #color: 'black'
      else
        A
          className: 'profile_anchor login'
          'data-action': 'login'
          onClick: (e) =>
            reset_key 'auth',
              form: 'login'
              ask_questions: true


          style: 
            color: if !light_background then 'white'
          t('Log in')
    


styles += """
.profile_navigation {
  text-align: right;
  width: 100%;
  padding: 20px 120px 0 0;
  font-size: 21px; }

.menu_link {
  position: relative;
  bottom: 8px;
  padding-left: 27px;
  display: block;
  color: #{focus_blue};
  white-space: nowrap; }

.menu_link:hover{ color: black; }

.profile_menu_wrap:hover .profile_anchor{ color: inherit; }
"""