
window.stop_editing_forum = ->
  edit_forum = fetch 'edit_forum'  
  for key in Object.keys(edit_forum) when key != 'key'
    delete edit_forum[key]
  save edit_forum


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


    is_light = is_light_background()

    if !edit_forum.editing

      DIV 
        style: 
          position: 'fixed'
          left: "50%"
          top: 8
          zIndex: 99999
          marginLeft: -142

        BUTTON
          style: 
            border: 'none'

            backgroundColor: if is_light then "rgba(0,0,0,.9)" else "rgba(220, 220, 220, 0.9)"
            color: if !is_light then 'black' else 'white'

            padding: '4px 8px'
            borderRadius: 8
            cursor: 'pointer'
          onClick: enter_edit
          onKeyDown: (e) =>
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              enter_edit(e)  
              e.preventDefault()

          translator 'forum.edit_button', 'Edit Banner & Forum Structure'
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
            onClick: stop_editing_forum
            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                stop_editing_forum()  
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

