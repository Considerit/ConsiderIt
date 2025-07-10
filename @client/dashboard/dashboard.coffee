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
require './all_forums'
require './analytics'
require './meanies'


window.styles += """
  #DASHBOARD-flex-container {
    display: flex;
    flex-wrap: nowrap;
    border-top: 1px solid var(--brd_lightest_gray);
  }
  #DASHBOARD-menu {
    /* width: 265px; */
    flex-grow: 0;
    background: var(--bg_container);
    background: linear-gradient(180deg, var(--bg_container) 88%, var(--bg_light) 100%);
    padding-bottom: 70px;
    /* border: 1px solid var(--brd_light_gray); */
  }

  #DASHBOARD-menu a {
    text-decoration: none;
    color: var(--text_dark);
    padding: 8px 24px;
    display: block;
    font-weight: 400;
    white-space: nowrap;
    font-size: 14px;  
  } #DASHBOARD-menu a.active {
     background-color: var(--selected_color);
     color: var(--text_light);
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
    padding: 25px 24px 8px 24px;
    font-weight: 600;
    opacity: .5;
    font-size: 0px;
    visibility: hidden;    
  }  
  #DASHBOARD-main {
    flex: 1;
    padding: 30px 0 30px 72px;
    max-width: 1050px;
  }
  #DASHBOARD-title {
    font-weight: 700;
    font-size: 36px;
    color: var(--selected_color);
    margin-bottom: 36px;
  }

  #DASHBOARD-main .explanation {
    font-size: 14px;
    margin: 8px 0;
    color: var(--text_gray);
  }

  #DASHBOARD-main .explanation p {
    margin-bottom: 6px;
  }

  #DASHBOARD-main .input_group.checkbox .indented {
    flex: 1;
    padding-left: 18px;
    cursor: pointer;
  }

  [data-widget="Dashboard"] .btn {
    background-color: var(--selected_color);
  }

  @media #{NOT_LAPTOP_MEDIA} {
    #DASHBOARD-main {
      padding: 30px 24px;
    }
    #DASHBOARD-menu {
      display: none;
    }
  }

"""


get_dash_widget = (url) -> 
  switch url
    when '/dashboard/edit_profile'
      EditProfile
    when '/dashboard/email_notifications'
      Notifications
    when '/dashboard/data_import_export'
      DataDash
    when '/dashboard/moderate'
      ModerationDash
    when '/dashboard/application'
      ForumSettingsDash
    when '/dashboard/customizations'
      CustomizationsDash
    when '/dashboard/intake_questions'
      IntakeQuestions        
    when '/dashboard/roles'
      SubdomainRoles
    when '/dashboard/tags'
      UserTags
    when '/dashboard/translations'
      TranslationsDash
    when '/dashboard/all_forums'
      AllYourForums
    when '/dashboard/analytics'
      DataAnalytics
    when '/dashboard/meanies'
      Meanies 
    else 
      null
get_dash_title = (url) ->
  switch url
    when '/dashboard/edit_profile'
      title = 'Your Profile'
    when '/dashboard/email_notifications'
      title = 'Notifications'
    when '/dashboard/data_import_export'
      title = 'Data Import & Export'
    when '/dashboard/moderate'
      title = 'Moderation'
    when '/dashboard/application'
      title = 'Forum Settings'
    when '/dashboard/customizations'
      title = 'Customizations'
    when '/dashboard/intake_questions'
      title = 'Sign-up Questions'
    when '/dashboard/roles'
      title = 'Permissions & Roles'
    when '/dashboard/tags'
      title = 'User Tags'
    when '/dashboard/translations'
      title = 'Language Translation'
    when '/dashboard/all_forums'
      title = 'All Your Consider.it Forums'
    when '/dashboard/analytics'
      title = 'Analytics'
    when '/dashboard/meanies'
      title = 'Sniffing for Suspicious Activity'

    else 
      null
  title


window.Dashboard = ReactiveComponent
  displayName: 'Dashboard'
  render: -> 


    current_user = bus_fetch '/current_user'
    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    is_super = current_user.is_super_admin

    loc = bus_fetch 'location'

    title = get_dash_title loc.url
        

    if title == null 
      return DIV null, "No Dashboard at #{loc.url}"

    Widget = get_dash_widget(loc.url)

    draw_menu_option = (opts) ->
      active = opts.href == loc.url
      A 
        key: opts.href
        className: if active then 'active'
        href: opts.href
        # style: 
        #   paddingLeft: 44
        # if opts.icon && false
        #   SPAN
        #     className: 'icon'
        #     dangerouslySetInnerHTML: __html: dashboard_icons[opts.icon]( if active then 'white' else 'black')

        SPAN 
          className: 'label'
          translator "user_menu.option.#{opts.label}", opts.label

        if opts.paid && permit('configure paid feature') < 0
          UpgradeForumButton
            tag: SPAN
            style: 
              backgroundColor: "var(--bg_dark_gray)"


    draw_menu_separator = (title) -> 
      DIV 
        key: title
        translator "dashboard.section_title.#{title}", title

    DIV 
      id: "DASHBOARD-flex-container"
      "data-name": loc.url
      style: 
        width: DASHBOARD_WIDTH()

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
            draw_menu_option {href: '/dashboard/intake_questions', label: 'Sign-up Questions', icon: 'survey', paid: true}      
          ]


        if is_super 
          draw_menu_option {href: '/dashboard/customizations', label: 'Customizations', icon: 'coding'}      

        if is_admin
          [
            draw_menu_separator "administration"
            draw_menu_option {href: '/dashboard/moderate', label: 'Moderate', icon: 'moderation'} 
            draw_menu_option {href: '/dashboard/analytics', label: 'Analytics'} 
            draw_menu_option {href: '/dashboard/data_import_export', label: 'Import / Export Data', icon: 'upload', paid: true}
          ]
        
        if is_super 
          draw_menu_option {href: '/dashboard/tags', label: 'User Tags', icon: 'user_data'}   

        draw_menu_separator 'other'
        draw_menu_option {href: '/dashboard/translations', label: 'Language Translation', icon: 'translate'}   

        if current_user.logged_in
          draw_menu_option {href: '/dashboard/all_forums', label: 'All Your Forums'}   


      DIV 
        id: "DASHBOARD-main"


        H1
          id: "DASHBOARD-title"
          TRANSLATE "dashboard.#{title}.header",  title

        Widget? key: "/page#{loc.url}"





window.styles += """
  #modal #DASHBOARD-main {
    padding: 0px;
  }
"""

window.ModalDash = ReactiveComponent
  displayName: 'ModalDash'
  mixins: [Modal]

  render: ->
    Widget = get_dash_widget(@props.url)
    title = get_dash_title @props.url

    wrap_in_modal null, @props.done_callback, DIV 
      id: 'DASHBOARD-main' 

      H1
        style: 
          fontSize: 28
          marginBottom: 36

        translator "dashboard.section_title.#{title}", title 

      Widget()

      BUTTON 
        className: 'btn'
        style: 
          marginTop: 36
        onClick: @props.done_callback

        'Done'



if !browser.is_mobile
  window.styles += """
    .radio_group input[type='radio']{
      -webkit-appearance: button;
      -moz-appearance: button;
      appearance: button;
      border: 4px solid var(--brd_light_gray);
      border-top-color: var(--brd_mid_gray);
      border-left-color: var(--brd_mid_gray);
      background: var(--bg_light);
      width: 20px;
      height: 20px;
      border-radius: 50%;
      position: absolute;
      left: -36px;
      margin-top: 0;
    }
    .radio_group input[type='radio']:checked{
      border: 10px solid var(--focus_color);
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
    background-color: var(--bg_lighter_gray);  /* widget bg */
    -webkit-transition: .4s;
    transition: .4s;
    border-radius: 34px;
    box-shadow: 0 1px 2px var(--shadow_dark_50);

  }

  .toggle_switch .toggle_switch_circle:before {
    position: absolute;
    content: "";
    height: 18px;
    width: 18px;
    left: 4px;
    bottom: 4px;
    background-color: var(--bg_light);
    -webkit-transition: .4s;
    transition: .4s;
    border-radius: 50%;
    box-shadow: 0 1px 2px var(--shadow_dark_20)
  }

  input:checked + .toggle_switch_circle {
    background-color: var(--selected_color);
  }

  input:checked + .toggle_switch_circle:before {
    transform: translateX(26px);
  }
"""
