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
        title = 'Intake Questions'
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
        title = "No Dashboard at #{loc.url}"



    draw_menu_option = (opts) ->
      active = opts.href == loc.url
      A 
        className: if active then 'active'
        href: opts.href

        if opts.icon 
          SPAN
            className: 'icon'
            dangerouslySetInnerHTML: __html: icons[opts.icon]( if active then 'white' else 'black')

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

        if is_admin && fetch('/subdomain').plan 
          draw_menu_option {href: '/dashboard/intake_questions', label: 'Intake Questions', icon: 'survey'}      

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


icons = 
  avatar:    (color) -> "<svg fill=\"#{color}\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\" x=\"0px\" y=\"0px\" viewBox=\"23 25 53 50\" enable-background=\"new 0 0 100 100\" xml:space=\"preserve\"><path d=\"M25.7,75.2c0,0,0.1,0,0.1,0c1.1-0.1,1.9-1,1.8-2.1c-0.2-2.3,0-6.2,3.1-6.9c10.7-2.7,14.4-6.3,15.6-8.6  c1,0.3,2.1,0.4,3.2,0.4c0,0,0.1,0,0.1,0h0.2c0,0,0.1,0,0.1,0c1.3,0,2.5-0.2,3.7-0.5c1.3,2.4,4.9,6.1,15.6,8.8  c3.1,0.8,3.3,4.7,3.1,6.9c-0.1,1.1,0.7,2,1.8,2.1c0,0,0.1,0,0.1,0c1,0,1.8-0.8,1.9-1.8c0.4-5.9-1.8-9.9-6-11  c-9.6-2.4-12.3-5.4-13-6.7c0.7-0.5,1.3-1,1.9-1.7c4.9-5.5,4.1-14.9,4-15.9c-0.5-9.9-7.3-13.4-13-13.4c-0.1,0-0.2,0-0.3,0  c-0.1,0-0.2,0-0.3,0c-5.7,0-12.5,3.5-13,13.4c-0.1,0.9-0.9,10.4,4,15.9c0.7,0.8,1.4,1.4,2.2,1.9c-0.2,0.3-0.5,0.6-0.9,1  c-1.5,1.5-4.8,3.6-12.1,5.4c-4.2,1.1-6.4,5.1-6,10.9C23.9,74.4,24.7,75.2,25.7,75.2z M40.4,38.5c0,0,0-0.1,0-0.1  c0.4-9.1,7.1-9.8,9.1-9.8c0.1,0,0.2,0,0.2,0c0.1,0,0.1,0,0.2,0c0,0,0.1,0,0.2,0c2,0,8.7,0.7,9.1,9.8c0,0,0,0.1,0,0.1  c0.3,2.4,0.2,9.3-3.1,13c-1.5,1.7-3.6,2.6-6.3,2.6c0,0,0,0-0.1,0c0,0,0,0-0.1,0c-2.7,0-4.8-0.9-6.3-2.6  C39.5,47.1,40.4,38.6,40.4,38.5z\"/></svg>"
  upload:    (color) -> "<svg fill=\"#{color}\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"2 4 28 22\" x=\"0px\" y=\"0px\"><g data-name=\"upload cloud\"><path d=\"M30,17.9375a4.3632,4.3632,0,0,0-5.0087-4.327c.0011-.0578.0087-.1151.0087-.173A8.875,8.875,0,0,0,7.8149,10.3218,5.9967,5.9967,0,0,0,8,22.3125h3a1,1,0,0,0,0-2H8a4,4,0,0,1,0-8,4.0947,4.0947,0,0,1,.4268.0225.9464.9464,0,0,0,.118-.0113.9685.9685,0,0,0,.1976-.0188.9517.9517,0,0,0,.1826-.0614.8625.8625,0,0,0,.3111-.214.95.95,0,0,0,.1154-.1378.975.975,0,0,0,.0923-.182.9173.9173,0,0,0,.0523-.1033A6.8771,6.8771,0,0,1,22.86,14.8232a.9958.9958,0,0,0,.1459.7529l.0025.0069a1.0034,1.0034,0,0,0,1.376.3291,2.375,2.375,0,1,1,1.24,4.4h-4.5a1,1,0,0,0,0,2h4.9375a.9931.9931,0,0,0,.3983-.0845A4.38,4.38,0,0,0,30,17.9375Z\"/><path d=\"M20.6,16.6377l-4-3a.996.996,0,0,0-1.1992,0l-4,3a1,1,0,0,0,1.1992,1.6l2.4-1.8v10a1,1,0,0,0,2,0v-10l2.4,1.8a1,1,0,0,0,1.1992-1.6Z\"/></g></svg>"
  translate: (color) -> "<svg fill=\"#{color}\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\" x=\"0px\" y=\"0px\" viewBox=\"10 10 60 60\" style=\"enable-background:new 0 0 80 80;\" xml:space=\"preserve\"><g><path d=\"M40,16c0-2.21-1.79-4-4-4H16c-2.21,0-4,1.79-4,4v20c0,2.21,1.79,4,4,4h20c2.21,0,4-1.79,4-4V16z M38,36c0,1.1-0.9,2-2,2H16   c-1.1,0-2-0.9-2-2V16c0-1.1,0.9-2,2-2h20c1.1,0,2,0.9,2,2V36z\"/><path d=\"M64,40H44c-2.21,0-4,1.79-4,4v20c0,2.21,1.79,4,4,4h20c2.21,0,4-1.79,4-4V44C68,41.79,66.21,40,64,40z M59.32,59.05   c0.52,0.18,0.8,0.74,0.63,1.27C59.81,60.74,59.42,61,59,61c-0.1,0-0.21-0.02-0.32-0.05c-1.97-0.66-3.5-1.5-4.68-2.4301   c-1.18,0.9301-2.71,1.77-4.68,2.4301C49.21,60.98,49.1,61,49,61c-0.42,0-0.81-0.26-0.95-0.68c-0.17-0.53,0.11-1.09,0.63-1.27   c1.61-0.53,2.87-1.2,3.85-1.93c-2.02-2.27-2.46-4.72-2.54-6.12H49c-0.55,0-1-0.45-1-1s0.45-1,1-1h4v-1c0-0.55,0.45-1,1-1   s1,0.45,1,1v1h4c0.55,0,1,0.45,1,1s-0.45,1-1,1h-0.99c-0.08,1.4-0.52,3.85-2.54,6.12C56.45,57.85,57.71,58.51,59.32,59.05z\"/><path d=\"M54,55.79c1.6-1.82,1.96-3.72,2.02-4.79h-4.05C52.02,52.07,52.38,53.98,54,55.79z\"/><path d=\"M26.9229,19.6152C26.7676,19.2432,26.4033,19,26,19s-0.7676,0.2432-0.9229,0.6152l-2.7814,6.6755   C22.1133,26.4718,22,26.7224,22,27c0,0.0001,0.0001,0.0001,0.0001,0.0002l-1.9229,4.615   c-0.2129,0.5098,0.0283,1.0957,0.5381,1.3076c0.5098,0.2129,1.0947-0.0273,1.3076-0.5381L23.7498,28h4.5004l1.827,4.3848   C30.2373,32.7686,30.6084,33,31,33c0.1289,0,0.2588-0.0244,0.3848-0.0771c0.5098-0.2119,0.751-0.7979,0.5381-1.3076   L26.9229,19.6152z M24.5832,26L26,22.5996L27.4168,26H24.5832z\"/><path d=\"M43.1663,27.5197c0.0552,0.0881,0.1168,0.1675,0.1959,0.2344c0.0154,0.0131,0.0219,0.0335,0.0382,0.0457l4,3   C47.5801,30.9346,47.79,31,47.999,31c0.3047,0,0.6045-0.1377,0.8008-0.4004c0.332-0.4414,0.2422-1.0684-0.2002-1.3994L46.9999,28   H50c0.2861,0,7,0.0908,7,8c0,0.5527,0.4473,1,1,1s1-0.4473,1-1c0-9.8857-8.9102-10-9-10h-3.0001l1.5997-1.2002   c0.4424-0.3311,0.5322-0.958,0.2002-1.3994c-0.3311-0.4434-0.958-0.5322-1.3994-0.2002l-4,3   c-0.0163,0.0122-0.0228,0.0326-0.0382,0.0457c-0.0791,0.0669-0.1408,0.1464-0.196,0.2346   c-0.0216,0.0345-0.0496,0.0624-0.0668,0.0992C43.0391,26.7084,43,26.8484,43,27s0.0391,0.2916,0.0994,0.4203   C43.1166,27.4572,43.1447,27.4851,43.1663,27.5197z\"/><path d=\"M36.834,52.4807c-0.0552-0.0883-0.1171-0.1678-0.1962-0.2347c-0.0154-0.0131-0.0219-0.0335-0.0381-0.0457l-4-3   c-0.4404-0.3301-1.0674-0.2422-1.3994,0.2002c-0.332,0.4414-0.2422,1.0684,0.2002,1.3994L33.0001,52H30c-0.2861,0-7-0.0908-7-8   c0-0.5527-0.4473-1-1-1s-1,0.4473-1,1c0,9.8857,8.9102,10,9,10h3.0001l-1.5997,1.2002c-0.4424,0.3311-0.5322,0.958-0.2002,1.3994   C31.3965,56.8623,31.6963,57,32.001,57c0.209,0,0.4189-0.0654,0.5986-0.2002l4-3c0.0164-0.0122,0.0228-0.0326,0.0382-0.0457   c0.0791-0.0669,0.1409-0.1464,0.196-0.2346c0.0215-0.0345,0.0496-0.0623,0.0668-0.0991C36.9609,53.2917,37,53.1517,37,53   s-0.0391-0.2918-0.0994-0.4205C36.8835,52.5428,36.8555,52.5151,36.834,52.4807z\"/></g></svg>"
  bell:      (color) -> "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"20 15 60 70\" version=\"1.1\" x=\"0px\" y=\"0px\"><g stroke=\"none\" stroke-width=\"1\" fill=\"none\" fill-rule=\"evenodd\"><g fill-rule=\"nonzero\" fill=\"#{color}\"><path d=\"M58.9863458,71.5 C58.726905,76.2379945 54.8027842,80 50,80 C45.1972158,80 41.273095,76.2379945 41.0136542,71.5 L27.0025482,71.5 C25.3425883,71.5 24,70.1608104 24,68.5029699 L24,65.5 C24,62.189348 26.688664,59.5 30.0020869,59.5 C29.9981947,59.5 30,47.4992494 30,47.4992494 C30,39.0465921 35.2858464,31.6357065 43,28.7587819 L43,28.4952534 C43,24.6330455 46.138457,21.5 50,21.5 C53.8656855,21.5 57,24.6311601 57,28.4952534 L57,28.7589486 C64.7139633,31.6362562 70,39.0483724 70,47.4992494 L70,59.4982567 C73.3063923,59.5 76,62.1883045 76,65.5 L76,68.5029699 C76,70.1542433 74.6530016,71.5 72.9974518,71.5 L58.9863458,71.5 Z M54.9753124,71.5 L45.0246876,71.5 C45.2755498,74.0266613 47.4073259,76 50,76 C52.5926741,76 54.7244502,74.0266613 54.9753124,71.5 Z M72,67.5 L72,65.5 C72,64.3992101 71.099016,63.5 69.9979131,63.5 C67.7877428,63.5 66,61.7131252 66,59.4982567 L66,47.4992494 C66,40.3240131 61.2358497,34.083713 54.4456568,32.1249199 L53,31.7078857 L53,28.4952534 C53,26.8412012 51.6574476,25.5 50,25.5 C48.3460522,25.5 47,26.8437313 47,28.4952534 L47,31.7078537 L45.5542654,32.1248469 C38.7637896,34.083424 34,40.3222636 34,47.4992494 L34,59.4982567 C34,61.7067825 32.2078843,63.5 30.0020869,63.5 C28.8980308,63.5 28,64.3982593 28,65.5 L28,67.5 L72,67.5 Z\"/></g></g></svg>"
  forum:     (color) -> "<svg fill=\"#{color}\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\" x=\"0px\" y=\"0px\" viewBox=\"6 17 88 65\" enable-background=\"new 0 0 100 100\" xml:space=\"preserve\"><g><path d=\"M84.412,19.068H43.588c-3.916,0-7.177,2.833-7.857,6.557H15.588c-4.408,0-7.994,3.586-7.994,7.993v27.164   c0,4.408,3.586,7.994,7.994,7.994h19.456l12.867,11.518c0.468,0.42,1.065,0.638,1.668,0.638c0.368,0,0.738-0.081,1.083-0.247   c0.912-0.438,1.469-1.383,1.413-2.393l-0.532-9.516h4.868c3.593,0,6.639-2.384,7.642-5.653l11.858,10.614   c0.468,0.42,1.065,0.638,1.668,0.638c0.007,0,0.014-0.001,0.02,0c1.381,0,2.5-1.119,2.5-2.5c0-0.156-0.014-0.309-0.042-0.457   l-0.514-9.198h4.868c4.408,0,7.994-3.586,7.994-7.993V27.063C92.405,22.654,88.819,19.068,84.412,19.068z M56.412,63.776H48.9   c-0.687,0-1.344,0.283-1.816,0.782s-0.718,1.171-0.68,1.857l0.342,6.124l-9.079-8.126c-0.458-0.411-1.052-0.638-1.667-0.638H15.588   c-1.651,0-2.994-1.343-2.994-2.994V33.618c0-1.65,1.343-2.993,2.994-2.993h20.006v23.602c0,4.407,3.586,7.993,7.994,7.993h15.433   C58.511,63.143,57.539,63.776,56.412,63.776z M87.405,54.227c0,1.65-1.343,2.993-2.994,2.993H76.9   c-0.687,0-1.344,0.283-1.816,0.782s-0.718,1.171-0.68,1.857l0.342,6.124l-9.079-8.126C65.209,57.446,64.615,57.22,64,57.22H43.588   c-1.651,0-2.994-1.343-2.994-2.993V28.13c0-0.002,0-0.003,0-0.005s0-0.003,0-0.005v-1.058c0-1.651,1.343-2.994,2.994-2.994h40.823   c1.651,0,2.994,1.343,2.994,2.994V54.227z\"/></g></svg>"
  lock:      (color) -> "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 40 40\" version=\"1.1\" x=\"0px\" y=\"0px\"><g stroke=\"none\" stroke-width=\"1\" fill=\"none\" fill-rule=\"evenodd\"><rect x=\"0\" y=\"0\" width=\"40\" height=\"40\"/><path d=\"M20,20 C20.8817862,20 21.5484529,20 22,20 C30.836556,20 38,27.163444 38,36 L38,37 L36,37 L36,36 C36,28.2680135 29.7319865,22 22,22 C21.5473049,22 20.8806382,22 20,22 L20,22 C20,21.4477153 19.5522847,21 19,21 L19,20 L20,20 Z\" fill=\"#{color}\" fill-rule=\"nonzero\"/><path d=\"M22,16 C25.3137085,16 28,13.3137085 28,10 C28,6.6862915 25.3137085,4 22,4 C18.6862915,4 16,6.6862915 16,10 C16,13.3137085 18.6862915,16 22,16 Z M22,18 C17.581722,18 14,14.418278 14,10 C14,5.581722 17.581722,2 22,2 C26.418278,2 30,5.581722 30,10 C30,14.418278 26.418278,18 22,18 Z\" fill=\"#{color}\" fill-rule=\"nonzero\"/><path d=\"M11,32 C11,32.5522847 10.5522847,33 10,33 C9.44771525,33 9,32.5522847 9,32 L9,30.9146471 C8.41740381,30.7087289 8,30.1531094 8,29.5 C8,28.6715729 8.67157288,28 9.5,28 L10.5,28 C11.3284271,28 12,28.6715729 12,29.5 C12,30.1531094 11.5825962,30.7087289 11,30.9146471 L11,32 Z M4,23 L4,20 C4,16.6862915 6.6862915,14 10,14 C13.3137085,14 16,16.6862915 16,20 L16,23 L18,23 L18,38 L2,38 L2,23 L4,23 Z M4,25 L4,36 L16,36 L16,25 L4,25 Z M6,23 L14,23 L14,20 C14,17.790861 12.209139,16 10,16 C7.790861,16 6,17.790861 6,20 L6,23 Z\" fill=\"#{color}\" fill-rule=\"nonzero\"/></g></svg>"
  coding:    (color) -> "<svg fill=\"#{color}\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"5 5 37 37\" x=\"0px\" y=\"0px\"><g data-name=\"Layer 2\"><path d=\"M41,6H7A1,1,0,0,0,6,7V41a1,1,0,0,0,1,1H41a1,1,0,0,0,1-1V7A1,1,0,0,0,41,6ZM20,11a1,1,0,1,1-1-1A1,1,0,0,1,20,11Zm-4,0a1,1,0,1,1-1-1A1,1,0,0,1,16,11Zm-5-1a1,1,0,1,1-1,1A1,1,0,0,1,11,10ZM40,40H8V16H21a1,1,0,0,0,.71-.29L25.41,12H40Z\"/><path d=\"M17.29,22.29a1,1,0,0,0-1.41,0l-4,4a1,1,0,0,0,0,1.42l4,4a1,1,0,1,0,1.41-1.42L14,27l3.29-3.29A1,1,0,0,0,17.29,22.29Z\"/><path d=\"M30.88,31.71a1,1,0,0,0,1.41,0l4-4a1,1,0,0,0,0-1.42l-4-4a1,1,0,0,0-1.41,0,1,1,0,0,0,0,1.42L34.17,27l-3.29,3.29A1,1,0,0,0,30.88,31.71Z\"/><path d=\"M25.11,22.55l-4,8a1,1,0,0,0,.44,1.34A.93.93,0,0,0,22,32a1,1,0,0,0,.89-.55l4-8a1,1,0,1,0-1.78-.9Z\"/></g></svg>"
  moderation:(color) -> "<svg fill=\"#{color}\" xmlns:x=\"http://ns.adobe.com/Extensibility/1.0/\" xmlns:i=\"http://ns.adobe.com/AdobeIllustrator/10.0/\" xmlns:graph=\"http://ns.adobe.com/Graphs/1.0/\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\" x=\"0px\" y=\"0px\" viewBox=\"3 3 95 95\" style=\"enable-background:new 0 0 100 100;\" xml:space=\"preserve\"><switch><foreignObject requiredExtensions=\"http://ns.adobe.com/AdobeIllustrator/10.0/\" x=\"0\" y=\"0\" width=\"1\" height=\"1\"/><g i:extraneous=\"self\"><g><path d=\"M95.1,84.8L74,65.7c4.9-6.6,7.9-14.7,7.9-23.6C81.8,20.3,64,2.5,42.2,2.5S2.5,20.3,2.5,42.2s17.8,39.7,39.7,39.7     c8.8,0,17-2.9,23.6-7.9l19.1,21.1c0.2,0.2,0.3,0.4,0.5,0.5c3,2.7,7.6,2.5,10.3-0.5C98.3,92.1,98.1,87.5,95.1,84.8z M11.1,42.2     C11.1,25,25,11.1,42.2,11.1S73.2,25,73.2,42.2S59.3,73.2,42.2,73.2S11.1,59.3,11.1,42.2z\"/><path d=\"M52.6,30.8L38.1,46.5l-6.4-6.9c-1.6-1.7-4.3-1.8-6.1-0.2c-1.7,1.6-1.8,4.3-0.2,6.1l9.5,10.3c0.8,0.9,2,1.4,3.2,1.4     s2.3-0.5,3.2-1.4l17.7-19.1c1.6-1.7,1.5-4.5-0.2-6.1C57,29,54.2,29.1,52.6,30.8z\"/></g></g></switch></svg>"
  user_data: (color) -> "<svg fill=\"#{color}\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\" stroke-width=\"0.501\" stroke-linejoin=\"bevel\" fill-rule=\"evenodd\" version=\"1.1\" overflow=\"visible\" viewBox=\"10 20 80 55\" x=\"0px\" y=\"0px\"><g fill=\"none\" stroke=\"black\" transform=\"scale(1 -1)\"><g transform=\"translate(0 -96)\"><g><path d=\"M 8.625,23.701 L 8.625,72.3 C 8.625,73.334 9.465,74.175 10.5,74.175 L 85.501,74.175 C 86.535,74.175 87.376,73.334 87.376,72.3 L 87.376,23.701 C 87.376,22.666 86.535,21.826 85.501,21.826 L 10.5,21.826 C 9.465,21.826 8.625,22.666 8.625,23.701 Z M 83.626,25.576 L 83.626,70.425 L 12.375,70.425 L 12.375,25.576 L 83.626,25.576 Z M 17.778,33.112 L 17.778,34.987 C 17.778,38.826 19.254,41.73 21.775,43.611 C 24.216,45.432 27.432,46.147 30.721,46.147 C 34.008,46.147 37.224,45.432 39.665,43.611 C 42.187,41.728 43.662,38.829 43.662,34.987 L 43.662,33.112 L 17.778,33.112 Z M 37.422,40.605 C 35.856,41.774 33.539,42.397 30.721,42.397 C 27.901,42.397 25.583,41.774 24.017,40.605 C 22.904,39.774 22.06,38.586 21.707,36.869 L 39.733,36.869 C 39.379,38.587 38.536,39.773 37.422,40.605 Z M 49.433,42.366 C 49.433,43.4 50.273,44.241 51.308,44.241 L 67.636,44.241 C 68.67,44.241 69.511,43.4 69.511,42.366 C 69.511,41.331 68.67,40.491 67.636,40.491 L 51.308,40.491 C 50.273,40.491 49.433,41.331 49.433,42.366 Z M 23.246,55.433 C 23.246,59.558 26.593,62.906 30.719,62.906 C 34.844,62.906 38.192,59.558 38.192,55.433 C 38.192,51.307 34.844,47.96 30.719,47.96 C 26.593,47.96 23.246,51.307 23.246,55.433 Z M 49.433,49.866 C 49.433,50.9 50.273,51.741 51.308,51.741 L 75.886,51.741 C 76.92,51.741 77.761,50.9 77.761,49.866 C 77.761,48.831 76.92,47.991 75.886,47.991 L 51.308,47.991 C 50.273,47.991 49.433,48.831 49.433,49.866 Z M 34.442,55.433 C 34.442,57.487 32.773,59.156 30.719,59.156 C 28.664,59.156 26.996,57.487 26.996,55.433 C 26.996,53.378 28.664,51.71 30.719,51.71 C 32.773,51.71 34.442,53.378 34.442,55.433 Z M 49.433,57.366 C 49.433,58.4 50.273,59.241 51.308,59.241 L 75.886,59.241 C 76.92,59.241 77.761,58.4 77.761,57.366 C 77.761,56.331 76.92,55.491 75.886,55.491 L 51.308,55.491 C 50.273,55.491 49.433,56.331 49.433,57.366 Z\" stroke=\"none\" fill=\"#000000\" fill-rule=\"evenodd\" stroke-width=\"0.5\" marker-start=\"none\" marker-end=\"none\" stroke-miterlimit=\"79.8403193612775\"/></g></g></g></svg>"
  survey: (color) -> """<svg viewBox="80 0 540 540"> <g fill="#{color}" stroke="#{color}">  <path d="m386.96 206.64h114.8c10.641 0 19.039-8.3984 19.039-19.039 0-10.641-8.4023-19.602-19.039-19.602h-114.8c-10.641 0-19.039 8.3984-19.039 19.039 0 10.641 8.3984 19.602 19.039 19.602z"/>  <path d="m386.96 299.04h114.8c10.641 0 19.039-8.3984 19.039-19.039s-8.3984-19.039-19.039-19.039h-114.8c-10.641 0-19.039 8.3984-19.039 19.039s8.3984 19.039 19.039 19.039z"/>  <path d="m386.96 392h114.8c10.641 0 19.039-8.3984 19.039-19.039 0-10.641-8.3984-19.039-19.039-19.039h-114.8c-10.641 0-19.039 8.3984-19.039 19.039 0 10.078 8.3984 19.039 19.039 19.039z"/>  <path d="m189.84 244.16h16.801c6.1602 0 11.199-4.4805 11.762-10.078 2.2383-11.762 9.5195-26.32 33.039-26.32 17.922 0 25.762 9.5195 28.559 15.121 3.9219 8.3984 3.3594 17.922-1.6797 24.641-5.0391 7.2812-10.078 10.641-16.238 14.559-14.559 10.078-26.32 20.719-28.559 50.961 0 3.3594 1.1211 6.7188 3.3594 9.5195 2.2383 2.2383 5.6016 3.9219 8.9609 3.9219h16.801c6.1602 0 11.762-5.0391 12.32-11.199 1.1211-11.762 3.9219-14 11.199-19.602 6.7188-5.0391 16.238-11.199 25.199-24.078 14.559-19.602 16.238-45.922 5.0391-67.762-11.762-23.52-36.398-37.52-64.961-37.52-47.602 0-69.441 34.719-73.922 63.84-0.55859 3.3594 0.55859 6.7188 2.8008 9.5195 2.8008 2.7969 6.1602 4.4766 9.5195 4.4766z"/>  <path d="m278.88 369.04c0 13.609-11.031 24.641-24.641 24.641-13.605 0-24.637-11.031-24.637-24.641 0-13.605 11.031-24.641 24.637-24.641 13.609 0 24.641 11.035 24.641 24.641"/>  <path d="m596.96 72.801h-493.92c-10.641 0-19.039 8.3984-19.039 19.039v376.32c0 10.641 8.3984 19.039 19.039 19.039h493.92c10.641 0 19.039-8.3984 19.039-19.039v-376.32c0-10.641-8.3984-19.039-19.039-19.039zm-19.039 376.32h-455.84v-338.24h455.84z"/> </g></svg>"""

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
