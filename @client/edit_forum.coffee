
window.stop_editing_forum = ->
  edit_forum = bus_fetch 'edit_forum'  
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

    subdomain = bus_fetch '/subdomain'
    current_user = bus_fetch '/current_user'
    edit_forum = bus_fetch 'edit_forum'

    if !current_user.is_admin
      return DIV null 

    enter_edit = (e) ->
      edit_forum.editing = true 
      save edit_forum


    is_light = is_light_background()

    show_dash_modal = bus_fetch 'show_dash_modal'
    return SPAN null if show_dash_modal.showing

    if !edit_forum.editing

      DIV 
        style: 
          position: 'absolute'
          left: if TABLET_SIZE() then 24 else "50%"
          top: 17
          zIndex: 99999
          marginLeft: if !TABLET_SIZE() then -152

        BUTTON 

          onClick: enter_edit

          if PHONE_SIZE()
            translator 'forum.edit_button_short', 'Edit Banner'
          else 
            translator 'forum.edit_button', 'Edit Banner & Forum Structure'

    else 
      DIV null,
        BUTTON 
          style: 
            boxShadow: '0 1px 2px rgba(0,0,0,.5)'
          onClick: stop_editing_forum

          translator 'shared.done_editing', 'Done Editing Forum'

        if subdomain.errors?.length > 0
          ErrorBlock subdomain.errors, 
            style: 
              marginBottom: 10
              marginLeft: 20 


