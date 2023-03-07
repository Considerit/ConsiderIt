
styles += """
  .dangerzone button {
    background-color: #c31d1d;
    padding: 8px 24px;
    color: white;
    font-weight: 600;
    border: none;
    border-radius: 8px;    
  }

"""


window.DataDash = ReactiveComponent
  displayName: 'DataDash'


  successful_import_cb: (data) ->
                  
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


  failed_import_cb: (result) ->
    $$.setStyles 'html, #submit_import', {cursor: ''}
    @local.successes = null                      
    @local.errors = ['Unknown error parsing the files. Email help@consider.it.']
    save @local

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
          value: arest.csrf()

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
                flexDirection: if PHONE_SIZE() then 'column' else 'row'
                alignItems: 'center'

              if current_user.is_super_admin
                DIV 
                  style: 
                    paddingTop: 20
                    textAlign: if !PHONE_SIZE() then 'right' else 'center'
                    width: 150

                  LABEL style: {whiteSpace: 'nowrap'}, htmlFor: "#{table}-file", "#{table} (.csv)"

                  DIV null, 
                    A 
                      style: 
                        textDecoration: 'underline'
                        fontSize: 12
                      href: "/example_import_csvs/#{table.toLowerCase()}.csv"
                      'data-nojax': true
                      'Example'

              DIV 
                style: 
                  padding: '20px 20px 0 20px'

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
              marginTop: 36
              fontSize: 20

            onClick: (e) => 
              e.preventDefault()

              $$.setStyles 'html, #submit_import', {cursor: 'wait'}

              ajax_submit_files_in_form
                form: '#import_data'
                type: 'POST'
                additional_data: 
                  authenticity_token: arest.csrf()
                  trying_to: 'update_avatar_hack'   
                success: @successful_import_cb
                error: @failed_import_cb

            'Import Data'


        if current_user.is_super_admin
          [ @drawArgdownImport(), @drawArgdownExport() ]


        if @local.errors && @local.errors.length > 0
          DIV style: {borderRadius: 8, margin: 20, padding: 20, backgroundColor: '#FFE2E2'}, 
            H1 style: {fontSize: 18}, 'Ooops! There are errors in the uploaded files:'
            for error in @local.errors
              DIV style: {marginTop: 10}, error

        if @local.successes
          DIV style: {borderRadius: 8, margin: 20, padding: 20, backgroundColor: '#E2FFE2'}, 
            H1 style: {fontSize: 18}, 'Success! Here\'s what happened:'
            
            for table, successes of @local.successes
              for success in successes
                DIV style: {display: 'block', marginTop: 10}, success

        
      DIV 
        className: 'dangerzone'
        style: 
          marginTop: 24
          pointerEvents: if !paid then 'none'
          opacity: if !paid then .4


        H4
          style: 
            fontSize: 20
            marginBottom: 12

          "Danger Zone"


        if current_user.is_admin
          DIV 
            style: 
              marginBottom: 24
            BUTTON 
              onClick: => 
                if confirm("Are you sure you want to delete all proposals, opinions, and comments on this forum?")
                  
                  frm = new FormData()
                  frm.append "authenticity_token", arest.csrf()

                  cb = =>
                    location.reload()

                  xhr = new XMLHttpRequest
                  xhr.addEventListener 'readystatechange', cb, false
                  xhr.open 'PUT', '/nuke_everything', true
                  xhr.send frm

              "Delete all data on this forum"

        if current_user.is_admin
          DIV 
            style: 
              marginBottom: 24
            BUTTON 
              onClick: => 
                if confirm("Are you sure you want to entirely delete this forum? In addition to removing all content, the forum and all its configuration will be removed.")
                  
                  frm = new FormData()
                  frm.append "authenticity_token", arest.csrf()
                  frm.append "subdomain_to_destroy", subdomain.id

                  cb = =>
                    # location.reload()
                    console.log 'done'

                  xhr = new XMLHttpRequest
                  xhr.addEventListener 'readystatechange', cb, false
                  xhr.open 'DELETE', '/destroy_forum', true
                  console.log 'DELETE'
                  xhr.send frm

              "Delete this forum entirely"



  drawArgdownImport: -> 
    FORM 
      id: 'import_argdown'
      action: '/dashboard/data_import_argdown'
      style: 
        marginTop: 72
        borderTop: '1px dotted #ddd'

      H2
        style: 
          fontSize: 20
          margin: "16px 0"
        'Argdown-like Import'
        SUP
          style: 
            color: '#999'
            fontSize: 12
            fontWeight: 400
            paddingLeft: 4
          'Experimental'


      INPUT 
        id: "argdown-file"
        name: "argdown-file"
        type:'file'
        # style: {backgroundColor: selected_color, color: 'white', fontWeight: 700, borderRadius: 8, padding: 6}

      BUTTON
        id: 'submit_import_argdown'
        className: 'btn'
        style: 
          display: 'block'
          marginTop: 24
          fontSize: 16

        onClick: (e) => 
          e.preventDefault()

          $$.setStyles 'html, #import_argdown', {cursor: 'wait'}

          ajax_submit_files_in_form
            form: '#import_argdown'
            type: 'POST'
            additional_data: 
              authenticity_token: arest.csrf()
              trying_to: 'update_avatar_hack'   
            success: @successful_import_cb
            error: @failed_import_cb

        'Import'



  drawArgdownExport: -> 

    FORM 
      className: "argdown-export"
      action: "/dashboard/export_argdown"
      method: 'post'

      STYLE 
        dangerouslySetInnerHTML: __html: """
          .argdown-export label {
            display: flex;
          }
          .argdown-export input[type='checkbox'] {
            margin-right: 12px;
          }
          .argdown-export .options {
            margin-bottom: 24px;
          }


        """

      INPUT 
        type: 'hidden'
        name: 'authenticity_token'
        value: arest.csrf()

      H2
        style: 
          fontSize: 20
          margin: "16px 0"
        'Argdown-like Export'

        SUP
          style: 
            color: '#999'
            fontSize: 12
            fontWeight: 400
            paddingLeft: 4
          'Experimental'

      DIV 
        className: 'options'
        LABEL null,

          INPUT 
            type: 'checkbox'
            defaultChecked: false
            name: 'exclude_metadata'

          "Exclude metadata"

        LABEL null,

          INPUT 
            type: 'checkbox'
            defaultChecked: false
            name: 'exclude_comments'

          "Exclude comments"

        LABEL null,

          INPUT 
            type: 'checkbox'
            defaultChecked: false
            name: 'exclude_points'

          "Exclude points"

        LABEL null,

          INPUT 
            type: 'checkbox'
            defaultChecked: false
            name: 'exclude_proposals'

          "Exclude proposals"

        LABEL null,

          INPUT 
            type: 'checkbox'
            defaultChecked: false
            name: 'exclude_descriptions'

          "Exclude descriptions"

        LABEL null,

          INPUT 
            type: 'checkbox'
            defaultChecked: false
            name: 'use_indexes'

          "Use indexes"


      INPUT
        type: 'submit'
        className: 'btn' 
        style: 
          fontSize: 16

        onClick: => 
          show_flash(translator('admin.flashes.export_started', "Your export has started. It can take a little while."))

        value: 'Export Argdown'

