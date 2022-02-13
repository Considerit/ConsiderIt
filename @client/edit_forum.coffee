



# Various components have local control over editing their respective part of the customizations state. 
# before_save_callback for each registered controller should just update the passed customizations object,
# not save it. The cleanup_callback is called after all controllers have had a chance to add their changes. 
# image_save_callback is for those controllers who need to submit files to the server. If there exists at 
# least one image_save_callback, the page is reloaded after all image save callbacks have returned. 
__forum_editing_handlers = {}
window.register_forum_editing_handler = (name, {before_save_callback, cleanup_callback, image_save_callback, has_files_to_submit}) ->
  if name not of __forum_editing_handlers   
    __forum_editing_handlers[name] = {before_save_callback, cleanup_callback, image_save_callback, has_files_to_submit}

window.clear_forum_editing_handler = (name) ->
  if name of __forum_editing_handlers
    delete __forum_editing_handlers[name]



window.EditForum = ReactiveComponent
  displayName: 'EditForum'

  submit: -> 
    subdomain = fetch '/subdomain'
    customizations = subdomain.customizations
    edit_forum = fetch 'edit_forum'


    # Deleting lists is fraught because they might have proposals in them. 
    # We need to figure out which lists are actually being deleted, vs 
    # just moved around.  
    if edit_forum.deleted_lists
      deleting_lists_with_proposals = false 

      for page, deletions of edit_forum.deleted_lists
        
        for list_key, __ of deletions

          # if the list has just been moved to another page, no problem
          in_some_other_page = false 
          for  pg, lists of edit_forum.list_order
            in_some_other_page ||= lists.indexOf(list_key) > -1

          if !in_some_other_page
            deleting_lists_with_proposals ||= get_proposals_in_list(list_key)?.length > 0
          
      if deleting_lists_with_proposals
        if !confirm(translator('engage.list-config-save-all-delete-confirm', 'You\'ve made changes that will result in one or more lists that contain proposals to be deleted. Those proposals will be lost forever. Are you sure you want to proceed?'))
          for key in Object.keys(edit_forum) when key != 'key'
            delete edit_forum[key]
          save edit_forum
          return

      for page, deletions of edit_forum.deleted_lists        
        for list_key, __ of deletions
          delete_list list_key, page, true


    # each registered forum editing handler gets a turn at updating the customizations object
    for name, {before_save_callback} of __forum_editing_handlers
      before_save_callback?(customizations)

    save subdomain, => 
      if subdomain.errors?.length > 0 
        return 

      # are there any image_save_callbacks?
      # NOTE: we only want to call the image_save_callback if it wants to submit!
      image_cbs = (v.image_save_callback for k,v of __forum_editing_handlers when v.has_files_to_submit?())
      if image_cbs.length > 0
        image_cbs_returned = 0
        for image_cb in image_cbs
          image_cb (successful) ->
            image_cbs_returned += 1 if successful
            if image_cbs_returned == image_cbs.length
              location.reload()
      else
        for name, {cleanup_callback} of __forum_editing_handlers
          cleanup_callback?()
        for key in Object.keys(edit_forum) when key != 'key'
          delete edit_forum[key]
        save edit_forum




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

          translator 'forum.edit_button', 'edit forum'
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
            onClick: @submit
            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                @submit(e)  
                e.preventDefault()

            translator 'shared.save_changes_button', 'Save changes'

          BUTTON
            style: 
              backgroundColor: 'transparent'
              border: 'none'
              textDecoration: 'underline'
              color: if is_light then 'black' else 'white'
            onClick: exit_edit
            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                exit_edit(e)  
                e.preventDefault()

            translator 'shared.cancel_button', 'cancel'


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

