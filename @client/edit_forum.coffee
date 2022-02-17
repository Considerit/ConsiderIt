window.EditForum = ReactiveComponent
  displayName: 'EditForum'

  render: ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    edit_forum = fetch 'edit_forum'

    if !current_user.is_admin
      return DIV null 

    enter_edit = (e) ->
      edit_forum.editing = true 
      save edit_forum

    exit_edit = (e) ->
      for key in Object.keys(edit_forum) when key != 'key'
        delete edit_forum[key]
      save edit_forum


    is_light = is_light_background()

    if !edit_forum.editing

      DIV 
        style: 
          position: 'absolute'
          left: "50%"
          top: 8
          zIndex: 2
          marginLeft: -52

        BUTTON
          style: 
            border: 'none'

            # backgroundColor: if is_light then "rgba(255,255,255,.2)" else "rgba(0,0,0,.2)"
            # color: if is_light then 'rgba(0,0,0,.6)' else 'rgba(255,255,255,.6)'

            backgroundColor: if is_light then "rgba(0,0,0,.8)" else "rgba(255,255,255,.8)"
            color: if !is_light then 'black' else 'white'

            padding: '4px 8px'
            borderRadius: 8
            cursor: 'pointer'
          onClick: enter_edit
          onKeyDown: (e) =>
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              enter_edit(e)  
              e.preventDefault()

          translator 'forum.edit_button', 'Edit Forum'
    else 
      DIV 
        style: 
          position: 'fixed'
          left: "50%"
          marginLeft: -80 - 8*2
          top: 0
          padding: "4px 8px"
          zIndex: 99999999999
          backgroundColor: if !is_light then "rgba(0,0,0,.3)" else "rgba(255,255,255,.3)"

        DIV null,
          BUTTON 
            style: 
              backgroundColor: if is_light then "rgba(0,0,0,.8)" else "rgba(255,255,255,.8)"
              color: if !is_light then 'black' else 'white'
              border: 'none'
              borderRadius: 8
              padding: '4px 8px'
            onClick: exit_edit
            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                exit_edit(e)  
                e.preventDefault()

            translator 'shared.done_editing', 'Done Editing Forum'


          if subdomain.errors?.length > 0
            DIV 
              style: 
                borderRadius: 8
                margin: 20
                padding: 20
                backgroundColor: '#FFE2E2'

              H1 style: {fontSize: 18}, 'Ooops!'

              for error in subdomain.errors
                DIV 
                  style: 
                    marginTop: 10
                  error

