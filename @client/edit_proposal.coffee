window.EditProposal = ReactiveComponent
  displayName: 'EditProposal'

  render : ->
    current_user = fetch('/current_user')
    proposal = @data()
    subdomain = fetch '/subdomain'

    # defaultValue for React forms conflicts with statebus's method of 
    # just rerunning until things work. Namely, the default value
    # that is set before the proposal is loaded entirely sticks
    # even after the proposal is fully loaded from the server.
    # This code works around that problem by simply exiting the 
    # render if the proposal isn't loaded already. 
    if !@props.fresh && !proposal.id
      return SPAN null
    
    # check permissions
    permitted = if @props.fresh  
                  permit('create proposal')
                else
                  permit('update proposal', proposal)

    if permitted < 0
      recourse permitted, 'To participate,'
      return DIV null

    block_style = 
      width: CONTENT_WIDTH()
      padding: '2px 0px'
      marginBottom: 12
      position: 'relative'

    description_field_style =
      fontSize: 18
      width: CONTENT_WIDTH()
      padding: 12
      marginBottom: 8
      border: '1px solid #ccc'

    input_style = _.extend {}, description_field_style, 
      display: 'block'

    label_style =
      fontSize: 24
      fontWeight: 600
      width: 240
      display: 'inline-block'
      color: focus_color()
      marginBottom: 3

    operation_style = 
      color: '#aaa'
      textDecoration: 'underline'
      fontSize: 14
      cursor: 'pointer'
      display: 'block'    
      backgroundColor: 'transparent'
      padding: 0
      border: 'none'  


    if @props.fresh 
      loc = fetch 'location'
      category = loc.query_params.category or ''
    else 
      category = proposal.cluster 


    available_lists = lists_current_user_can_add_to get_all_lists()
    
    DIV null, 
      DIV 
        style: 
          width: CONTENT_WIDTH()
          margin: 'auto'
          padding: '3em 0'
          position: 'relative'

        DIV 
          style: 
            fontSize: 28
            marginBottom: 20

          H2
            style: 
              fontSize: 30
              fontWeight: 700

            if @props.fresh 
              translator 'engage.add_new_proposal_button', "Create new proposal"
            else 
              "#{capitalize(translator('engage.edit_button', 'edit'))} '#{proposal.name}'"

        DIV style: block_style,
          LABEL 
            htmlFor:'name'
            style: label_style
            translator("engage.edit_proposal.summary_label", "Summary") + ':'
          INPUT 
            id:'name'
            name:'name'
            pattern:'^.{3,}'
            placeholder: translator 'engage.proposal_name_placeholder', 'Clear and concise summary'
            required:'required'
            defaultValue: if @props.fresh then null else proposal.name
            style: input_style

        DIV style: block_style,
          LABEL 
            htmlFor:"description-#{proposal.key}"
            style: label_style
            translator("engage.edit_proposal.description_label", "Details") + ':'
          
          WysiwygEditor
            key:"description-#{proposal.key}"
            style: _.extend {}, input_style,
              minHeight: 20
            html: if @props.fresh then null else proposal.description

        DIV
          style: block_style

          LABEL 
            htmlFor:'category'
            style: label_style
            translator('category') + ' [' + translator('optional') + ']:'
          

          SELECT
            ref: 'category'
            id: "category"
            name: "category"
            style: 
              fontSize: 18
            defaultValue: category
            onChange: (e) => 
              @local.category = e.target.value
              save @local

            [
              if current_user.is_admin

                [
                  OPTION 
                    style: 
                      fontStyle: 'italic'
                    value: 'new category'
                    'Create new category'

                  OPTION 
                    disabled: "disabled"
                    '--------'
                ]

              for list_key in available_lists
                OPTION  
                  value: list_key.substring(5)
                  get_list_title list_key, true 

            ]

          if current_user.is_admin && @local.category == 'new category'
            INPUT 
              type: 'text'
              ref: 'new_category'
              style: 
                fontSize: 16
                padding: '4px 6px'
                #marginLeft: 4
                marginTop: 4
                display: 'block'



        DIV 
          style: _.extend {}, block_style,
            display: if !current_user.is_admin then 'none'

          LABEL 
            htmlFor: 'listed_on_homepage'
            style: label_style
            translator "engage.edit_proposal.show_on_homepage", 'List on homepage?'

          INPUT 
            id: 'listed_on_homepage'
            name: 'listed_on_homepage'
            type: 'checkbox'
            defaultChecked: if @props.fresh then true else !proposal.hide_on_homepage
            style: 
              fontSize: 24

        DIV
          style: _.extend {}, block_style,
            display: if !current_user.is_admin then 'none'

          LABEL 
            htmlFor: 'open_for_discussion'
            style: label_style
            translator "engage.edit_proposal.open_for_discussion", 'Open for discussion?'

          INPUT 
            id: 'open_for_discussion'
            name: 'open_for_discussion'
            type: 'checkbox'
            defaultChecked: if @props.fresh then true else proposal.active
            style: {fontSize: 24}

        
        if current_user.is_admin 
          FORM 
            id: 'proposal_pic_files'
            action: '/update_proposal_pic_hack'

            DIV 
              className: 'input_group'
              style: block_style

              DIV null, 
                LABEL 
                  style: label_style
                  htmlFor: 'pic'
                  'Pic'
              INPUT 
                id: 'pic'
                type: 'file'
                name: 'pic'
                onChange: (ev) =>
                  @submit_pic = true

            DIV 
              className: 'input_group'
              style: block_style

              DIV null, 
                LABEL 
                  style: label_style
                  htmlFor: 'banner'
                  'Banner'
              INPUT 
                id: 'banner'
                type: 'file'
                name: 'banner'
                onChange: (ev) =>
                  @submit_pic = true

        if @local.errors?.length > 0
          
          DIV
            role: 'alert'
            style:
              fontSize: 18
              color: 'darkred'
              backgroundColor: '#ffD8D8'
              padding: 10
              marginTop: 10
            for error in @local.errors
              DIV null, 
                I
                  className: 'fa fa-exclamation-circle'
                  style: {paddingRight: 9}

                SPAN null, error


        DIV null,
          BUTTON 
            className:'button primary_button'
            style: 
              width: 400
              marginTop: 35
              backgroundColor: focus_color()              
            onClick: @saveProposal

            if @props.fresh 
              translator 'Publish'
            else 
              translator 'Update'

          BUTTON
            style: 
              marginTop: 10
              padding: 25
              marginLeft: 10
              fontSize: 22
              border: 'none'
              backgroundColor: 'transparent'

            onClick: =>
              if @props.fresh 
                loadPage "/"
              else 
                loadPage "/#{proposal.slug}"

            translator 'engage.cancel_button', 'cancel'

        if @local.file_errors
          DIV style: {color: 'red'}, 'Error uploading files!'


  saveProposal : -> 
    current_user = fetch '/current_user'
    
    name = document.getElementById("name").value 
    description = fetch("description-#{@data().key}").html

    category = @refs.category.getDOMNode().value
    if current_user.is_admin && category == 'new category'
      category = @refs.new_category.getDOMNode().value    
    category = null if category == ''

    active = document.getElementById('open_for_discussion').checked
    hide_on_homepage = !document.getElementById('listed_on_homepage').checked

    if @props.fresh
      proposal =
        key : '/new/proposal'
        name : name
        description : description
        cluster: category
        active: active
        hide_on_homepage: hide_on_homepage

    else 
      proposal = @data()
      _.extend proposal, 
        cluster: category
        name: name
        description: description
        active: active
        hide_on_homepage: hide_on_homepage

    if @local.roles
      proposal.roles = @local.roles
      proposal.invitations = @local.invitations

    proposal.errors = []
    @local.errors = []
    save @local

    after_save = => 
      if proposal.errors?.length == 0
        window.scrollTo(0,0)
        loadPage "/#{proposal.slug}"
      else
        @local.errors = proposal.errors
        save @local


    save proposal, => 
      if @submit_pic
        current_user = fetch '/current_user'
        form_to_upload = document.getElementById('proposal_pic_files')
        ajax_submit_files_in_form
          form: '#proposal_pic_files'
          type: 'PUT'
          additional_data: 
            authenticity_token: current_user.csrf
            id: proposal.id
          success: after_save
          error: => 
            @local.file_errors = true
            save @local
      else 
        after_save()
