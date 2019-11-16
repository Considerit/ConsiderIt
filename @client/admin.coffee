# Admin components, like moderation


# require './vendor/jquery.form'
require './form'
require './shared'


window.DashHeader = ReactiveComponent
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
          TRANSLATE 
            id: "admin.dash_header.#{@props.name}"
            @props.name   

ImportDataDash = ReactiveComponent
  displayName: 'ImportDataDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    tables = ['Users', 'Proposals', 'Opinions', 'Points', 'Comments']

    DIV null, 

      
      DashHeader name: 'Export Data'

      DIV style: {width: HOMEPAGE_WIDTH(), margin: '15px auto'},

      if subdomain.plan || current_user.is_super_admin
        DIV null, 
          "Export data from Considerit. A download will begin in a couple seconds after hitting export. The zip file contains four spreadsheets: opinions, points, proposals, and users."
          DIV style: marginTop: 20, display: 'block'
          A 
            style: 
              backgroundColor: focus_color()
            href: "/dashboard/export"
            "data-nojax": true
            className: 'primary_button'

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
                    style: {backgroundColor: focus_color(), color: 'white', fontWeight: 700, borderRadius: 8, padding: 6}
            

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
                  className: 'primary_button'
                  style: 
                    backgroundColor: focus_color()
                  onClick: (e) => 
                    e.preventDefault()
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
        .app_settings_dash input[type="text"], .app_settings_dash textarea { border: 1px solid #aaa; display: block; width: #{HOMEPAGE_WIDTH()}px; font-size: 18px; padding: 4px 8px; } 
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
            LABEL htmlFor: 'lang', 'Primary Language'
            SELECT 
              id: 'lang'
              type: 'text'
              name: 'lang'
              defaultValue: subdomain.lang
              style: 
                fontSize: 18
                marginLeft: 12
                display: 'inline-block'


              do => 
                available_languages = Object.assign({}, fetch('/translations').available_languages or {})
                if current_user.is_super_admin
                  available_languages['pseudo-en'] = "Pseudo English (for testing)"
                  
                for abbrev, label of available_languages

                  OPTION
                    value: abbrev
                    label 

            if subdomain.lang? && subdomain.lang != 'en'
              DIV 
                style: 
                  fontSize: 12

                TRANSLATE
                  id: "i18n.translations_link"
                  percent_complete: Math.round(translation_progress(subdomain.lang) * 100)
                  language: (fetch('/translations').available_languages or {})[subdomain.lang]
                  link: 
                    component: A 
                    args: 
                      href: "/dashboard/translations"
                      style:
                        textDecoration: 'underline'
                        color: focus_color()
                        fontWeight: 700
                  "Translations for {language} are {percent_complete}% completed. Help improve the translations <link>here</link>."


            DIV 
              style: 
                fontSize: 12
              "Is your preferred language not available? Email us at hello@consider.it to help us create a translation."




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
              style: 
                backgroundColor: focus_color()
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
    @local.customization_filter ||= ''

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
              style: 
                backgroundColor: focus_color()
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

          INPUT 
            style: 
              width: '100%'
            placeholder: 'Filter to subs with customization containing...'
            ref: 'customization_filter'
            type: 'text'
            defaultValue: ''
            onKeyUp: (e) => 
              @local.customization_filter = @refs.customization_filter.getDOMNode().value
              save @local

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

              for sub, id of sub_ids when @local.customization_filter.length == 0 || id.toLowerCase().indexOf(@local.customization_filter.toLowerCase()) > -1
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
                color: focus_color()
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




        
ModerationDash = ReactiveComponent
  displayName: 'ModerationDash'

  render : -> 
    moderations = @data().moderations
    subdomain = fetch '/subdomain'

    # todo: choose default more intelligently
    @local.model ||= 'Proposal'

    dash = fetch 'moderation_dash'

    all_items = {}

    for model in ['Point', 'Comment', 'Proposal']
      
      # Separate moderations by status
      passed = []
      reviewable = []
      quarantined = []
      failed = []

      moderations[model] ||= []

      moderations[model].sort (a,b) -> 
        new Date(fetch(b.moderatable).created_at) - new Date(fetch(a.moderatable).created_at)


      for i in moderations[model]
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

      all_items[model] = [['Pending', reviewable, true], ['Quarantined', quarantined, true], ['Failed', failed, true], ['Passed', passed, false]]
    
    items = all_items[@local.model]
    @items = items 


    # We assume an ordering of the task categories where the earlier
    # categories are more urgent & shown higher up in the list than later categories.

    if !dash.selected_task && items.length > 0
      # Prefer to select a higher urgency task by default

      for [category, itms] in items
        if itms.length > 0
          dash.selected_task = itms[0].key
          save dash
          break

    # After a moderation is saved, that item will alert the dash
    # that we should move to the next moderation.
    # Need state history to handle this more elegantly
    if dash.transition
      @selectNext()

    DIV null,
      DIV null, 

        ModerationOptions()

        UL 
          style: 
            listStyle: 'none'
            margin: '20px auto'
            textAlign: 'center'

          for model in ['Point', 'Comment', 'Proposal']
            select_class = (model) => @local.model = model; save @local

            do (model) => 
              LI 
                style: 
                  display: 'inline-block'

                BUTTON 
                  style: 
                    backgroundColor: if @local.model == model then '#444' else 'transparent'
                    color: if @local.model == model then 'white' else '#aaa'
                    fontSize: 36
                    marginRight: 32
                    border: 'none'
                    borderRadius: 4
                    fontWeight: 600
                    fontStyle: 'oblique'

                  onClick: => select_class(model)
                  onKeyPress: (e) => 
                    if e.which in [13, 32]
                      select_class(model); e.preventDefault()
                  "Review #{model}s"

                  " (#{all_items[model][0][1].length})"



        DIV null, 

          for [category, itms, default_show] in items

            if itms.length > 0
              show_category = (if @local["show_#{category}"]? then @local["show_#{category}"] else default_show)
              toggle_show = do (category, show_category) => =>
                @local["show_#{category}"] = !show_category
                save @local 

              DIV 
                style: 
                  marginTop: 20
                  key: category



                H1 
                  style: 
                    fontSize: 24
                    fontStyle: 'oblique'
                    fontWeight: 600
                    textAlign: 'center'
                    backgroundColor: '#e0e0e0'
                    margin: '20px 0'
                    cursor: 'pointer'
                  onClick: toggle_show

                  category

                  " (#{itms.length})"


                  A 
                    style: 
                      #float: 'right'
                      color: '#aaa'
                      fontWeight: 400
                      fontStyle: 'oblique'
                      verticalAlign: 'middle'
                      paddingRight: 10
                      paddingLeft: 40
                      textDecoration: 'underline'
                      
                    

                    if show_category
                      'Hide'

                    else 
                      'Show'


                if show_category
                  UL 
                    style: {}
                    for item in itms
                      LI 
                        'data-id': item.key
                        key: item.key
                        style: 
                          position: 'relative'
                          listStyle: 'none'

                        onClick: do (item) => => 
                          dash.selected_task = item.key
                          save dash
                          setTimeout => 
                            $("[data-id='#{item.key}']").ensureInView()
                          , 1


                        ModerateItem 
                          key: item.key
                          selected: dash.selected_task == item.key



  # select a different task in the list relative to data.selected_task
  selectNext: -> @_select(false)
  selectPrev: -> @_select(true)
  _select: (reverse) -> 
    dash = fetch 'moderation_dash'
    get_next = false
    all_items = if !reverse then @items else @items.slice().reverse()

    for [category, items, default_show] in all_items
      tasks = if !reverse then items else items.slice().reverse()
      show_category = (if @local["show_#{category}"]? then @local["show_#{category}"] else default_show)
      continue if !show_category

      for item in tasks
        if get_next
          dash.selected_task = item.key
          dash.transition = null
          save dash
          setTimeout => 
            $("[data-id='#{item.key}']").ensureInView()
          , 1
          return
        else if item.key == dash.selected_task
          get_next = true

  componentDidMount: ->
    $(document).on 'keyup.dash', (e) =>
      @selectNext() if e.keyCode == 40 # down
      @selectPrev() if e.keyCode == 38 # up
  componentWillUnmount: ->
    $(document).off 'keyup.dash'






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
      tease = "#{moderatable.nutshell.substring(0, 120)}..."
      header = moderatable.nutshell
      details = moderatable.text 
      href = "/#{proposal.slug}?results=true&selected=#{point.key}"
    else if class_name == 'Comment'
      point = fetch(moderatable.point)
      proposal = fetch(point.proposal)
      comments = fetch("/comments/#{point.id}")
      tease = "#{moderatable.body.substring(0, 120)}..."
      header = moderatable.body
      details = ''
      href = "/#{proposal.slug}?results=true&selected=#{point.key}"      
    else if class_name == 'Proposal'
      proposal = moderatable
      tease = "#{proposal.name.substring(0, 120)}..."
      header = proposal.name
      details = moderatable.description
      href = "/#{proposal.slug}"


    current_user = fetch('/current_user')
    
    selected = @props.selected 

    item_header = 
      fontWeight: 700
      fontSize: 22

    DIV 
      style: 
        cursor: if selected then 'auto' else 'pointer'
        margin: 'auto'
        borderLeft:  "4px solid #{if selected then focus_color() else 'transparent'}"
        padding: '8px 14px'
        maxWidth: 700
        marginBottom: if selected then 40 else 12



      DIV 
        style: 
          marginLeft: 70
          position: 'relative'

        DIV null, 

          if class_name == 'Comment' && selected #@local.show_conversation && selected
            DIV 
              style: 
                opacity: .5
              BUBBLE_WRAP 
                title: point.nutshell 
                anon: point.hide_name
                user: point.user
                body: point.text
                width: '100%'


              for comment in _.uniq( _.map(comments.comments, (c) -> c.key).concat(moderatable.key)) when comment != moderatable.key
                BUBBLE_WRAP 
                  title: fetch(comment).body
                  user: fetch(comment).user
                  width: '100%'

          BUBBLE_WRAP
            title: if selected then header else tease
            body: if selected then moderatable.description else ''
            anon: !!moderatable.hide_name
            user: moderatable.user
            width: '100%'

          DIV null,
            "by #{author.name}"


            if selected 
              A 
                style: 
                  textDecoration: 'underline'
                  padding: '0 8px'
                target: '_blank'
                href: href
                'data-nojax': true


                "View #{class_name}"

            if selected && !moderatable.hide_name && !@local.messaging
              BUTTON
                style: 
                  marginLeft: 8
                  textDecoration: 'underline'
                  backgroundColor: 'transparent'
                  border: 'none'
                onClick: => @local.messaging = moderatable; save(@local)
                'Message author'



        if selected && @local.messaging
          DirectMessage to: @local.messaging.user, parent: @local, sender_mask: 'Moderator'

      if selected && class_name == 'Proposal'
        # Category
        DIV 
          style: 
            marginTop: 8
            marginLeft: 63
                  
          SELECT
            style: 
              fontSize: 18
            value: proposal.cluster
            ref: 'category'
            onChange: (e) =>
              proposal.cluster = e.target.value
              save proposal

            for clust in get_all_clusters()
              OPTION  
                value: clust
                clust

      if selected 

        judge = (judgement) => 
          # this has to happen first otherwise the dash won't 
          # know what the next item is when it transitions
          dash = fetch 'moderation_dash'
          dash.transition = item.key #need state transitions 
          save dash

          setTimeout => 
            item.status = judgement
            save item
          , 1

        # moderation area
        DIV 
          style:       
            margin: '10px 0px 20px 63px'
            position: 'relative'

          STYLE null, 
            """
            .moderation { font-weight: 600; border-radius: 8px; padding: 6px 12px; display: inline-block; margin-right: 10px; box-shadow: 0px 1px 2px rgba(0,0,0,.4)}
            .moderation label, .moderation input { font-size: 22px; cursor: pointer }
            """

          DIV 
            className: 'moderation',
            style: 
              backgroundColor: '#81c765'
            onClick: -> judge(1)

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'pass'
              defaultChecked: item.status == 1

            LABEL htmlFor: 'pass', 'Pass'

          DIV 
            className: 'moderation'
            style: 
              backgroundColor: '#ffc92a'

            onClick: -> judge(2)

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'quar'
              defaultChecked: item.status == 2
            LABEL htmlFor: 'quar', 'Quarantine'
          DIV 
            className: 'moderation'
            style: 
              backgroundColor: '#f94747'

            onClick: -> judge(0)

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'fail'
              defaultChecked: item.status == 0

            LABEL htmlFor: 'fail', 'Fail'

      if selected 

        # status area
        DIV 
          style: 
            marginLeft: 63
            fontStyle: 'italic'


          if item.updated_since_last_evaluation
            SPAN style: {}, "Updated since last moderation"
          else if item.status == 1
            SPAN style: {}, "Passed by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
          else if item.status == 2
            SPAN style: {}, "Quarantined by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
          else if item.status == 0
            SPAN style: {}, "Failed by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"





ModerationOptions = ReactiveComponent
  displayName: 'ModerationOptions'


  render: -> 
    subdomain = fetch '/subdomain'
    expanded = subdomain.moderated_classes.length == 0 || @local.edit_settings

    DIV 
      style: 
        textAlign: if !expanded then 'right'
        paddingRight: if !expanded then 30


      if !expanded 
        BUTTON 
          style: 
            backgroundColor: 'transparent'
            fontSize: 24
            border: 'none'
            textDecoration: 'underline'
            color: '#aaa'
            fontStyle: 'oblique'
          onClick: => 
            @local.edit_settings = true
            save @local
          'Edit moderation settings'    

      else
        DIV 
          style: 
            padding: 50
                       
          for model in ['points', 'comments', 'proposals']
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

DirectMessage = ReactiveComponent
  displayName: 'DirectMessage'

  render : -> 
    text_style = 
      width: 500
      fontSize: 16
      display: 'block'
      padding: '4px 8px'

    DIV style: {margin: '18px 0', padding: '15px 20px', backgroundColor: 'white', width: 550, backgroundColor: considerit_gray, boxShadow: "0 2px 4px rgba(0,0,0,.4)"}, 
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


## Export...
window.ModerationDash = ModerationDash
window.AppSettingsDash = AppSettingsDash
window.ImportDataDash = ImportDataDash
window.DashHeader = DashHeader
window.CustomizationsDash = CustomizationsDash