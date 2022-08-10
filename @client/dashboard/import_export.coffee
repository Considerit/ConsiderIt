window.DataDash = ReactiveComponent
  displayName: 'DataDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    if current_user.is_super_admin
      tables = ['Users', 'Proposals', 'Opinions', 'Points', 'Comments']
    else 
      tables = ['Proposals']

    paid = permit('configure paid feature') > 0

    query = ''
    user_tags = customization 'user_tags'
    if user_tags

      query = "?#{(v.key for v in user_tags).join('=1&')}" 

    DIV null, 

      if current_user.is_super_admin
        DIV 
          style: 
            marginBottom: 24
          BUTTON 
            onClick: => 
              if confirm("Are you sure you want to delete everything on this forum?")
                
                $.ajax
                  url: "/nuke_everything",
                  type: "PUT"
                  data: 
                    authenticity_token: current_user.csrf
                  success: =>
                    location.reload()

            "Delete all data on this forum"
      

      if !paid
        UpgradeForumButton
          big: true
          text: "Upgrade to enable data import and export"

      FORM 
        action: "/dashboard/export#{query}"
        method: 'post'
        style: 
          pointerEvents: if !paid then 'none'
          opacity: if !paid then .4

        INPUT 
          type: 'hidden'
          name: 'authenticity_token'
          value: current_user.csrf

        H4
          style: 
            fontSize: 20
            marginBottom: 12

          "Export data from your forum"

        DIV 
          className: 'explanation'
          "A download will begin in a couple seconds after hitting export. The zip file contains four spreadsheets: opinions, points, proposals, and users."

        INPUT
          type: 'submit'
          className: 'btn' 
          style: 
            marginTop: 18
            fontSize: 20

          onClick: => 
            show_flash(translator('admin.flashes.export_started', "Your export has started. It can take a little while."))

          value: 'Export'







      DIV 
        style: 
          marginTop: 24
          pointerEvents: if !paid then 'none'
          opacity: if !paid then .4


        H4
          style: 
            fontSize: 20
            marginBottom: 12

          "Import data to your forum"

        DIV 
          className: 'explanation'

          P 
            style: 
              marginBottom: 6

            "Your proposal import spreadsheet file should be in CSV format. Importing the same spreadsheet multiple times is okay. Here is an "
            A 
              style: 
                textDecoration: 'underline'
                fontWeight: 700
              href: "/example_import_csvs/proposals.csv"
              'data-nojax': true
              'example .csv file'
            "."


        FORM 
          id: 'import_data'
          action: '/dashboard/data_import_export'

          for table in tables
            DIV
              key: table
              style: 
                display: 'flex'

              if current_user.is_super_admin
                DIV 
                  style: 
                    paddingTop: 20
                    textAlign: 'right'
                    width: 150

                  LABEL style: {whiteSpace: 'nowrap'}, htmlFor: "#{table}-file", "#{table} (.csv)"

                  DIV null
                    A 
                      style: 
                        textDecoration: 'underline'
                        fontSize: 12
                      href: "/example_import_csvs/#{table.toLowerCase()}.csv"
                      'data-nojax': true
                      'Example'

              DIV 
                style: 
                  padding: '20px 0 0 20px'

                INPUT 
                  id: "#{table}-file"
                  name: "#{table.toLowerCase()}-file"
                  type:'file'
                  style: {backgroundColor: selected_color, color: 'white', fontWeight: 700, borderRadius: 8, padding: 6}
            

          if current_user.is_super_admin
            [
              DIV 
                key: 'generate_inclusions'
                style: 
                  padding: '20px 0 20px 20px' 
                INPUT type: 'checkbox', name: 'generate_inclusions', id: 'generate_inclusions'
                LABEL htmlFor: 'generate_inclusions', 
                  """
                  Generate opinions & inclusions of points?
                  It requires a proposal file; for each proposal in the file, this option will increase by 
                  2x the number of existing opinions. Each simulated opinion will include two points. 
                  Stances and inclusions will not be assigned randomly, but rather following a 
                  rich-get-richer model. You can use this option multiple times. This option is only good for demos.
                  """

              DIV 
                key: 'assign_pics'
                style: 
                  padding: '20px 0 20px 20px' 
                INPUT type: 'checkbox', name: 'assign_pics', id: 'assign_pics'
                LABEL htmlFor: 'assign_pics', 
                  """
                  Assign a random profile picture for users without an avatar url
                  """
            ]

          BUTTON
            id: 'submit_import'
            className: 'btn'
            style: 
              marginTop: 18
              fontSize: 20

            onClick: (e) => 
              e.preventDefault()

              $$.setStyles 'html, #submit_import', {cursor: 'wait'}

              ajax_submit_files_in_form
                form: '#import_data'
                type: 'POST'
                additional_data: 
                  authenticity_token: current_user.csrf
                  trying_to: 'update_avatar_hack'   
                success: (data) => 
                  
                  data = JSON.parse data
                  if data[0].errors
                    @local.successes = null
                    @local.errors = data[0].errors
                    save @local
                  else
                    $$.setStyles 'html, #submit_import', {cursor: ''}

                    # clear out statebus 
                    arest.clear_matching_objects((key) -> key.match( /\/page\// ))
                    @local.errors = null
                    @local.successes = data[0]
                    save @local
                error: (result) => 
                  $$.setStyles 'html, #submit_import', {cursor: ''}
                  @local.successes = null                      
                  @local.errors = ['Unknown error parsing the files. Email tkriplean@gmail.com.']
                  save @local

            'Import Data'


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
