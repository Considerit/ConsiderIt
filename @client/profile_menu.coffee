window.ProfileMenu = ReactiveComponent
  displayName: 'ProfileMenu'

  componentDidMount : -> @setBgColor()
  componentDidUpdate : -> @setBgColor()
  setBgColor : -> 
    cb = (is_light) => 
      if @local.light_background != is_light
        @local.light_background = is_light
        save @local

    is_light = isLightBackground @getDOMNode(), cb

    cb is_light

  render : -> 
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')
    loc = fetch('location') # should rerender on a location change because background
                            # color might change

    is_evaluator = subdomain.assessment_enabled && current_user.is_evaluator
    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    menu_options = [
      {href: '/edit_profile', label: 'Edit Profile'},
      {href: '/dashboard/email_notifications', label: 'Email Settings'},
      if is_admin then {href: '/dashboard/import_data', label: 'Import Data'} else null,
      if is_admin then {href: '/dashboard/application', label: 'App Settings'} else null,
      if is_admin then {href: '/dashboard/roles', label: 'User Roles'} else null,
      if is_moderator then {href: '/dashboard/moderate', label: 'Moderate'} else null,
      if is_evaluator then {href: '/dashboard/assessment', label: 'Fact-check'} else null 
    ]

    menu_options = _.compact menu_options

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
              left: -122
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
              'Log out'

          SPAN 
            style: 
              color: if !@local.light_background then 'white'
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
      else
        A
          className: 'profile_anchor login'
          'data-action': 'login'
          onClick: (e) =>
            reset_key 'auth',
              form: 'login'

          style: 
            color: if !@local.light_background then 'white'
          'Log in'
    


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