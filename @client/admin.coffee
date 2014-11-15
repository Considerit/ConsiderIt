# Admin components, like moderation and factchecking backend

# Experimenting with sharing css styles between components via js objects
task_area_header_style = {fontSize: 24, fontWeight: 400, margin: '10px 0'}
task_area_bar = {padding: '4px 30px', fontSize: 24, borderRadius: '8px 8px 0 0', height: 35, backgroundColor: 'rgba(0,0,55,.1)'}
task_area_section_style = {margin: '10px 0px 20px 0px', position: 'relative'}
task_area_style = {cursor: 'auto', width: 3 * CONTENT_WIDTH / 4, backgroundColor: '#F4F0E9', position: 'absolute', left: CONTENT_WIDTH/4, top: -35, borderRadius: 8}



# Checks if current user has proper credentials to view this component. 
# If not, shows Auth. 
AccessControlled = ReactiveComponent
  displayName: 'AccessControlled'

  render : -> 
    current_user = fetch '/current_user'

    is_permitted = false
    for role in @props.permitted
      if (role == 'user' && current_user.logged_in) ||  current_user["is_#{role}"]
        is_permitted = true
        break

    if is_permitted
      @props.children
    else if current_user.logged_in
      window.app_router.navigate("/", {trigger: true})
      SPAN null
    else
      @root.auth_mode = 'login'
      save @root
      SPAN null

DashHeader = (name) ->
  DIV style: {position: 'relative'},
    A
      className: 'homepage_link'
      onClick: (=> window.app_router.navigate("/", {trigger: true}))
      style: {position: 'absolute', display: 'inline-block', top: 5, left: -40},
      I className: 'fa fa-home', style: {fontSize: 28, color: 'black'}
    
    H1 style: {fontSize: 28, margin: '20px 0'}, name   

ImportDataDash = ReactiveComponent
  displayName: 'ImportDataDash'

  render : ->
    customer = fetch '/customer'
    current_user = fetch '/current_user'

    if customer.identifier == 'livingvotersguide'
      tables = ['Measures', 'Candidates', 'Jurisdictions']
    else 
      tables = ['Users', 'Proposals', 'Opinions', 'Points', 'Comments']

    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 
      STYLE null, 
        """
        """

      DashHeader 'Import Data'
      P style: {fontWeight: 300, marginBottom: 6}, 
        "Import data into Considerit. The spreadsheet should be in comma separated value format (.csv)."

      if customer.identifier != 'livingvotersguide'

        DIV null,
          P style: {fontWeight: 300, marginBottom: 6}, 
            "To refer to a User, use their email address. For example, if you’re uploading points, in the user column, refer to the author via their email address. "
          P style: {fontWeight: 300, marginBottom: 6}, 
            "To refer to a Proposal, refer to its url. "
          P style: {fontWeight: 300, marginBottom: 6}, 
            "To refer to a Point, make up an id for it and use that."
          P style: {fontWeight: 300, marginBottom: 6}, 
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

  render : -> 
    customer = @data()

    DIV className: 'app_settings_dash',
      STYLE null, 
        """
        .app_settings_dash { font-size: 18px; width: #{CONTENT_WIDTH}px; margin: 20px auto; }
        .app_settings_dash label { display: block; }
        .app_settings_dash input { display: block; width: 600px; font-size: 18px; padding: 4px 8px; } 
        .app_settings_dash .input_group { margin-bottom: 12px; }
        """

      DashHeader 'Application Settings'


      if customer.identifier
        DIV null, 
          DIV className: 'input_group',
            LABEL htmlFor: 'about_page_url', 'About Page URL'
            INPUT 
              id: 'about_page_url'
              type: 'text'
              name: 'about_page_url'
              defaultValue: customer.about_page_url
              placeholder: 'The about page will then contain a window to this url.'

          DIV className: 'input_group',
            LABEL htmlFor: 'contact_email', 'Contact email'
            INPUT 
              id: 'contact_email'
              type: 'text'
              name: 'contact_email'
              defaultValue: customer.contact_email
              placeholder: 'Sender email address for notification emails. Default is admin@consider.it.'

          DIV className: 'input_group',
            LABEL htmlFor: 'app_title', 'The name of this application'
            INPUT 
              id: 'app_title'
              type: 'text'
              name: 'app_title'
              defaultValue: customer.app_title
              placeholder: 'Shows in email subject lines and in the window title.'

          DIV className: 'input_group',
            LABEL htmlFor: 'project_url', 'Project url'
            INPUT 
              id: 'project_url'
              type: 'text'
              name: 'project_url'
              defaultValue: customer.project_url
              placeholder: 'A link to the main project\'s homepage, if any.'

          DIV className: 'input_group',
            BUTTON className: 'button', onClick: @submit, 'Save'

  submit : -> 
    customer = @data()

    fields = ['about_page_url', 'contact_email', 'app_title', 'project_url']

    for f in fields
      customer[f] = $(@getDOMNode()).find("##{f}").val()

    save customer


RolesDash = ReactiveComponent
  displayName: 'RolesDash'

  render : -> 
    customer = @data()

    roles = [ 
      ['admin', 'Admins can access everything.'], 
      ['moderator', 'Moderators can review user content; they get email notifications when content needs review.']
    ]

    if customer.assessment_enabled
      roles.push ['evaluator', 'Evaluators review factual claims in pro/con points.']


    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 

      DashHeader 'User Roles'

      for role in roles
        DIV style: {marginTop: 12},
          H1 style: {fontSize: 18}, capitalize(role[0])
          SPAN style: {fontSize: 14}, role[1]

          PermissionBlock key: role[0]


PermissionBlock = ReactiveComponent
  displayName: 'PermissionBlock'

  render : -> 
    customer = fetch '/customer'
    users = fetch '/users'
    role = @props.key

    DIV null,
      if customer.roles[role]
        for user_key in customer.roles[role]
          user = fetch user_key
          SPAN style: {display: 'inline-block', padding: '4px 8px', fontWeight: 400, fontSize: 15, backgroundColor: '#e1e1e1', color: 'black', borderRadius: 16, margin: '4px'}, 
            if user.name then user.name else user.email
            I style: {cursor: 'pointer', marginLeft: 8}, className: 'fa fa-close', onClick: do (user_key, role) => =>
              # remove role
              customer.roles[role] = _.without customer.roles[role], user_key
              save customer
      
      DIV style: {position: 'relative'}, 
        INPUT 
          id: 'filter'
          type: 'text'
          style: {fontSize: 18, width: 500}
          autocomplete: 'off'
          placeholder: "Add #{role}"
          onChange: (=> @local.filtered = $(@getDOMNode()).find('#filter').val(); save(@local);)
          onFocus: (e) => 
            @local.add = true
            save(@local)
            e.stopPropagation()
            $(document).on 'click.roles', (e) =>
              if e.target.id != 'filter'
                @local.add = false
                @local.filtered = null
                $(@getDOMNode()).find('#filter').val('')
                save(@local)
                $(document).off('click.roles')
            return false

        if @local.add
          UL style: {width: 500, position: 'absolute', zIndex: 99, listStyle: 'none', backgroundColor: '#fff', border: '1px solid #eee'},
            for user in _.filter(users.users, (u) => customer.roles[role].indexOf(u.key) < 0 && (!@local.filtered || "#{u.name} <#{u.email}>".indexOf(@local.filtered) > -1) )
              LI 
                style: {padding: '2px 12px', fontSize: 18, cursor: 'pointer', borderBottom: '1px solid #fafafa'}
                onClick: do(user) => (e) => 
                  # add role
                  customer.roles[role].push user.key
                  save customer
                  e.stopPropagation()

                "#{user.name} <#{user.email}>"



AdminTaskList = ReactiveComponent
  displayName: 'AdminTaskList'

  render : -> 

    dash = @data()

    # We assume an ordering of the task categories that where the earlier
    # categories are more urgent & shown higher up in the list than later categories.
    if !dash.selected_task && @props.items.length > 0
      # Prefer to select a higher urgency task by default

      for [category, items] in @props.items
        if items.length > 0
          dash.selected_task = items[0].key
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

        
ModerationDash = ReactiveComponent
  displayName: 'ModerationDash'

  render : -> 
    moderations = @data().moderations.sort (a,b) -> new Date(b.created_at) - new Date(a.created_at)
    customer = fetch '/customer'

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


    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 
      DashHeader 'Moderation Interface'

      DIV className: 'moderation_settings',
        if customer.moderated_classes.length == 0 || @local.edit_settings
          DIV null,             
            for model in ['points', 'comments'] #, 'proposals']
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
                      customer["moderate_#{model}_mode"] = idx
                      save customer

                      #saving the customer shouldn't always dirty moderations (which is expensive), so just doing it manually here
                      arest.serverFetch('/dashboard/moderate')  

                    INPUT style: {cursor: 'pointer'}, type: 'radio', name: "moderate_#{model}_mode", id: "moderate_#{model}_mode_#{idx}", defaultChecked: customer["moderate_#{model}_mode"] == idx
                    LABEL style: {cursor: 'pointer', paddingLeft: 8 }, htmlFor: "moderate_#{model}_mode_#{idx}", field

            BUTTON 
              onClick: => 
                @local.edit_settings = false
                save @local
              'Done'

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
          moderatable = @data(item.moderatable)
          if class_name == 'Point'
            proposal = @data(moderatable.proposal)
            tease = "#{moderatable.nutshell.substring(0, 30)}..."
          else if class_name == 'Comment'
            point = @data(moderatable.point)
            proposal = @data(point.proposal)
            tease = "#{moderatable.body.substring(0, 30)}..."

          DIV className: 'tab',
            DIV style: {fontSize: 14, fontWeight: 600}, "Moderate #{class_name} #{item.moderatable_id}"
            DIV style: {fontSize: 12, fontStyle: 'italic'}, tease      
            DIV style: {fontSize: 12, paddingLeft: 12}, "- #{@data(moderatable.user).name}"
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
      proposal = @data(moderatable.proposal)
    else if class_name == 'Comment'
      point = @data(moderatable.point)
      proposal = @data(point.proposal)
      comments = @data("/comments/#{point.id}")

    current_user = @data('/current_user')
    
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
          SPAN style: {}, "Is this #{item.moderatable_type} ok?"

        if item.user
          SPAN style: {float: 'right', fontSize: 18, verticalAlign: 'bottom'},
            "Moderated by #{@data(item.user).name}"

      DIV style: {padding: '10px 30px'},
        # content area
        DIV style: task_area_section_style, 

          if item.moderatable_type == 'Point'
            UL style: {marginLeft: 73}, 
              Point key: point, rendered_as: 'under_review'
          else if item.moderatable_type == 'Comment'
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

            if (item.status != 0 && item.status != 2) || item.moderatable_type == 'Comment'
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              A 
                target: '_blank'
                href: "/#{proposal.long_id}/?selected=#{point.key}"
                style: {textDecoration: 'underline'}
                'Read in context']

            if !moderatable.hide_name && !@local.messaging
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              A
                style: {textDecoration: 'underline'}
                onClick: (=> @local.messaging = moderatable; save(@local)),
                'Message author']
            else if @local.messaging
              EmailMessage to: @local.messaging.user, parent: @local



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

  render : ->
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

    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 
      DashHeader 'Fact Checking Interface'

      AdminTaskList 
        items: items
        key: 'factcheck_dash'

        renderTab : (item) =>
          point = @data(item.point)
          proposal = @data(point.proposal)

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
    point = @data(assessment.point)
    proposal = @data(point.proposal)
    current_user = @data('/current_user')

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
            ["Responsible: #{@data(assessment.user).name}"
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
              href: "/#{proposal.long_id}/?selected=#{point.key}"
              style: {textDecoration: 'underline'}
              'Read point in context'

            if !point.hide_name && @local.messaging != point
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              A
                style: {textDecoration: 'underline'}
                onClick: (=> @local.messaging = point; save(@local)),
                'Message author']
            else if @local.messaging == point
              EmailMessage to: @local.messaging.user, parent: @local


        # requests area
        DIV style: task_area_section_style, 
          H1 style: task_area_header_style, 'Fact check requests'
          DIV style: {}, 
            for request in assessment.requests
              DIV className: 'comment_entry',

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
                    EmailMessage to: @local.messaging.user, parent: @local

        # claims area
        DIV style: task_area_section_style, 
          H1 style: task_area_header_style, 'Claims under review'


          DIV style: {}, 
            for claim in assessment.claims
              claim = @data(claim)
              if @local.editing == claim.key
                EditClaim fresh: false, key: claim.key, parent: @local, assessment: @data()
              else 

                verdict = @data(claim.verdict)
                DIV style: {marginLeft: 73, marginBottom: 18, position: 'relative'}, 
                  IMG style: {position: 'absolute', width: 50, left: -73}, src: verdict.icon

                  DIV style: {fontSize: 18}, claim.claim_restatement
                  DIV style: {fontSize: 12}, verdict.name
                  
                  DIV 
                    className: 'claim_result'
                    style: {marginTop: 10, fontSize: 14}
                    dangerouslySetInnerHTML: {__html: claim.result }
                  
                  DIV style: {marginTop: 10, position: 'relative'},

                    DIV style: {fontSize: 12, marginTop: 10}, 
                      DIV null, "Created by #{@data(claim.creator).name}"
                      if claim.approver
                        DIV null, "Approved by #{@data(claim.approver).name}"

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
      claim.approver = @data('/current_user').user
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
      assessment.user = @data("/current_user").user
    save(assessment)

  toggleResponsibility : ->
    assessment = @data()
    current_user = @data('/current_user')

    if assessment.user == current_user.user
      assessment.user = null
    else if !assessment.user
      assessment.user = current_user.user

    save assessment

EmailMessage = ReactiveComponent
  displayName: 'EmailMessage'

  render : -> 
    text_style = 
      width: 500
      fontSize: 14
      display: 'block'

    DIV style: {marginTop: 18, padding: '15px 20px', backgroundColor: 'white', width: 550, border: '#999', boxShadow: "0 1px 2px rgba(0,0,0,.2)"}, 
      DIV style: {marginBottom: 8},
        LABEL null, 'To: ', @data(@props.to).name

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
          for verdict in @data('/dashboard/assessment').verdicts
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


# Creates a new customer / subdomain. This is meant to only be accessed from 
# the considerit homepage, but will work from any subdomain.
CreateSubdomain = ReactiveComponent
  displayName: 'CreateSubdomain'

  render : -> 
    current_user = fetch('/current_user')

    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 
      DashHeader 'Create new subdomain (secret, you so special!!!)'

      DIV style: {marginTop: 20},
        LABEL htmlFor: 'subdomain', 
          'Name of the new subdomain'
        INPUT id: 'subdomain', name: 'subdomain', type: 'text', style: {fontSize: 28, padding: '8px 12px', width: CONTENT_WIDTH}, placeholder: 'Don\'t be silly with weird characters'

        DIV style: {fontSize: 14}, 
          "You will be redirected to the new subdomain where you can configure the application. You will automatically be added as an administrator."

        BUTTON 
          className: 'button primary_button' 
          onClick: => 
            $.ajax '/customer', 
              data: 
                subdomain: $(@getDOMNode()).find('#subdomain').val()
                authenticity_token: current_user.csrf
              type: 'POST'
              success: (data) => 
                if data[0].errors
                  @local.errors = data[0].errors
                else
                  @local.successful = data[0].identifier
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
window.ImportDataDash = ImportDataDash
window.AccessControlled = AccessControlled
window.CreateSubdomain = CreateSubdomain
window.DashHeader = DashHeader