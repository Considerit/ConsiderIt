require './customizations'
require './drop_menu'


styles += """
  button.create_account {
    background-color: var(--selected_color);
  }
  #user_nav {
    position: absolute;
    z-index: 999;
    right: 30px;
    font-size: 26px;    
  }
  @media #{PHONE_MEDIA} {
    #user_nav {
      right: 8px;
    }
  }

  .auth_area_banner a, .auth_area_banner .like_link {
    color: #ffffff;
    font-weight: 700;
    font-size: 18px;
    margin-left: 20px;
    position: relative;
    top: 0;    
  }

  .dark .auth_area_banner a, .dark .auth_area_banner .like_link {
    color: #ffffff;
  }

  .dark.image_background .auth_area_banner a, .dark.image_background .auth_area_banner .like_link {
    color: #000000;
  }

  .image_background .auth_area_banner {
    background-color: #000000aa;
    padding: 12px 36px;
    border-radius: 16px;
  }

  .dark.image_background .auth_area_banner {
    background-color: #ffffffaa;
  }

  [data-widget="ProfileMenu"] [data-widget="DropMenu"] .dropMenu-anchor {
    color: #ffffff;
    background-color: #00000088;

    z-index: 9999999999;
    border-radius: 8px;
    padding: 3px 4px;
    font-weight: 600;
    display: flex;
    align-items: center;
  }

  .dark [data-widget="ProfileMenu"] [data-widget="DropMenu"] .dropMenu-anchor {
    color: #000000;
    background-color: #ffffff88;    
  }


"""

window.ProfileMenu = ReactiveComponent
  displayName: 'ProfileMenu'

  render : -> 
    current_user = bus_fetch '/current_user'
    subdomain = bus_fetch '/subdomain'
    loc = bus_fetch 'location'

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
      if is_admin then {href: '/dashboard/analytics', label: 'Analytics'} else null,
      if is_moderator then {href: '/dashboard/moderate', label: 'Moderate'} else null,
      {label: 'Log out', 'data-action': 'logout'}

    ]

    menu_options = _.compact menu_options

    edit_forum = bus_fetch 'edit_forum'


    DIV
      id: 'user_nav'
      style: _.defaults {}, (customization('profile_menu_style') or {}), (@props.style or {}),
        top: if current_user.is_admin && (edit_forum.editing || loc.url.startsWith('/dashboard')) && permit('configure paid feature') < 0 then 57 else 17



      if current_user.logged_in

        if !edit_forum.editing

          DropMenu
            options: menu_options
            
            selection_made_callback: (option) ->
              if option.label == 'Log out'
                logout()
            
            render_anchor: (menu_showing) -> 
              [
                Avatar 
                  key: current_user.user
                  hide_popover: true
                  className: 'userbar_avatar'
                  style: 
                    height: 35
                    width: 35
                    marginRight: 12
                    marginTop: 1

                SPAN 
                  key: 'username'
                  style: 
                    color: if menu_showing then "var(--text_gray)"
                    fontSize: 18
                    position: 'relative'
                    paddingRight: 12
                  current_user.name
                I 
                  key: 'caret'
                  className: 'fa fa-caret-down'
                  style: 
                    visibility: if menu_showing then 'hidden'
              ]            
            render_option: (option) -> 
              if option.label == 'Log out'
                translator "auth.log_out", "Log out"
              else 
                translator "user_menu.option.#{option.label}", option.label
                        
            anchor_when_open_style: 
              backgroundColor: 'transparent'
              boxShadow: 'none'
              color: "var(--text_light_gray)"
            
            menu_style: 
              left: 'auto'
              right: -9999
              margin: '-42px 0 0 -8px'
              padding: "56px 14px 8px 8px"
              backgroundColor: "var(--bg_lightest_gray)"
              textAlign: 'right'
              minWidth: '100%'
            
            menu_when_open_style: 
              right: 0
            
            option_style: 
              color: "var(--focus_color)"
              position: 'relative'
              bottom: 8
              paddingLeft: 27
              display: 'block'
              whiteSpace: 'nowrap' 
              fontWeight: 600 

            active_option_style: 
              color: "var(--text_dark)"


      else

        DIV 
          className: "auth_area_banner" 

          if bus_fetch('/subdomain').SSO_domain
            A            
              href: '/login_via_saml'
              treat_as_external_link: true

              translator "auth.log_in", "Log in"
          else 
            DIV 
              style: 
                fontSize: 18  

              BUTTON
                className: 'btn create_account'
                'data-action': 'create_account'
                onClick: (e) =>
                  reset_key 'auth',
                    form: 'create account'

                translator "shared.auth.sign_up", "Sign up"

              BUTTON
                className: 'like_link'
                'data-action': 'login'
                onClick: (e) =>
                  reset_key 'auth',
                    form: 'login'



                translator "auth.log_in", "Log in"

