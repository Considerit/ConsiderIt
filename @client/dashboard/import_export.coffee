window.DataDash = ReactiveComponent
  displayName: 'DataDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    tables = ['Users', 'Proposals', 'Opinions', 'Points', 'Comments']

    DIV null, 

      if current_user.is_super_admin
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
      

      if subdomain.plan || current_user.is_super_admin
        query = ''
        user_tags = customization 'user_tags'
        if user_tags
          query = "?#{Object.keys(user_tags).join('&')}" 

        DIV null, 
          "Export data from Considerit. A download will begin in a couple seconds after hitting export. The zip file contains four spreadsheets: opinions, points, proposals, and users."
          DIV style: marginTop: 20, display: 'block'
          A 
            style: 
              backgroundColor: focus_color()
            href: "/dashboard/export#{query}"
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


      DIV null,
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

        FORM 
          id: 'import_data'
          action: '/dashboard/data_import_export'


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
