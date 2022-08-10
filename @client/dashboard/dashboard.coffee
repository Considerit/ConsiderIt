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
    flex-wrap: nowrap;
    border-top: 1px solid #EEEEEE;
  }
  #DASHBOARD-menu {
    /* width: 265px; */
    flex-grow: 0;
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
      'Language Translation'
      TranslationsDash
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
    else 
      null
  title


window.Dashboard = ReactiveComponent
  displayName: 'Dashboard'
  render: -> 


    current_user = fetch '/current_user'
    is_admin = current_user.is_admin
    is_moderator = current_user.is_moderator
    is_super = current_user.is_super_admin

    loc = fetch 'location'

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
        style: 
          paddingLeft: 44
        if opts.icon && false
          SPAN
            className: 'icon'
            dangerouslySetInnerHTML: __html: dashboard_icons[opts.icon]( if active then 'white' else 'black')

        SPAN 
          className: 'label'
          translator "user_menu.option.#{opts.label}", opts.label

        if opts.paid && permit('configure paid feature') < 0
          UpgradeForumButton
            tag: SPAN
            style: 
              backgroundColor: '#666'


    draw_menu_separator = (title) -> 
      DIV 
        key: title
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
            draw_menu_option {href: '/dashboard/intake_questions', label: 'Sign-up Questions', icon: 'survey', paid: true}      
          ]


        if is_super 
          draw_menu_option {href: '/dashboard/customizations', label: 'Customizations', icon: 'coding'}      

        if is_admin
          [
            draw_menu_separator "administration"
            draw_menu_option {href: '/dashboard/moderate', label: 'Moderate', icon: 'moderation'} 
            draw_menu_option {href: '/dashboard/data_import_export', label: 'Import / Export Data', icon: 'upload', paid: true}
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
      border: 10px solid #{focus_blue};
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
    box-shadow: 0 1px 2px rgb(0 0 0 / 40%);

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
    box-shadow: 0 1px 2px rgb(0 0 0 / 20%)
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
