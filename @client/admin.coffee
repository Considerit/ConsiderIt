# Admin components, like moderation and factchecking backend

# Experimenting with sharing css styles between components via js objects
task_area_header_style = {fontSize: 24, fontWeight: 400, margin: '10px 0'}
task_area_bar = {padding: '4px 30px', fontSize: 24, borderRadius: '8px 8px 0 0', height: 35, backgroundColor: 'rgba(0,0,55,.1)'}
task_area_section_style = {margin: '10px 0px 20px 0px', position: 'relative'}
task_area_style = {cursor: 'auto', width: 3 * CONTENT_WIDTH / 4, backgroundColor: '#F4F0E9', position: 'absolute', left: CONTENT_WIDTH/4, top: -35, borderRadius: 8}


####
# AccessControlled
#
# Mixin that implements a check for whether this user can access
# the component (that this is mixed into). 
#
# The server has to respond with
# a keyed object w/ access_denied set for the component's key 
# for this mixin to be useful.
#
# Note that the component needs to explicitly call the accessGranted method
# in its render function. 
#
AccessControlled = 
  accessGranted: -> 
    current_user = fetch '/current_user'

    ####
    # HACK: Clear out statebus if current_user changed. See comment below.
    local_but_not_component_unique = fetch "local-#{@props.key}"
    access_attrs = ['verified', 'logged_in', 'email']
    if local_but_not_component_unique._last_current_user && @data().access_denied 
      reduced_user = _.map access_attrs, (attr) -> current_user[attr] 
      for el,idx in reduced_user
        if el != local_but_not_component_unique._last_current_user[idx]
          delete @data().access_denied
          arest.serverFetch @props.key
          break
    ####


    if @data().access_denied 
      # Let's recover, depending on the recourse the server dictates
      recourse = @data().access_denied
      switch recourse

        when 'lack of credentials'
          window.app_router.navigate("/", {trigger: true})

        when 'login required'
          @root.auth_mode = 'login'
          @root.auth_reason = 'Access this page'
          save @root

        when 'email not verified'
          @root.auth_mode = 'verify'
          @root.auth_reason = 'Access this page'
          save @root

      #######
      # Hack! The server will return access_denied on the page, e.g.: 
      # 
      #   { key: '/page/dashboard/moderate', access_denied: 'login required' }
      # 
      # Here's a problem: 
      # What happens if the user logs in? Or if they verify their email?
      # We will need to refetch that page on the server so we can proceed 
      # with the proper data and without the access denied error.
      #
      # My solution here is to store relevant values of /current_user the last time
      # an access denied error was registered. Then everytime one of those attributes
      # changes (i.e. when the user might be able to access), we'll issue a server
      # fetch on the page.
      #
      local_but_not_component_unique._last_current_user = _.map access_attrs, (attr) -> current_user[attr] 
      save local_but_not_component_unique
      #
      # This hack will be unnecessary by having a server that pushes out changes to 
      # subscribed keys. In that world, the server logs a dependency for a client 
      # on an access-controlled resource. If the client ever gains the proper 
      # authorization, the server can just push down the data.

    return !@data().access_denied 


DashHeader = ReactiveComponent
  displayName: 'DashHeader'

  render : ->
    subdomain = fetch '/subdomain'
    DIV 
      style: 
        position: 'relative'
        backgroundColor: subdomain.branding.primary_color
        color: 'white'

      DIV style: {width: CONTENT_WIDTH, margin: 'auto', position: 'relative'},
        A
          className: 'homepage_link'
          onClick: (=> window.app_router.navigate("/", {trigger: true}))
          style: {position: 'absolute', display: 'inline-block', top: 25, left: -40},
          I className: 'fa fa-home', style: {fontSize: 28}
        
        H1 style: {fontSize: 28, padding: '20px 0', color: 'white'}, @props.name   

ImportDataDash = ReactiveComponent
  displayName: 'ImportDataDash'
  mixins: [AccessControlled]

  render : ->
    return SPAN(null) if !@accessGranted()

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    if subdomain.name == 'livingvotersguide'
      tables = ['Measures', 'Candidates', 'Jurisdictions']
    else 
      tables = ['Users', 'Proposals', 'Opinions', 'Points', 'Comments']

    DIV null, 

      DashHeader name: 'Import Data'

      DIV style: {width: CONTENT_WIDTH, margin: '15px auto'},
        P style: {marginBottom: 6}, 
          "Import data into Considerit. The spreadsheet should be in comma separated value format (.csv)."

        if subdomain.name != 'livingvotersguide'

          DIV null,
            P style: {marginBottom: 6}, 
              "To refer to a User, use their email address. For example, if you’re uploading points, in the user column, refer to the author via their email address. "
            P style: {marginBottom: 6}, 
              "To refer to a Proposal, refer to its url. "
            P style: {marginBottom: 6}, 
              "To refer to a Point, make up an id for it and use that."
            P style: {marginBottom: 6}, 
              "You do not have to upload every file, just what you need to. Importing the same spreadsheet multiple times is ok."

        FORM action: '/dashboard/import_data',
          TABLE null, TBODY null,
            for table in tables
              TR null,
                TD style: {paddingTop: 20, textAlign: 'right'}, 
                  LABEL style: {whiteSpace: 'nowrap'}, htmlFor: "#{table}-file", "#{table} (.csv)"
                  DIV null, A style: {textDecoration: 'underline', fontSize: 12}, href: "/example_import_csvs/#{table.toLowerCase()}.csv", 'Example'
                TD style: {padding: '20px 0 0 20px'}, 
                  INPUT id: "#{table}-file", name: "#{table.toLowerCase()}-file", type:'file', style: {backgroundColor: considerit_blue, color: 'white', fontWeight: 700, borderRadius: 8, padding: 6}
            

            if current_user.is_super_admin
              [TR null,
                TD null
                TD style: {padding: '20px 0 20px 20px'}, 
                  INPUT type: 'checkbox', name: 'generate_inclusions', id: 'generate_inclusions'
                  LABEL htmlFor: 'generate_inclusions', 
                    """
                    Generate opinions & inclusions of points?
                    It requires a proposal file; for each proposal in the file, this option will increase by 
                    2x the number of existing opinions. Each simulated opinion will include two points. 
                    Stances and inclusions will not be assigned randomly, but rather following a 
                    rich-get-richer model. You can use this option multiple times. This option is only good for demos.
                    """

              TR null,
                TD null
                TD style: {padding: '20px 0 20px 20px'}, 
                  INPUT type: 'checkbox', name: 'assign_pics', id: 'assign_pics'
                  LABEL htmlFor: 'assign_pics', 
                    """
                    Assign a random profile picture for users without an avatar url
                    """]

            TR null,
              TD null
              TD style: {padding: '20px 0 0 20px'}, 
                A 
                  id: 'submit_import'
                  style: {backgroundColor: '#7ED321', color: 'white', border: 'none', borderRadius: 8, fontSize: 24, fontWeight: 700, padding: '10px 20px'}
                  onClick: => 
                    $('html, #submit_import').css('cursor', 'wait')
                    $(@getDOMNode()).find('form').ajaxSubmit
                      type: 'POST'
                      data: 
                        authenticity_token: current_user.csrf
                        trying_to: 'update_avatar_hack'   
                      success: (data) => 
                        if data[0].errors
                          @local.successes = null
                          @local.errors = data[0].errors
                          save @local
                        else
                          $('html, #submit_import').css('cursor', '')
                          # clear out statebus 
                          arest.clear_matching_objects((key) -> key.match( /\/page\// ))
                          @local.errors = null
                          @local.successes = data[0]
                          save @local
                      error: (result) => 
                        $('html, #submit_import').css('cursor', '')
                        @local.successes = null                      
                        @local.errors = ['Unknown error parsing the files. Email tkriplean@gmail.com.']
                        save @local
                        

                  'Done. Upload!'


        if @local.errors && @local.errors.length > 0
          DIV style: {borderRadius: 8, margin: 20, padding: 20, backgroundColor: '#FFE2E2'}, 
            H1 style: {fontSize: 18}, 'Ooops! There are errors in the uploaded files:'
            for error in @local.errors
              DIV style: {marginTop: 10}, error

        if @local.successes
          DIV style: {borderRadius: 8, margin: 20, padding: 20, backgroundColor: '#E2FFE2'}, 
            H1 style: {fontSize: 18}, 'Success! Here\'s what happened:'
            for table in tables
              if @local.successes[table.toLowerCase()]
                DIV null,
                  H1 style: {fontSize: 15, fontWeight: 300}, table
                  for success in @local.successes[table.toLowerCase()]
                    DIV style: {marginTop: 10}, success

AppSettingsDash = ReactiveComponent
  displayName: 'AppSettingsDash'
  mixins: [AccessControlled]

  render : -> 
    return SPAN(null) if !@accessGranted()


    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    DIV className: 'app_settings_dash',

      STYLE dangerouslySetInnerHTML: __html: #dangerously set html is so that the type="text" doesn't get escaped
        """
        .app_settings_dash { font-size: 18px }
        .app_settings_dash input[type="text"] { display: block; width: 600px; font-size: 18px; padding: 4px 8px; } 
        .app_settings_dash .input_group { margin-bottom: 12px; }
        """

      DashHeader name: 'Application Settings'

      if subdomain.name
        DIV style: {width: CONTENT_WIDTH, margin: '20px auto'}, 

          DIV className: 'input_group',
            LABEL htmlFor: 'app_title', 'The name of this application'
            INPUT 
              id: 'app_title'
              type: 'text'
              name: 'app_title'
              defaultValue: subdomain.app_title
              placeholder: 'Shows in email subject lines and in the window title.'

          DIV className: 'input_group',
            LABEL htmlFor: 'external_project_url', 'Project url'
            INPUT 
              id: 'external_project_url'
              type: 'text'
              name: 'external_project_url'
              defaultValue: subdomain.external_project_url
              placeholder: 'A link to the main project\'s homepage, if any.'

          DIV className: 'input_group',
            LABEL htmlFor: 'notifications_sender_email', 'Contact email'
            INPUT 
              id: 'notifications_sender_email'
              type: 'text'
              name: 'notifications_sender_email'
              defaultValue: subdomain.notifications_sender_email
              placeholder: 'Sender email address for notification emails. Default is admin@consider.it.'

          DIV className: 'input_group',
            LABEL htmlFor: 'about_page_url', 'About Page URL'
            INPUT 
              id: 'about_page_url'
              type: 'text'
              name: 'about_page_url'
              defaultValue: subdomain.about_page_url
              placeholder: 'The about page will then contain a window to this url.'

          if current_user.is_super_admin
            DIV null,
              DIV className: 'input_group',
                LABEL htmlFor: 'masthead_header_text', 'Masthead header text'
                INPUT 
                  id: 'masthead_header_text'
                  type: 'text'
                  name: 'masthead_header_text'
                  defaultValue: subdomain.branding.masthead_header_text
                  placeholder: 'This will be shown in bold white text across the top of the header.'

              DIV className: 'input_group',
                LABEL htmlFor: 'primary_color', 'Primary color (CSS format)'
                INPUT 
                  id: 'primary_color'
                  type: 'text'
                  name: 'primary_color'
                  defaultValue: subdomain.branding.primary_color
                  placeholder: 'The primary brand color. Needs to be dark.'

              FORM id: 'subdomain_files', action: '/update_images_hack',
                DIV className: 'input_group',
                  DIV null, LABEL htmlFor: 'masthead', 'Masthead background image. Should be pretty large.'
                  INPUT 
                    id: 'masthead'
                    type: 'file'
                    name: 'masthead'
                    onChange: (ev) =>
                      @submit_masthead = true

                DIV className: 'input_group',
                  DIV null, LABEL htmlFor: 'logo', 'Organization\'s logo'
                  INPUT 
                    id: 'logo'
                    type: 'file'
                    name: 'logo'
                    onChange: (ev) =>
                      @submit_logo = true

              DIV className: 'input_group',
                INPUT type: 'checkbox', name: 'light_masthead', id: 'light_masthead', defaultChecked: subdomain.branding.light_masthead
                LABEL htmlFor: 'light_masthead', 
                  "Is the masthead image a light color (if not specified, is the primary color light)?"


          DIV className: 'input_group',
            BUTTON className: 'primary_button button', onClick: @submit, 'Save'

          if @local.save_complete
            DIV style: {color: 'green'}, 'Saved.'

          if @local.errors
            DIV style: {color: 'red'}, 'Error uploading files!'


  submit : -> 
    submitting_files = @submit_logo || @submit_masthead

    subdomain = fetch '/subdomain'

    fields = ['about_page_url', 'notifications_sender_email', 'app_title', 'external_project_url']

    for f in fields
      subdomain[f] = $(@getDOMNode()).find("##{f}").val()

    subdomain.branding =
      primary_color: $('#primary_color').val()
      masthead_header_text: $('#masthead_header_text').val()
      light_masthead: $('#light_masthead:checked').length > 0
    @local.save_complete = @local.errors = false
    save @local

    save subdomain, => 

      @local.save_complete = true if !submitting_files
      save @local

      if submitting_files
        current_user = fetch '/current_user'
        $('#subdomain_files').ajaxSubmit
          type: 'PUT'
          data: 
            authenticity_token: current_user.csrf
          success: =>
            location.reload()
          error: => 
            @local.errors = true
            save @local


ProposalShare = ReactiveComponent
  displayName: 'ProposalShare'

  render : -> 

    subdomain = fetch '/subdomain'

    roles = [ 
      {name: 'editor', label: 'Editors', description: 'Can modify the description of the proposal, as well as write, comment, and opine.', icon: 'fa-edit', wildcard_label: 'Anyone who can access can edit'}, 
      {name: 'writer', label: 'Writers', description: 'Can write pro and con points that are shared with others. Any writer can comment and opine.', icon: 'fa-th-list', wildcard_label: 'Anyone who can access can write'},
      {name: 'commenter', label: 'Commenters', description: 'Can comment on shared pro and con points.', icon: 'fa-comment', wildcard_label: 'Anyone who can access can comment'},
      {name: 'opiner', label: 'Opiners', description: 'Can contribute their opinions of this proposal. But not original content.', icon: 'fa-bar-chart', wildcard_label: 'Anyone who can access can opine'},
      {name: 'observer', label: 'Observers', description: 'Can access this proposal. But that’s it. Anyone added to the above categories is also an observer.', icon: 'fa-eye', wildcard_label: "Anyone who can access #{subdomain.name} can view"}
    ]

    roles = _.compact roles

    DIV null, 

      DIV style: {width: BODY_WIDTH, margin: 'auto'},
        for role,idx in roles
          DIV style: {marginTop: 24}, key: idx,
            H1 style: {fontSize: 18, position: 'relative'}, 
              I className: "fa #{role.icon}", style: {position: 'absolute', top: 2, left: -35, fontSize: 24}
              role.label
            
            SPAN style: {fontSize: 14}, role.description

            PermissionBlock key: role.name, target: @proposal, role: role
        
        DIV style: {marginLeft: -35, marginTop: 12},
          Invite roles: roles, target: @proposal



RolesDash = ReactiveComponent
  displayName: 'RolesDash'
  mixins: [AccessControlled]

  render : -> 
    return SPAN(null) if !@accessGranted()

    subdomain = fetch '/subdomain'

    roles = [ 
      {name: 'admin', label: 'Administrators', description: 'Can configure everything related to this site, including all of the below.', icon: 'fa-cog'}, 
      {name: 'moderator', label: 'Moderators', description: 'Can moderate user content. Will receive emails for content needing moderation.', icon: 'fa-fire-extinguisher'},
      if subdomain.assessment_enabled then {name: 'evaluator', label: 'Fact checkers', description: 'Can validate claims. Will receive emails when a fact-check is requested.', icon: 'fa-flag-checkered'} else null,
      {name: 'proposer', label: 'Proposers', description: 'Can add new proposals.', icon: 'fa-lightbulb-o', wildcard_label: 'Any registered visitor can post new proposals'},
      {name: 'visitor', label: 'Visitors', description: 'Can access this site.', icon: 'fa-android', wildcard_label: 'Anyone can visit this site.'} #'fa-key'

    ]

    roles = _.compact roles

    DIV null, 

      DashHeader name: 'User Roles'

      DIV style: {width: CONTENT_WIDTH, margin: 'auto'},
        for role,idx in roles
          DIV style: {marginTop: 24}, key: idx,
            H1 style: {fontSize: 18, position: 'relative'}, 
              I className: "fa #{role.icon}", style: {position: 'absolute', top: 2, left: -35, fontSize: 24}
              role.label
            
            SPAN style: {fontSize: 14}, role.description

            PermissionBlock key: role.name, target: '/subdomain', role: role
        
        DIV style: {marginLeft: -35, marginTop: 12},
          Invite roles: roles, target: '/subdomain'

invited_user_style = {display: 'inline-block', padding: '6px 12px', fontWeight: 400, fontSize: 13, backgroundColor: 'rgb(217, 227, 244)', color: 'black', borderRadius: 8, margin: 4}

Invite = ReactiveComponent
  displayName: 'Invite'

  render: ->
    target = fetch @props.target
    users = fetch '/users'

    if !@local.role
      @local.added = []
      @local.role = @props.roles[0]
      save @local


    DIV style: {position: 'relative', backgroundColor: '#E7F2FF', padding: '18px 24px'}, 
      STYLE null, ".invite_menu_item:hover{background-color: #414141; color: white}"

      DIV style: {fontWeight: 500, fontSize: 18, marginBottom: 6, display: 'inline-block'}, 
        DIV 
          id: 'select_new_role'
          style: {backgroundColor: 'rgba(100,100,150,.1)'
          padding: '8px 12px', borderRadius: 8, cursor: 'pointer'}
          onClick: =>
            $(document).on 'click.select_new_role', (e) =>
              if e.target.id != 'select_new_role'
                @local.select_new_role = false
                save(@local)
                $(document).off('click.select_new_role')

            @local.select_new_role = true
            save @local 
          I className: "fa #{@local.role.icon}", style: {displayName: 'inline-block', margin: '0 8px 0 0'} 
          "Add #{@local.role.label}"
          I style: {marginLeft: 8}, className: "fa fa-caret-down"

        if @local.select_new_role
          UL style: {width: 500, position: 'absolute', zIndex: 99, listStyle: 'none', backgroundColor: '#fff', border: '1px solid #eee'},
            for role,idx in @props.roles
              if role.name != @local.role.name
                LI 
                  className: 'invite_menu_item'
                  style: {padding: '2px 12px', fontSize: 18, cursor: 'pointer', borderBottom: '1px solid #fafafa'}
                  key: idx
                  onClick: do(role) => (e) => 
                    @local.role = role
                    @local.added = []
                    save @local
                    e.stopPropagation()

                  I className: "fa #{role.icon}", style: {displayName: 'inline-block', margin: '0 8px 0 0'} 
                  "Add #{role.label}"

      if @local.added.length > 0
        DIV null,
          for user_key, idx in @local.added
            
            SPAN key: user_key, style: invited_user_style, 
              SPAN null,
                if user_key && user_key[0] == '/'

                  user = fetch user_key
                  SPAN null,
                    if user.avatar_file_name
                      Avatar key: user_key, hide_name: true, style: {width: 20, height: 20, marginRight: 5}

                    if user.name 
                      user.name 
                    else 
                      user.email
                else
                  user_key
              SPAN
                style: {cursor: 'pointer', marginLeft: 8}
                onClick: do (user_key, role) => =>
                  @local.added = _.without @local.added, user_key
                  save @local
                'x'

      DIV null,
        INPUT 
          id: 'filter'
          type: 'text'
          style: {fontSize: 18, width: 500, padding: '3px 6px'}
          autoComplete: 'off'
          placeholder: "Name or email..."
          onChange: (=> @local.filtered = $(@getDOMNode()).find('#filter').val(); save(@local);)
          onKeyPress: (e) => 
            # enter key pressed...
            if e.which == 13
              e.preventDefault()
              $filter = $(@getDOMNode()).find('#filter')
              candidates = $filter.val()
              $filter.val('')
              if candidates
                candidates = candidates.split(',')
                for candidate_email in candidates
                  candidate_email = candidate_email.trim()
                  if candidate_email.indexOf(' ') < 0 && candidate_email.indexOf('@') > 0 && candidate_email.indexOf('.') > 0
                    @local.added.push candidate_email
                save @local
          onFocus: (e) => 
            @local.selecting = true
            save(@local)
            e.stopPropagation()
            $(document).on 'click.roles', (e) =>
              if e.target.id != 'filter'
                @local.selecting = false
                @local.filtered = null
                $(@getDOMNode()).find('#filter').val('')
                save(@local)
                $(document).off('click.roles')
            return false

      if @local.selecting
        UL style: {width: 500, position: 'absolute', zIndex: 99, listStyle: 'none', backgroundColor: '#fff', border: '1px solid #eee'},
          for user,idx in _.filter(users.users, (u) => 
            target.roles[@local.role.name].indexOf(u.key) < 0 && @local.added.indexOf(u.key) < 0 && (!@local.filtered || "#{u.name} <#{u.email}>".indexOf(@local.filtered) > -1) )
            LI 
              className: 'invite_menu_item'
              style: {padding: '2px 12px', fontSize: 18, cursor: 'pointer', borderBottom: '1px solid #fafafa'}
              key: idx

              onClick: do(user) => (e) => 
                @local.added.push user.key
                save @local
                e.stopPropagation()

              "#{user.name} <#{user.email}>"

      DIV style: {marginTop: 20},
        INPUT 
          type: 'checkbox'
          id: 'send_email_invite'
          name: 'send_email_invite'
          onClick: =>
            @local.send_email_invite = !@local.send_email_invite
            save @local

        LABEL htmlFor: 'send_email_invite', 'Send email invitation'

        if @local.send_email_invite
          DIV style: {marginLeft: 20, marginTop: 10},
            AutoGrowTextArea 
              id: 'custom_email_message'
              name: 'custom_email_message'
              placeholder: '(optional) custom message'
              style: {width: 500, fontSize: 14, padding: '8px 14px'}

      DIV
        style: {backgroundColor: considerit_blue, color: 'white', padding: '8px 14px', fontSize: 16, display: 'inline-block', cursor: 'pointer', borderRadius: 8, marginTop: 12}
        onClick: (e) => 

          target.roles[@local.role.name] = target.roles[@local.role.name].concat @local.added

          target.send_email_invite = @local.send_email_invite
          if @local.send_email_invite
            target.custom_email_message = $('#custom_email_message').val()              
          
          @local.added = []

          save target

        'Done'


PermissionBlock = ReactiveComponent
  displayName: 'PermissionBlock'

  render : -> 
    target = fetch @props.target
    role = @props.role

    console.log role.wildcard_label

    DIV style: {marginLeft: -4},
      
      if role.wildcard_label
        DIV null,
          INPUT 
            id: "wildcard-#{role.name}"
            name: "wildcard-#{role.name}"
            type: 'checkbox'
          LABEL htmlFor: "wildcard-#{role.name}", role.wildcard_label

      else if !target.roles[role.name] || target.roles[role.name].length == 0
        DIV style: {fontStyle: 'italic', margin: 4}, 'None'

      if target.roles[role.name]
        for user_key in target.roles[role.name]
          SPAN key: user_key, style: invited_user_style, 
            if user_key && user_key[0] == '/'
              user = fetch user_key
              SPAN null,
                if user.avatar_file_name
                  Avatar key: user_key, hide_name: true, style: {width: 20, height: 20, marginRight: 5}
                if user.name 
                  user.name 
                else 
                  user.email
            else
              user_key
            SPAN # remove role
              style: {cursor: 'pointer', marginLeft: 8}
              onClick: do (user_key, role) => =>
                target.roles[role.name] = _.without target.roles[role.name], user_key
                save target
              'x'
      


      

AdminTaskList = ReactiveComponent
  displayName: 'AdminTaskList'

  render : -> 

    dash = @data()

    # We assume an ordering of the task categories where the earlier
    # categories are more urgent & shown higher up in the list than later categories.

    if !dash.selected_task && @props.items.length > 0
      # Prefer to select a higher urgency task by default

      for [category, items] in @props.items
        if items.length > 0
          dash.selected_task = items[0].key
          console.log dash.selected_task
          save dash
          break

    # After a moderation is saved, that item will alert the dash
    # that we should move to the next moderation.
    # Need state history to handle this more elegantly
    if dash.transition
      @selectNext()

    DIV null, 
      STYLE null, '.task_tab:hover{background-color: #f1f1f1 }'

      for [category, items] in @props.items
        if items.length > 0
          DIV style: {marginTop: 20}, key: category,
            H1 style: {fontSize: 22}, category
            UL style: {},
              for item in items
                background_color = if item.key == dash.selected_task then '#F4F0E9' else ''
                LI key: item.key, style: {position: 'relative', listStyle: 'none', width: CONTENT_WIDTH / 4},

                  DIV 
                    className: 'task_tab',
                    style: {zIndex: 1, cursor: 'pointer', padding: '10px', margin: '5px 0', borderRadius: '8px 0 0 8px', backgroundColor: background_color},
                    onClick: do (item) => => 
                      dash.selected_task = item.key
                      save dash

                    @props.renderTab item

                  if dash.selected_task == item.key
                    @props.renderTask item


  # select a different task in the list relative to data.selected_task
  selectNext: -> @_select(false)
  selectPrev: -> @_select(true)
  _select: (reverse) -> 
    data = @data()
    get_next = false
    all_items = if !reverse then @props.items else @props.items.slice().reverse()

    for [category, items] in all_items
      tasks = if !reverse then items else items.slice().reverse()
      for item in tasks
        if get_next
          data.selected_task = item.key
          data.transition = null
          save data
          return
        else if item.key == data.selected_task
          get_next = true

  componentDidMount: ->
    $(document).on 'keyup.dash', (e) =>
      @selectNext() if e.keyCode == 40 # down
      @selectPrev() if e.keyCode == 38 # up
  componentWillUnmount: ->
    $(document).off 'keyup.dash'

        
ModerationDash = ReactiveComponent
  mixins: [AccessControlled]
  displayName: 'ModerationDash'

  render : -> 
    return SPAN(null) if !@accessGranted()

    moderations = @data().moderations.sort (a,b) -> new Date(b.created_at) - new Date(a.created_at)
    subdomain = fetch '/subdomain'

    # Separate moderations by status
    passed = []
    reviewable = []
    quarantined = []
    failed = []

    for i in moderations
      # register a data dependency, else resort doesn't happen when an item changes
      fetch i.key

      if !i.status? || i.updated_since_last_evaluation
        reviewable.push i
      else if i.status == 1
        passed.push i
      else if i.status == 0
        failed.push i
      else if i.status == 2
        quarantined.push i

    items = [['Pending review', reviewable], ['Quarantined', quarantined], ['Failed', failed], ['Passed', passed]]


    DIV null,
      DashHeader name: 'Moderate user contributions'

      DIV style: {width: CONTENT_WIDTH, margin: '15px auto'}, 
        DIV className: 'moderation_settings',
          if subdomain.moderated_classes.length == 0 || @local.edit_settings
            DIV null,             
              for model in ['points', 'comments', 'proposals'] #, 'proposals']
                # The order of the options is important for the database records
                moderation_options = [
                  "Do not moderate #{model}", 
                  "Do not publicly post #{model} until moderation", 
                  "Post #{model} immediately, but withhold email notifications until moderation", 
                  "Post #{model} immediately, catch bad ones afterwards"]

                FIELDSET style: {marginBottom: 12},
                  LEGEND style: {fontSize: 24},
                    capitalize model

                  for field, idx in moderation_options
                    DIV 
                      style: {marginLeft: 18, fontSize: 18, cursor: 'pointer'}
                      onClick: do (idx, model) => => 
                        subdomain["moderate_#{model}_mode"] = idx
                        save subdomain, -> 
                          #saving the subdomain shouldn't always dirty moderations (which is expensive), so just doing it manually here
                          arest.serverFetch('/page/dashboard/moderate')  

                      INPUT style: {cursor: 'pointer'}, type: 'radio', name: "moderate_#{model}_mode", id: "moderate_#{model}_mode_#{idx}", defaultChecked: subdomain["moderate_#{model}_mode"] == idx
                      LABEL style: {cursor: 'pointer', paddingLeft: 8 }, htmlFor: "moderate_#{model}_mode_#{idx}", field

              BUTTON 
                onClick: => 
                  @local.edit_settings = false
                  save @local
                'close'

          else 
            A 
              style: {textDecoration: 'underline'}
              onClick: => 
                @local.edit_settings = true
                save @local
              'Edit moderation settings'

        AdminTaskList 
          key: 'moderation_dash'
          items: items
          renderTab : (item) =>
            class_name = item.moderatable_type
            moderatable = fetch(item.moderatable)
            if class_name == 'Point'
              proposal = fetch(moderatable.proposal)
              tease = "#{moderatable.nutshell.substring(0, 30)}..."
            else if class_name == 'Comment'
              point = fetch(moderatable.point)
              proposal = fetch(point.proposal)
              tease = "#{moderatable.body.substring(0, 30)}..."
            else if class_name == 'Proposal'
              proposal = moderatable
              tease = "#{proposal.name.substring(0, 30)}..."

            DIV className: 'tab',
              DIV style: {fontSize: 14, fontWeight: 600}, "Moderate #{class_name} #{item.moderatable_id}"
              DIV style: {fontSize: 12, fontStyle: 'italic'}, tease      
              DIV style: {fontSize: 12, paddingLeft: 12}, "- #{fetch(moderatable.user).name}"
              #DIV style: {fontSize: 12}, "Issue: #{proposal.name}"
              #DIV style: {fontSize: 12}, "Added on #{new Date(moderatable.created_at).toDateString()}"
              if item.updated_since_last_evaluation
                DIV style: {fontSize: 12}, "* revised"

          renderTask: (item) => 
            ModerateItem key: item.key



# TODO: respect point.hide_name
ModerateItem = ReactiveComponent
  displayName: 'ModerateItem'

  render : ->
    item = @data()

    class_name = item.moderatable_type
    moderatable = fetch(item.moderatable)
    author = fetch(moderatable.user)
    if class_name == 'Point'
      point = moderatable
      proposal = fetch(moderatable.proposal)
    else if class_name == 'Comment'
      point = fetch(moderatable.point)
      proposal = fetch(point.proposal)
      comments = fetch("/comments/#{point.id}")
    else if class_name == 'Proposal'
      proposal = moderatable

    current_user = fetch('/current_user')
    
    DIV style: task_area_style,
      
      # status area
      DIV style: task_area_bar,
        if item.updated_since_last_evaluation
          SPAN style: {}, "Updated since last moderation"
        else if item.status == 1
          SPAN style: {}, "Passed moderation #{new Date(item.updated_at).toDateString()}"
        else if item.status == 2
          SPAN style: {}, "Sitting in quarantine"
        else if item.status == 0
          SPAN style: {}, "Failed moderation"
        else 
          SPAN style: {}, "Is this #{class_name} ok?"

        if item.user
          SPAN style: {float: 'right', fontSize: 18, verticalAlign: 'bottom'},
            "Moderated by #{fetch(item.user).name}"

      DIV style: {padding: '10px 30px'},
        # content area
        DIV style: task_area_section_style, 

          if class_name == 'Point'
            UL style: {marginLeft: 73}, 
              Point key: point, rendered_as: 'under_review'
          else if class_name == 'Proposal'
            DIV null,
              DIV null, moderatable.name
              DIV null, moderatable.description

          else if class_name == 'Comment'
            if !@local.show_conversation
              DIV null,
                A style: {textDecoration: 'underline', paddingBottom: 10, display: 'block'}, onClick: (=> @local.show_conversation = true; save(@local)),
                  'Show full conversation'
                Comment key: moderatable

            else
              DIV null,
                A style: {textDecoration: 'underline', paddingBottom: 10, display: 'block'}, onClick: (=> @local.show_conversation = false; save(@local)),
                  'Hide full conversation'

                UL style: {opacity: .5, marginLeft: 73}, 
                  Point key: point, rendered_as: 'under_review'
                for comment in _.uniq( _.map(comments.comments, (c) -> c.key).concat(moderatable.key))

                  if comment != moderatable.key
                    DIV style: {opacity: .5},
                      Comment key: comment
                  else 
                    Comment key: moderatable



          DIV style:{fontSize: 12, marginLeft: 73}, 
            "by #{author.name}"

            if (item.status != 0 && item.status != 2 && class_name != 'Proposal') || class_name == 'Comment'
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              A 
                target: '_blank'
                href: "/#{proposal.slug}/?selected=#{point.key}"
                style: {textDecoration: 'underline'}
                'Read in context']

            if !moderatable.hide_name && !@local.messaging
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              A
                style: {textDecoration: 'underline'}
                onClick: (=> @local.messaging = moderatable; save(@local)),
                'Message author']
            else if @local.messaging
              DirectMessage to: @local.messaging.user, parent: @local



        # moderation area
        DIV style: task_area_section_style, 
          STYLE null, 
            """
            .moderation { padding: 6px 8px; display: inline-block; }
            .moderation:hover { background-color: rgba(255,255,255, .5); cursor: pointer; border-radius: 8px; }                         
            .moderation label, .moderation input { font-size: 24px; }
            .moderation label:hover, .moderation input:hover { font-size: 24px; cursor: pointer; }
            """

          DIV 
            className: 'moderation',
            onClick: ->
              # this has to happen first otherwise the dash won't 
              # know what the next item is when it transitions
              dash = fetch 'moderation_dash'
              dash.transition = item.key #need state transitions 
              save dash

              item.status = 1
              save item

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'pass'
              defaultChecked: item.status == 1

            LABEL htmlFor: 'pass', 'Pass'
          DIV 
            className: 'moderation',
            onClick: ->
              # this has to happen first otherwise the dash won't 
              # know what the next item is when it transitions
              dash = fetch 'moderation_dash'
              dash.transition = item.key #need state transitions 
              save dash

              item.status = 2
              save item

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'quar'
              defaultChecked: item.status == 2
            LABEL htmlFor: 'quar', 'Quarantine'
          DIV 
            className: 'moderation',
            onClick: ->
              # this has to happen first otherwise the dash won't 
              # know what the next item is when it transitions
              dash = fetch 'moderation_dash'
              dash.transition = item.key #need state transitions 
              save dash

              item.status = 0
              save item

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'fail'
              defaultChecked: item.status == 0

            LABEL htmlFor: 'fail', 'Fail'


FactcheckDash = ReactiveComponent
  displayName: 'FactcheckDash'
  mixins: [AccessControlled]

  render : ->
    return SPAN(null) if !@accessGranted()


    assessments = @data().assessments.sort (a,b) -> new Date(b.created_at) - new Date(a.created_at)

    # Separate assessments by status
    completed = []
    reviewable = []
    todo = []
    for a in assessments
      # register a data dependency, else resort doesn't happen when an item changes
      fetch a.key

      if a.complete 
        completed.push a
      else if a.reviewable
        reviewable.push a
      else
        todo.push a

    items = [['Pending review', reviewable], ['Incomplete', todo], ['Complete', completed]]

    DIV null,
      DashHeader name: 'Fact check user contributions'

      DIV style: {width: CONTENT_WIDTH, margin: '15px auto'}, 
        AdminTaskList 
          items: items
          key: 'factcheck_dash'

          renderTab : (item) =>
            point = fetch(item.point)
            proposal = fetch(point.proposal)

            DIV className: 'tab',
              DIV style: {fontSize: 14, fontWeight: 600}, "Fact check point #{point.id}"
              DIV style: {fontSize: 12}, "Requested on #{new Date(item.requests[0].created_at).toDateString()}"
              DIV style: {fontSize: 12}, "Issue: #{proposal.name}"
          
          renderTask : (item) => 
            FactcheckPoint key: item.key


FactcheckPoint = ReactiveComponent
  displayName: 'FactcheckPoint'

  render : ->
    assessment = @data()
    point = fetch(assessment.point)
    proposal = fetch(point.proposal)
    current_user = fetch('/current_user')

    all_claims_answered = assessment.claims.length > 0
    all_claims_approved = assessment.claims.length > 0
    for claim in assessment.claims
      if !claim.verdict || !claim.result
        all_claims_answered = all_claims_approved = false 
      if !claim.approver
        all_claims_approved = false

    DIV style: task_area_style,
      STYLE null, '.claim_result a{text-decoration: underline;}'
      
      # status area
      DIV style: task_area_bar,
        if assessment.complete
          SPAN style: {}, "Published #{new Date(assessment.published_at).toDateString()}"
        else if assessment.reviewable
          SPAN style: {}, "Awaiting approval"
        else
          SPAN style: {}, "Fact check this point"

        SPAN style: {float: 'right', fontSize: 18, verticalAlign: 'bottom'},
          if assessment.user 
            ["Responsible: #{fetch(assessment.user).name}"
            if assessment.user == current_user.user && !assessment.reviewable && !assessment.complete
              BUTTON style: {marginLeft: 8, fontSize: 14}, onClick: @toggleResponsibility, "I won't do it"]
          else 
            ['Responsible: '
            BUTTON style: {backgroundColor: considerit_blue, color: 'white', fontSize: 14, border: 'none', borderRadius: 8, fontWeight: 600 }, onClick: @toggleResponsibility, "I'll do it"]

      DIV style: {padding: '10px 30px'},
        # point area
        DIV style: task_area_section_style, 
          UL style: {marginLeft: 73}, 
            Point key: point, rendered_as: 'under_review'

          DIV style:{fontSize: 12, marginLeft: 73}, 
            "by #{fetch(point.user).name}"
            SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
            A 
              target: '_blank'
              href: "/#{proposal.slug}/?selected=#{point.key}"
              style: {textDecoration: 'underline'}
              'Read point in context'

            if !point.hide_name && @local.messaging != point
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              A
                style: {textDecoration: 'underline'}
                onClick: (=> @local.messaging = point; save(@local)),
                'Message author']
            else if @local.messaging == point
              DirectMessage to: @local.messaging.user, parent: @local


        # requests area
        DIV style: task_area_section_style, 
          H1 style: task_area_header_style, 'Fact check requests'
          DIV style: {}, 
            for request in assessment.requests
              DIV className: 'comment_entry', key: request.key,

                Avatar
                  className: 'comment_entry_avatar'
                  tag: DIV
                  key: request.user
                  hide_name: true

                DIV style: {marginLeft: 73},
                  splitParagraphs(request.suggestion)

                DIV style:{fontSize: 12, marginLeft: 73}, 
                  "by #{fetch(request.user).name}"
                  if @local.messaging != request
                    [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
                    A
                      style: {textDecoration: 'underline'}
                      onClick: (=> @local.messaging = request; save(@local)),
                      'Message requester']
                  else if @local.messaging == request
                    DirectMessage to: @local.messaging.user, parent: @local

        # claims area
        DIV style: task_area_section_style, 
          H1 style: task_area_header_style, 'Claims under review'


          DIV style: {}, 
            for claim in assessment.claims
              claim = fetch(claim)
              if @local.editing == claim.key
                EditClaim fresh: false, key: claim.key, parent: @local, assessment: @data()
              else 

                verdict = fetch(claim.verdict)
                DIV key: claim.key, style: {marginLeft: 73, marginBottom: 18, position: 'relative'}, 
                  IMG style: {position: 'absolute', width: 50, left: -73}, src: verdict.icon

                  DIV style: {fontSize: 18}, claim.claim_restatement
                  DIV style: {fontSize: 12}, verdict.name
                  
                  DIV 
                    className: 'claim_result'
                    style: {marginTop: 10, fontSize: 14}
                    dangerouslySetInnerHTML: {__html: claim.result }
                  
                  DIV style: {marginTop: 10, position: 'relative'},

                    DIV style: {fontSize: 12, marginTop: 10}, 
                      DIV null, "Created by #{fetch(claim.creator).name}"
                      if claim.approver
                        DIV null, "Approved by #{fetch(claim.approver).name}"

                    DIV style: {fontSize: 14},
                      if claim.result && claim.verdict && !claim.approver #&& current_user.id != claim.creator
                        BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @toggleClaimApproval(claim)), 'Approve'
                      else if claim.approver
                        BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @toggleClaimApproval(claim)), 'Unapprove'

                      BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @local.editing = claim.key; save(@local)), 'Edit'
                      BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @deleteClaim(claim)), 'Delete'

            if @local.editing == 'new'
              EditClaim fresh: true, key: '/new/claim', parent: @local, assessment: @data()
            else if !@local.editing
              Button {style: {marginLeft: 73, marginTop: 15}}, '+ Add new claim', => @local.editing = 'new'; save(@local)

        DIV style: task_area_section_style,
          H1 style: task_area_header_style, 'Private notes'
          AutoGrowTextArea
            className: 'assessment_notes'
            placeholder: 'Private notes about this fact check'
            defaultValue: assessment.notes
            min_height: 60
            style: 
              width: 550
              fontSize: 14
              display: 'block'

          BUTTON style: {fontSize: 14}, onClick: @saveNotes, 'Save notes'

          DIV style: task_area_header_style,
            if assessment.complete
              'Congrats, this one is finished.'
            else if all_claims_answered && !assessment.reviewable
              Button({}, 'Request approval', @requestApproval)
            else if assessment.reviewable
              if all_claims_approved && current_user.user != assessment.user
                Button({}, 'Publish fact check', @publish)
              else if all_claims_answered
                'This fact-check is awaiting publication'



  deleteClaim : (claim) -> destroy claim.key

  toggleClaimApproval : (claim) -> 
    if claim.approver
      claim.approver = null
    else
      claim.approver = fetch('/current_user').user
    save(claim)

  saveNotes: -> 
    assessment = @data()
    assessment.notes = $('.assessment_notes').val()
    save(assessment)

  publish : -> 
    assessment = @data()
    assessment.complete = true
    save(assessment)

  requestApproval : -> 
    assessment = @data()
    assessment.reviewable = true
    if !assessment.user
      assessment.user = fetch("/current_user").user
    save(assessment)

  toggleResponsibility : ->
    assessment = @data()
    current_user = fetch('/current_user')

    if assessment.user == current_user.user
      assessment.user = null
    else if !assessment.user
      assessment.user = current_user.user

    save assessment

DirectMessage = ReactiveComponent
  displayName: 'DirectMessage'

  render : -> 
    text_style = 
      width: 500
      fontSize: 14
      display: 'block'

    DIV style: {marginTop: 18, padding: '15px 20px', backgroundColor: 'white', width: 550, border: '#999', boxShadow: "0 1px 2px rgba(0,0,0,.2)"}, 
      DIV style: {marginBottom: 8},
        LABEL null, 'To: ', fetch(@props.to).name

      DIV style: {marginBottom: 8},
        LABEL null, 'Subject'
        AutoGrowTextArea
          className: 'message_subject'
          placeholder: 'Subject line'
          min_height: 25
          style: text_style

      DIV style: {marginBottom: 8},
        LABEL null, 'Body'
        AutoGrowTextArea
          className: 'message_body'
          placeholder: 'Email message'
          min_height: 75
          style: text_style

      Button {}, 'Send', @submitMessage
      A style: {marginLeft: 8}, onClick: (=> @props.parent.messaging = null; save @props.parent), 'cancel'

  submitMessage : -> 
    # TODO: convert to using arest create method; waiting on full dash porting
    $el = $(@getDOMNode())
    attrs = 
      recipient: @props.to
      subject: $el.find('.message_subject').val()
      body: $el.find('.message_body').val()
      sender: 'factchecker'

    $.ajax '/dashboard/message', data: attrs, type: 'POST', success: => 
      @props.parent.messaging = null
      save @props.parent

EditClaim = ReactiveComponent
  displayName: 'EditClaim'

  render : -> 
    text_style = 
      width: 550
      fontSize: 14
      display: 'block'

    DIV style: {padding: '8px 12px', backgroundColor: "rgba(0,0,0,.1)", marginLeft: 73, marginBottom: 18 },
      DIV style: {marginBottom: 8},
        LABEL null, 'Restate the claim'
        AutoGrowTextArea
          className: 'claim_restatement'
          placeholder: 'The claim'
          defaultValue: if @props.fresh then null else @data().claim_restatement
          min_height: 30
          style: text_style

      DIV style: {marginBottom: 8},
        LABEL style: {marginRight: 8}, 'Evaluate the claim'
        SELECT
          defaultValue: if @props.fresh then null else @data().verdict
          className: 'claim_verdict'
          for verdict in fetch('/page/dashboard/assessment').verdicts
            OPTION key: verdict.key, value: verdict.key, verdict.name


      DIV style: {marginBottom: 8},
        LABEL null, 'Review the claim'
        AutoGrowTextArea
          className: 'claim_result'
          placeholder: 'Prose review of this claim'
          defaultValue: if @props.fresh then null else @data().result
          min_height: 80
          style: text_style

      Button {}, 'Save claim', @saveClaim
      A style: {marginLeft: 12}, onClick: (=> @props.parent.editing = null; save(@props.parent)), 'cancel'



  saveClaim : -> 
    $el = $(@getDOMNode())

    claim = if @props.fresh then {key: '/new/claim'} else @data()

    claim.claim_restatement = $el.find('.claim_restatement').val()
    claim.result = $el.find('.claim_result').val()
    claim.assessment = @props.assessment.key
    claim.verdict = $el.find('.claim_verdict').val()

    save(claim)

    # This is ugly, what is activeRESTy way of doing this? 
    @props.parent.editing = null
    save @props.parent


# Creates a new subdomain / subdomain. This is meant to only be accessed from 
# the considerit homepage, but will work from any subdomain.
CreateSubdomain = ReactiveComponent
  displayName: 'CreateSubdomain'
  mixins: [AccessControlled]

  render : -> 
    return SPAN(null) if !@accessGranted()

    current_user = fetch('/current_user')

    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 
      DashHeader name: 'Create new subdomain (secret, you so special!!!)'

      DIV style: {marginTop: 20},
        LABEL htmlFor: 'subdomain', 
          'Name of the new subdomain'
        INPUT id: 'subdomain', name: 'subdomain', type: 'text', style: {fontSize: 28, padding: '8px 12px', width: CONTENT_WIDTH}, placeholder: 'Don\'t be silly with weird characters'

        DIV style: {fontSize: 14}, 
          "You will be redirected to the new subdomain where you can configure the application. You will automatically be added as an administrator."

        BUTTON 
          className: 'button primary_button' 
          onClick: => 
            $.ajax '/subdomain', 
              data: 
                subdomain: $(@getDOMNode()).find('#subdomain').val()
                authenticity_token: current_user.csrf
              type: 'POST'
              success: (data) => 
                if data[0].errors
                  @local.errors = data[0].errors
                else
                  @local.successful = data[0].name
                save @local
          'Create'

        if @local.errors && @local.errors.length > 0
          DIV style: {borderRadius: 8, margin: 20, padding: 20, backgroundColor: '#FFE2E2'}, 
            H1 style: {fontSize: 18}, 'Ooops! There were errors:'
            for error in @local.errors
              DIV style: {marginTop: 10}, error

        if @local.successful
          DIV style: {borderRadius: 8, margin: 20, padding: 20, backgroundColor: '#E2FFE2', fontSize: 20}, 
            "Success! "
            A style: {textDecoration: 'underline'}, href: "#{location.protocol}//#{@local.successful}.#{location.hostname}/dashboard/application", "Configure your shiny new subdomain"



## Export...
window.FactcheckDash = FactcheckDash
window.ModerationDash = ModerationDash
window.AppSettingsDash = AppSettingsDash
window.RolesDash = RolesDash
window.ProposalShare = ProposalShare
window.ImportDataDash = ImportDataDash
window.CreateSubdomain = CreateSubdomain
window.DashHeader = DashHeader