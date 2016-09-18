# Admin components, like moderation and factchecking backend


require './vendor/jquery.form'
require './form'
require './shared'


adminStyles = -> 
  {
    task_area_header_style:
      fontSize: 24
      fontWeight: 400
      margin: '10px 0'
    task_area_bar: 
      padding: '4px 30px'
      fontSize: 24
      borderRadius: '8px 8px 0 0'
      height: 35
      backgroundColor: 'rgba(0,0,55,.1)'
    task_area_section_style: 
      margin: '10px 0px 20px 0px'
      position: 'relative'
    task_area_style: 
      cursor: 'auto'
      width: CONTENT_WIDTH() * .75
      minWidth: 700
      backgroundColor: '#F4F0E9'
      position: 'absolute'
      left: CONTENT_WIDTH()/4
      top: -35
      borderRadius: 8
  }

DashHeader = ReactiveComponent
  displayName: 'DashHeader'

  render : ->    

    doc = fetch('document')
    if doc.title != @props.name
      doc.title = @props.name
      save doc

    subdomain = fetch '/subdomain'
    DIV 
      style: 
        position: 'relative'

      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: 'auto'
          position: 'relative'    
        H1 
          style: 
            fontSize: 28
            padding: '20px 0'
            fontWeight: 400
          @props.name   

ImportDataDash = ReactiveComponent
  displayName: 'ImportDataDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    if subdomain.name == 'livingvotersguide'
      tables = ['Measures', 'Candidates', 'Jurisdictions']
    else 
      tables = ['Users', 'Proposals', 'Opinions', 'Points', 'Comments']

    DIV null, 

      
      DashHeader name: 'Export Data'

      DIV style: {width: HOMEPAGE_WIDTH(), margin: '15px auto'},

      if subdomain.plan || current_user.is_super_admin
        DIV null, 
          "Export data from Considerit. A download will begin in a couple seconds after hitting export. The zip file contains four spreadsheets: opinions, points, proposals, and users."
          DIV style: marginTop: 20, display: 'block'
          BUTTON 
            style: {backgroundColor: '#7ED321', color: 'white', border: 'none', borderRadius: 8, fontSize: 24, fontWeight: 700, padding: '10px 20px'}
            href: "/dashboard/export"
            "data-nojax": true

            'Export'
      else 
        DIV style: {fontStyle: 'italic'},
          "Data export is only available for paid plans. Contact "
          A 
            href: 'mailto:hello@consider.it'
            style: 
              textDecoration: 'underline'
            'hello@consider.it'
          ' to inquire about a paid plan.'


      DashHeader name: 'Import Data'

      DIV style: {width: HOMEPAGE_WIDTH(), margin: '15px auto'},
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
                  DIV null
                    A 
                      style: 
                        textDecoration: 'underline'
                        fontSize: 12
                      href: "/example_import_csvs/#{table.toLowerCase()}.csv"
                      'data-nojax': true
                      'Example'

                TD style: {padding: '20px 0 0 20px'}, 
                  INPUT 
                    id: "#{table}-file"
                    name: "#{table.toLowerCase()}-file"
                    type:'file'
                    style: {backgroundColor: focus_blue, color: 'white', fontWeight: 700, borderRadius: 8, padding: 6}
            

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
                BUTTON
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

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    DIV className: 'app_settings_dash',

      STYLE dangerouslySetInnerHTML: __html: #dangerously set html is so that the type="text" doesn't get escaped
        """
        .app_settings_dash { font-size: 18px }
        .app_settings_dash input[type="text"], .app_settings_dash textarea { border: 1px solid #aaa; outline: none; display: block; width: #{HOMEPAGE_WIDTH()}px; font-size: 18px; padding: 4px 8px; } 
        .app_settings_dash .input_group { margin-bottom: 12px; }
        """

      DashHeader name: 'Application Settings'

      if subdomain.name
        DIV style: {width: HOMEPAGE_WIDTH(), margin: '20px auto'}, 

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
            LABEL htmlFor: 'lang', 'Interface Language'
            SELECT 
              id: 'lang'
              type: 'text'
              name: 'lang'
              defaultValue: subdomain.lang
              style: 
                fontSize: 18
                marginLeft: 12
                display: 'inline-block'

              OPTION
                value: 'en'
                'English'

              OPTION
                value: 'es'
                'Spanish'

              OPTION
                value: 'fr'
                'French'

              OPTION
                value: 'pt'
                'Portuguese'

              OPTION
                value: 'aeb'
                'Tunisian arabic'

            DIV 
              style: 
                fontStyle: 'italic'
                fontSize: 12
              "Your language not available? Email us at hello@consider.it to help us create a translation."




          if subdomain.plan || current_user.is_super_admin
            DIV className: 'input_group',
              
              LABEL htmlFor: 'google_analytics_code', "Google analytics. Add your Google analytics tracking code."
              INPUT 
                id: 'google_analytics_code'
                type: 'text'
                name: 'google_analytics_code'
                defaultValue: subdomain.google_analytics_code
                placeholder: 'Google Analytics tracking code'
          else 
            DIV className: 'input_group',
              LABEL htmlFor: 'google_analytics_code', "Google analytics tracking code"
              DIV style: {fontStyle: 'italic', fontSize: 15},
                "Only available for paid plans. Email "
                A 
                  href: 'mailto:hello@consider.it'
                  style: 
                    textDecoration: 'underline'
                  'hello@consider.it'
                ' to inquire further.'



          # DIV className: 'input_group',
          #   LABEL htmlFor: 'notifications_sender_email', 'Contact email'
          #   INPUT 
          #     id: 'notifications_sender_email'
          #     type: 'text'
          #     name: 'notifications_sender_email'
          #     defaultValue: subdomain.notifications_sender_email
          #     placeholder: 'Sender email address for notification emails. Default is admin@consider.it.'


          if current_user.is_super_admin



            # DIV className: 'input_group',
            #   LABEL htmlFor: 'about_page_url', 'About Page URL'
            #   INPUT 
            #     id: 'about_page_url'
            #     type: 'text'
            #     name: 'about_page_url'
            #     defaultValue: subdomain.about_page_url
            #     placeholder: 'The about page will then contain a window to this url.'


            DIV null,

              DIV className: 'input_group',
                LABEL htmlFor: 'plan', 'Account Plan (0,1,2)'
                INPUT 
                  id: 'plan'
                  type: 'text'
                  name: 'plan'
                  defaultValue: subdomain.plan
                  placeholder: '0 for free plan, 1 for custom, 2 for consulting.'

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

              # DIV className: 'input_group',
              #   LABEL htmlFor: 'homepage_text', 'Homepage text'
              #   TEXTAREA 
              #     id: 'homepage_text'
              #     name: 'homepage_text'
              #     defaultValue: subdomain.branding.homepage_text
              #     placeholder: 'Shown in homepage. Can be HTML.'
              #     style: 
              #       display: 'block'
              #       width: HOMEPAGE_WIDTH()


          FORM id: 'subdomain_files', action: '/update_images_hack',
            if current_user.is_super_admin
              DIV className: 'input_group',
                DIV null, LABEL htmlFor: 'masthead', 'Masthead background image. Should be pretty large.'
                INPUT 
                  id: 'masthead'
                  type: 'file'
                  name: 'masthead'
                  onChange: (ev) =>
                    @submit_masthead = true

            DIV className: 'input_group',
              DIV null, LABEL htmlFor: 'logo', 'Logo'
              INPUT 
                id: 'logo'
                type: 'file'
                name: 'logo'
                onChange: (ev) =>
                  @submit_logo = true


          DIV 
            className: 'input_group'
            BUTTON 
              className: 'primary_button button'
              onClick: @submit

              'Save'

          if @local.save_complete
            DIV style: {color: 'green'}, 'Saved.'

          if @local.file_errors
            DIV style: {color: 'red'}, 'Error uploading files!'

          if @local.errors
            if @local.errors && @local.errors.length > 0
              DIV 
                style: 
                  borderRadius: 8
                  margin: 20
                  padding: 20
                  backgroundColor: '#FFE2E2'

                H1 style: {fontSize: 18}, 'Ooops!'

                for error in @local.errors
                  DIV 
                    style: 
                      marginTop: 10
                    error

  submit : -> 
    submitting_files = @submit_logo || @submit_masthead

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    fields = ['about_page_url', 'notifications_sender_email', 'app_title', 'external_project_url', 'plan', 'google_analytics_code', 'lang']

    for f in fields
      subdomain[f] = $(@getDOMNode()).find("##{f}").val()

    if current_user.is_super_admin
      subdomain.branding =
        primary_color: $('#primary_color').val()
        masthead_header_text: $('#masthead_header_text').val()
        # homepage_text: $('#homepage_text').val()

    @local.save_complete = @local.file_errors = false
    save @local

    save subdomain, => 
      if subdomain.errors
        @local.errors = subdomain.errors

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
            @local.file_errors = true
            save @local



CustomizationsDash = ReactiveComponent
  displayName: 'CustomizationsDash'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    subdomains = fetch('/subdomains')

    sub_ids = {'': ''}
    for sub in subdomains.subs when sub.customizations?.length > 0 && sub.name != subdomain.name
      sub_ids[sub.name.toLowerCase()] = sub.customizations

    if !@local.compare_to?
      @local.compare_to = '' #_.keys(sub_ids)[0]
      save @local

    compare_to = sub_ids[@local.compare_to]

    return SPAN null if !subdomain.name || !current_user.is_super_admin || !subdomains.subs

    if !CodeMirror?
      location.reload()
      return SPAN null

    @local.current_value ||= subdomain.customizations

    DIV 
      style: 
        width: '90%'
        margin: '20px auto'
      className: 'customizations'

      STYLE 
        dangerouslySetInnerHTML: {__html: """
          .customizations .CodeMirror {
            height: 500px;
            font-size: 14px;
            border: 1px solid #ddd;
          }

        """}

      DIV className: 'input_group',



        DIV 
          style: 
            display: 'inline-block'
            width: if @local.compare_to != '' then '58%' else '75%'
            verticalAlign: 'top'

          DIV 
            style: 
              fontStyle: 'italic'
              fontSize: 24
              fontWeight: 600
            "Customizations for #{subdomain.name}.consider.it:"

          CodeMirrorTextArea 
            ref: 'cm_editor'
            id: 'customizations'
            default_value: subdomain.customizations or "\n\n\n\n\n\n\n"
            onChange: (val) => 
              @local.current_value = val

          DIV 
            className: 'input_group'
            BUTTON 
              className: 'primary_button button'
              onClick: @submit

              'Save'

          if @local.save_complete
            DIV style: {color: 'green'}, 'Saved.'

          if @local.errors
            if @local.errors && @local.errors.length > 0
              DIV 
                style: 
                  borderRadius: 8
                  margin: 20
                  padding: 20
                  backgroundColor: '#FFE2E2'

                H1 style: {fontSize: 18}, 'Ooops!'

                for error in @local.errors
                  DIV 
                    style: 
                      marginTop: 10
                    error

        DIV 
          style: 
            display: 'inline-block'
            width:  if @local.compare_to == '' then '22%' else '38%'
            verticalAlign: 'top'
            marginLeft: '2%'

          DIV 
            style: 
              fontStyle: 'italic'
            "Compare to "
            SELECT 
              value: @local.compare_to
              style: 
                width: 80
              onChange: (ev) => 
                @local.compare_to = ev.target.value 
                save @local

              for sub, id of sub_ids 
                OPTION 
                  value: sub
                  sub 
            ".consider.it:"

          if compare_to
            CodeMirrorTextArea 
              key: compare_to
              id: 'comparison'
              default_value: compare_to

      DIV null, 

        DIV 
          style: 
            marginTop: 20
            marginBottom: 5
            cursor: 'pointer'
            fontWeight: 600
            color: '#666'
            textDecoration: 'underline'
            
          onClick: => @local.show_shared = !@local.show_shared; save @local

          "Shared code and variables to use in customizations"

        if @local.show_shared

          CodeMirrorTextArea 
            key: 'shared_code'
            default_value: subdomain.shared_code

      DIV null, 

        DIV 
          style: 
            marginTop: 20
            marginBottom: 5
            cursor: 'pointer'
            fontWeight: 600
            color: '#666'
            textDecoration: 'underline'

          onClick: => @local.show_doc = !@local.show_doc; save @local

          "Variable documentation"

        if @local.show_doc
          DIV 
            style: 
              marginTop: 10

            A 
              href: "https://docs.google.com/spreadsheets/d/1gn1PuF98i4eD8x0E4YHmtBAcEdau9W13cJ7fh6MF3u8/edit#gid=0"
              target: '_blank'
              style: 
                display: 'block'
                textDecoration: 'underline'
                color: focus_blue
                marginBottom: 5
              "Load documentation in own tab"
            "."


            IFRAME
              width: '100%' 
              height: 1500 
              src: "https://docs.google.com/spreadsheets/d/1gn1PuF98i4eD8x0E4YHmtBAcEdau9W13cJ7fh6MF3u8/pubhtml?widget=true&amp;headers=false"






  submit : -> 
    subdomain = fetch '/subdomain'

    subdomain.customizations = @local.current_value

    @local.save_complete = false
    save @local

    save subdomain, => 
      if subdomain.errors
        @local.errors = subdomain.errors

      @local.save_complete = true
      save @local



CodeMirrorTextArea = ReactiveComponent
  displayName: 'CodeMirrorTextArea'

  render: -> 
    TEXTAREA 
      id: @props.id
      name: @props.id
      ref: 'field'
      defaultValue: @props.default_value 

  componentDidMount: -> 
    betterTab = (cm) ->

      if cm.somethingSelected()
        cm.indentSelection 'add'
      else
        o = if cm.getOption("indentWithTabs")
              "\t"
            else 
              Array(cm.getOption("indentUnit") + 1).join(" ")

        cm.replaceSelection o, "end", "+input"

    @m = CodeMirror.fromTextArea @refs.field.getDOMNode(), _.defaults (@props.opts or {}),        
          lineNumbers: true
          matchBrackets: true
          indentUnit: 2
          mode: 'coffeescript'
          extraKeys: 
            Tab: betterTab
    if @props.onChange
      @m.on('change', => @props.onChange(@m.getValue()))

  componentWillUnmount: -> 
    @m.getTextArea().remove()





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
                LI key: item.key, style: {position: 'relative', listStyle: 'none', width: CONTENT_WIDTH() / 4},

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
  displayName: 'ModerationDash'

  render : -> 
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

      DIV style: {width: CONTENT_WIDTH(), margin: '15px auto'}, 
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
                          #saving the subdomain shouldn't always dirty moderations 
                          #(which is expensive), so just doing it manually here
                          arest.serverFetch('/page/dashboard/moderate')  

                      INPUT 
                        style: {cursor: 'pointer'}
                        type: 'radio'
                        name: "moderate_#{model}_mode"
                        id: "moderate_#{model}_mode_#{idx}"
                        defaultChecked: subdomain["moderate_#{model}_mode"] == idx

                      LABEL 
                        style: {cursor: 'pointer', paddingLeft: 8 } 
                        htmlFor: "moderate_#{model}_mode_#{idx}"
                        field

              BUTTON 
                onClick: => 
                  @local.edit_settings = false
                  save @local
                'close'

          else 
            BUTTON 
              style: 
                padding: '4px 8px'

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
    
    DIV style: adminStyles().task_area_style,
      
      # status area
      DIV style: adminStyles().task_area_bar,
        if item.updated_since_last_evaluation
          SPAN style: {}, "Updated since last moderation"
        else if item.status == 1
          SPAN style: {}, "Passed by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
        else if item.status == 2
          SPAN style: {}, "Quarantined by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
        else if item.status == 0
          SPAN style: {}, "Failed by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
        else 
          SPAN style: {}, "Is this #{class_name} ok?"

      DIV style: {padding: '10px 30px'},
        # content area
        DIV 
          style: adminStyles().task_area_section_style, 

          if class_name == 'Point'
            UL style: {marginLeft: 73}, 
              Point key: point, rendered_as: 'under_review', enable_dragging: false
          else if class_name == 'Proposal'
            DIV null,
              DIV 
                style: 
                  fontSize: 20
                  fontWeight: 600
                moderatable.name
              DIV 
                className: 'moderatable_item'

                dangerouslySetInnerHTML: 
                  __html: moderatable.description

          else if class_name == 'Comment'
            if !@local.show_conversation
              DIV null,
                A style: {textDecoration: 'underline', paddingBottom: 10, display: 'block'}, onClick: (=> @local.show_conversation = true; save(@local)),
                  'Show full conversation'
                Comment 
                  key: moderatable
                  under_review: true

            else
              DIV null,
                A style: {textDecoration: 'underline', paddingBottom: 10, display: 'block'}, onClick: (=> @local.show_conversation = false; save(@local)),
                  'Hide full conversation'

                UL style: {opacity: .5, marginLeft: 73}, 
                  Point key: point, rendered_as: 'under_review', enable_dragging: false
                for comment in _.uniq( _.map(comments.comments, (c) -> c.key).concat(moderatable.key))

                  if comment != moderatable.key
                    DIV style: {opacity: .5},
                      Comment key: comment
                  else 
                    Comment key: moderatable



          DIV style:{fontSize: 12, marginLeft: 73}, 
            "by #{author.name}"

            if !moderatable.hide_name && !@local.messaging
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              BUTTON
                style: {textDecoration: 'underline', backgroundColor: 'transparent', border: 'none'}
                onClick: (=> @local.messaging = moderatable; save(@local)),
                'Message author']
            else if @local.messaging
              DirectMessage to: @local.messaging.user, parent: @local, sender_mask: 'Moderator'



        # moderation area
        DIV style: adminStyles().task_area_section_style, 
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

# TODO: Refactor the below and make sure that the styles applied to the 
#       user generated fields are in sync with the styling in the 
#       wysiwyg editor. 
styles += """
.moderatable_item br {
  padding-bottom: 0.5em; }
.moderatable_item p, 
.moderatable_item ul, 
.moderatable_item ol, 
.moderatable_item table {
  margin-bottom: 0.5em; }
.moderatable_item td {
  padding: 0 3px; }
.moderatable_item li {
  list-style: outside; }
.moderatable_item ol li {
  list-style-type: decimal; }  
.moderatable_item ul,
.moderatable_item ol, {
  padding-left: 20px;
  margin-left: 20px; }
.moderatable_item a {
  text-decoration: underline; }
.moderatable_item blockquote {
  opacity: 0.7;
  padding: 10px 20px; }
.moderatable_item table {
  padding: 20px 0px; }
"""

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

    DIV null,
      DashHeader name: 'Fact check user contributions'

      DIV style: {width: CONTENT_WIDTH(), margin: '15px auto'}, 
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

    DIV style: adminStyles().task_area_style,
      STYLE null, '.claim_result a{text-decoration: underline;}'
      
      # status area
      DIV style: adminStyles().task_area_bar,
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
            BUTTON 
              style: {backgroundColor: focus_blue, color: 'white', fontSize: 14, border: 'none', borderRadius: 8, fontWeight: 600 }
              onClick: @toggleResponsibility, "I'll do it"]

      DIV style: {padding: '10px 30px'},
        # point area
        DIV style: adminStyles().task_area_section_style, 
          UL style: {marginLeft: 73}, 
            Point key: point, rendered_as: 'under_review', enable_dragging: false

          DIV style:{fontSize: 12, marginLeft: 73}, 
            "by #{fetch(point.user).name}"
            SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
            A 
              target: '_blank'
              href: "/#{proposal.slug}?selected=#{point.key}"
              style: {textDecoration: 'underline'}
              'Read point in context'

            if !point.hide_name && @local.messaging != point
              [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
              BUTTON
                style: {textDecoration: 'underline', backgroundColor: 'transparent', border: 'none'}
                onClick: (=> @local.messaging = point; save(@local)),
                'Email author']
            else if @local.messaging == point
              DirectMessage to: @local.messaging.user, parent: @local, sender_mask: 'Fact-checker'


        # requests area
        DIV style: adminStyles().task_area_section_style, 
          H1 style: adminStyles().task_area_header_style, 'Fact check requests'
          DIV style: {}, 
            for request in assessment.requests
              DIV className: 'comment_entry', key: request.key,

                Avatar
                  className: 'comment_entry_avatar'
                  tag: DIV
                  key: request.user
                  hide_tooltip: true
                  style: 
                    width: 50
                    height: 50

                DIV 
                  style: 
                    display: 'inline-block'
                    width: '80%'

                  DIV style: {marginLeft: 20},
                    splitParagraphs(request.suggestion)

                  DIV style:{fontSize: 12, marginLeft: 20}, 
                    "by #{fetch(request.user).name || 'anonymous'}"
                    if @local.messaging != request
                      [SPAN style: {fontSize: 8, padding: '0 4px'}, " • "
                      A
                        style: {textDecoration: 'underline'}
                        onClick: (=> @local.messaging = request; save(@local)),
                        'Email requester']
                    else if @local.messaging == request
                      DirectMessage to: @local.messaging.user, parent: @local, sender_mask: 'Fact-checker'

        # claims area
        DIV style: adminStyles().task_area_section_style, 
          H1 style: adminStyles().task_area_header_style, 'Claims under review'


          DIV style: {}, 
            for claim in assessment.claims
              claim = fetch(claim)
              if @local.editing == claim.key
                EditClaim fresh: false, key: claim.key, parent: @local, assessment: @data()
              else 

                verdict = fetch(claim.verdict)
                DIV key: claim.key, style: {marginLeft: 60, marginBottom: 18, position: 'relative'}, 
                  IMG style: {position: 'absolute', width: 50, left: -60}, src: verdict.icon

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

                    do => 
                      button_style = 
                        marginRight: 5
                        fontSize: 14

                      DIV 
                        style: 
                          marginTop: 10
                          
                        if claim.result && claim.verdict && !claim.approver #&& current_user.id != claim.creator
                          BUTTON style: button_style, onClick: (do (claim) => => @toggleClaimApproval(claim)), 'Approve'
                        else if claim.approver
                          BUTTON style: button_style, onClick: (do (claim) => => @toggleClaimApproval(claim)), 'Unapprove'

                        BUTTON style: button_style, onClick: (do (claim) => => @local.editing = claim.key; save(@local)), 'Edit'
                        BUTTON style: button_style, onClick: (do (claim) => => @deleteClaim(claim)), 'Delete'

            if @local.editing == 'new'
              EditClaim fresh: true, key: '/new/claim', parent: @local, assessment: @data()
            else if !@local.editing
              Button {style: {marginLeft: 0, marginTop: 15}}, '+ Add new claim', => @local.editing = 'new'; save(@local)

        DIV style: adminStyles().task_area_section_style,
          H1 style: adminStyles().task_area_header_style, 'Private notes'
          AutoGrowTextArea
            className: 'assessment_notes'
            placeholder: 'Private notes about this fact check'
            defaultValue: assessment.notes
            min_height: 60
            style: 
              width: 500
              fontSize: 16
              display: 'block'
              padding: '4px 8px'


          BUTTON style: {fontSize: 14}, onClick: @saveNotes, 'Save notes'

          DIV style: adminStyles().task_area_header_style,
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
      fontSize: 16
      display: 'block'
      padding: '4px 8px'

    DIV style: {marginTop: 18, padding: '15px 20px', backgroundColor: 'white', width: 550, border: '#999', boxShadow: "0 1px 2px rgba(0,0,0,.2)"}, 
      DIV style: {marginBottom: 8},
        LABEL null, 'To: ', fetch(@props.to).name

      DIV style: {marginBottom: 8},
        LABEL htmlFor: 'message_subject', 'Subject'
        AutoGrowTextArea
          id: 'message_subject'
          className: 'message_subject'
          placeholder: 'Subject line'
          min_height: 25
          style: text_style

      DIV style: {marginBottom: 8},
        LABEL htmlFor: 'message_body', 'Body'
        AutoGrowTextArea
          id: 'message_body'
          className: 'message_body'
          placeholder: 'Email message'
          min_height: 75
          style: text_style

      Button {}, 'Send', @submitMessage
      BUTTON style: {marginLeft: 8, backgroundColor: 'transparent', border: 'none'}, onClick: (=> @props.parent.messaging = null; save @props.parent), 'cancel'

  submitMessage : -> 
    # TODO: convert to using arest create method; waiting on full dash porting
    $el = $(@getDOMNode())
    attrs = 
      recipient: @props.to
      subject: $el.find('.message_subject').val()
      body: $el.find('.message_body').val()
      sender_mask: @props.sender_mask or fetch('/current_user').name
      authenticity_token: fetch('/current_user').csrf

    $.ajax '/dashboard/message', data: attrs, type: 'POST', success: => 
      @props.parent.messaging = null
      save @props.parent

EditClaim = ReactiveComponent
  displayName: 'EditClaim'

  render : -> 
    text_style = 
      width: 550
      fontSize: 16
      display: 'block'
      padding: '4px 8px'

    DIV style: {padding: '8px 12px', backgroundColor: "rgba(0,0,0,.1)", marginLeft: 0, marginBottom: 18 },
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


## Export...
window.FactcheckDash = FactcheckDash
window.ModerationDash = ModerationDash
window.AppSettingsDash = AppSettingsDash
window.ImportDataDash = ImportDataDash
window.DashHeader = DashHeader
window.CustomizationsDash = CustomizationsDash