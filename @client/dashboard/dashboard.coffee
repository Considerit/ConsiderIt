require '../form'
require '../shared'


require './edit_profile'
require './notifications'
require './roles'
require './tags'
require './translations'
require './import_export'
require './moderation'
require './forum_settings'
require './customize'
require './intake_questions'


window.styles += """
  #DASHBOARD-flex-container {
    display: flex;
    flex-wrap: no-wrap;
    border-top: 1px solid #EEEEEE;
  }
  #DASHBOARD-menu {
    width: 265px;
    background: rgb(246,246,246);
    background: linear-gradient(180deg, rgba(246,246,246,1) 88%, rgba(255,255,255,1) 100%);
    padding-bottom: 70px;
  }
  #DASHBOARD-menu a {
    text-decoration: none;
    color: black;
    padding: 8px 24px;
    display: block;
    font-weight: 600;
    white-space: nowrap;
  } #DASHBOARD-menu a.active {
     background-color: #{selected_color};
     color: white;
  } #DASHBOARD-menu a:hover {
  }

  #DASHBOARD-menu a .label {
    vertical-align: middle;
  }
  #DASHBOARD-menu a .icon {
    vertical-align: middle;
    padding-right: 18px;
    width: 36px;
    display: inline-block;
  }
  #DASHBOARD-menu div {
    text-transform: uppercase;
    padding: 56px 24px 8px 24px;
    font-weight: 600;
    opacity: .5;
    font-size: 14px;
  }  
  #DASHBOARD-main {
    flex: 1;
    padding: 30px 0 30px 72px;
    max-width: 850px;
  }
  #DASHBOARD-title {
    font-weight: 700;
    font-size: 36px;
    color: #{selected_color};
    margin-bottom: 36px;
  }

  #DASHBOARD-main .explanation {
    font-size: 14px;
    margin: 8px 0;
    color: #444;
  }

  #DASHBOARD-main .explanation p {
    margin-bottom: 6px;
  }

  #DASHBOARD-main .input_group.checkbox .indented {
    flex: 1;
    padding-left: 18px;
    cursor: pointer;
  }

  #DASHBOARD-main .btn {
    background-color: #{selected_color};
  }


"""

window.Dashboard = ReactiveComponent
  displayName: 'Dashboard'
  render: -> 


    current_user = fetch '/current_user'
    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    is_super = current_user.is_super_admin

    loc = fetch 'location'

    switch loc.url
      when '/dashboard/edit_profile'
        title = 'Your Profile'
        Widget = EditProfile
      when '/dashboard/email_notifications'
        title = 'Notifications'
        Widget = Notifications
      when '/dashboard/data_import_export'
        title = 'Data Import & Export'
        Widget = DataDash
      when '/dashboard/moderate'
        title = 'Moderation'
        Widget = ModerationDash
      when '/dashboard/application'
        title = 'Forum Settings'
        Widget = ForumSettingsDash
      when '/dashboard/customizations'
        title = 'Customizations'
        Widget = CustomizationsDash
      when '/dashboard/intake_questions'
        title = 'Sign-up Questions'
        Widget = IntakeQuestions        
      when '/dashboard/roles'
        title = 'Permissions & Roles'
        Widget = SubdomainRoles
      when '/dashboard/tags'
        title = 'User Tags'
        Widget = UserTags
      when '/dashboard/translations'
        title = 'Language Translation'
        Widget = TranslationsDash
      else 
        return DIV null, "No Dashboard at #{loc.url}"



    draw_menu_option = (opts) ->
      active = opts.href == loc.url
      A 
        className: if active then 'active'
        href: opts.href

        if opts.icon 
          SPAN
            className: 'icon'
            dangerouslySetInnerHTML: __html: dashboard_icons[opts.icon]( if active then 'white' else 'black')

        SPAN 
          className: 'label'
          translator "user_menu.option.#{opts.label}", opts.label



    draw_menu_separator = (title) -> 
      DIV null,
        translator "dashboard.section_title.#{title}", title

    DIV 
      id: "DASHBOARD-flex-container"
      "data-name": loc.url

      DIV
        id: "DASHBOARD-menu"

        draw_menu_separator 'settings'

        draw_menu_option {href: '/dashboard/edit_profile', label: 'Edit Profile', icon: 'avatar'}
        draw_menu_option {href: '/dashboard/email_notifications', label: 'Email Settings', icon: 'bell'}

        if is_admin 
          [
            draw_menu_separator "forum setup"
            draw_menu_option {href: '/dashboard/application', label: 'Forum Settings', icon: 'forum'} 
            draw_menu_option {href: '/dashboard/roles', label: 'Permissions & Roles', icon: 'lock'} 
          ]

        if (is_admin && fetch('/subdomain').plan) || is_super 
          draw_menu_option {href: '/dashboard/intake_questions', label: 'Sign-up Questions', icon: 'survey'}      

        if is_super 
          draw_menu_option {href: '/dashboard/customizations', label: 'Customizations', icon: 'coding'}      

        if is_admin
          [
            draw_menu_separator "administration"
            draw_menu_option {href: '/dashboard/moderate', label: 'Moderate', icon: 'moderation'} 
            draw_menu_option {href: '/dashboard/data_import_export', label: 'Import / Export Data', icon: 'upload'}
          ]
        
        if is_super 
          draw_menu_option {href: '/dashboard/tags', label: 'User Tags', icon: 'user_data'}   

        draw_menu_separator 'other'
        draw_menu_option {href: '/dashboard/translations', label: 'Language Translation', icon: 'translate'}   


      DIV 
        id: "DASHBOARD-main"


        H1
          id: "DASHBOARD-title"
          TRANSLATE "dashboard.#{title}.header",  title

        Widget? key: "/page#{loc.url}"



if !browser.is_mobile
  window.styles += """
    .radio_group input[type='radio']{
      -webkit-appearance: button;
      -moz-appearance: button;
      appearance: button;
      border: 4px solid #ccc;
      border-top-color: #bbb;
      border-left-color: #bbb;
      background: #fff;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      position: absolute;
      left: -36px;
    }
    .radio_group input[type='radio']:checked{
      border: 20px solid #{focus_blue};
    }

    .radio_group {
      position: relative;
      margin-left: 36px;    
    }
  """

window.styles += """

  /* From https://www.w3schools.com/howto/howto_css_switch.asp */
  /* The switch - the box around the slider */

  .toggle_switch {
    position: relative;
    display: inline-block;
    width: 52px;
    height: 26px;
  }

  /* Hide default HTML checkbox */
  .toggle_switch input {
    opacity: 0;
    width: 0;
    height: 0;
  }

  /* The slider */
  .toggle_switch .toggle_switch_circle {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: #ccc;
    -webkit-transition: .4s;
    transition: .4s;
    border-radius: 34px;

  }

  .toggle_switch .toggle_switch_circle:before {
    position: absolute;
    content: "";
    height: 18px;
    width: 18px;
    left: 4px;
    bottom: 4px;
    background-color: white;
    -webkit-transition: .4s;
    transition: .4s;
    border-radius: 50%;
  }

  input:checked + .toggle_switch_circle {
    background-color: #{selected_color};
  }

  # input:focus + .toggle_switch_circle {
  #   box-shadow: 0 0 1px #{selected_color};
  # }

  input:checked + .toggle_switch_circle:before {
    -webkit-transform: translateX(26px);
    -ms-transform: translateX(26px);
    transform: translateX(26px);
  }
"""
