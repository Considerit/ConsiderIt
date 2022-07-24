
window.stop_editing_forum = ->
  edit_forum = fetch 'edit_forum'  
  for key in Object.keys(edit_forum) when key != 'key'
    delete edit_forum[key]
  save edit_forum


styles += """
  [data-widget="EditForum"] button {
    border: none;
    background-color: #{selected_color}; 
    color: white; 
    font-weight: 700;
    padding: 10px 22px; 
    border-radius: 8px;
    cursor: pointer;
    box-shadow: 0 1px 2px rgba(0,0,0,.4);
  }

"""

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

    show_dash_modal = fetch 'show_dash_modal'
    return SPAN null if show_dash_modal.showing

    if !edit_forum.editing

      DIV 
        style: 
          position: 'absolute'
          left: "50%"
          top: 8
          zIndex: 99999
          marginLeft: -152

        BUTTON 

          onClick: enter_edit

          translator 'forum.edit_button', 'Edit Banner & Forum Structure'
    else 

      DIV null,
        BUTTON 
          style: 
            boxShadow: '0 1px 2px rgba(0,0,0,.5)'
          onClick: stop_editing_forum

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

