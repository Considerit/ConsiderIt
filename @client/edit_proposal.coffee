

styles += """
  [data-widget="EditProposal"] #modal-body {

  }

  [data-widget="EditProposal"] input:checked + .toggle_switch_circle {
    background-color: #{focus_blue};
  }

  [data-widget="EditProposal"] label:not(.toggle_switch):not(.toggle_label){
    font-size: 20px;
    font-weight: 600;
    padding-right: 24px;
    display: inline-block;
    color: #{focus_blue};
    margin-bottom: 3px;
    text-transform: capitalize;
  }

  [data-widget="EditProposal"] .toggle_label {
    padding-left: 18px;
    color: #{focus_blue};
    font-weight: 600;
    font-size: 18px;
  }

  [data-widget="EditProposal"] .block{
    padding: 2px 0;
    margin-bottom: 24px;
    position: relative;
  }

  [data-widget="EditProposal"] form {
    margin-top: 8px;
  }
"""





window.EditProposal = ReactiveComponent
  displayName: 'EditProposal'
  mixins: [Modal]

  render : ->
    current_user = fetch('/current_user')
    proposal = fetch @props.proposal
    subdomain = fetch '/subdomain'
    
    # check permissions
    permitted = if @props.fresh  
                  permit('create proposal')
                else
                  permit('update proposal', proposal)

    if permitted < 0
      recourse permitted, 'To participate,'
      return DIV null

    description_field_style =
      fontSize: 18
      width: '100%'
      padding: 12
      marginBottom: 8
      border: '1px solid #ccc'

    input_style = _.extend {}, description_field_style, 
      display: 'block'


    operation_style = 
      color: '#aaa'
      textDecoration: 'underline'
      fontSize: 14
      cursor: 'pointer'
      display: 'block'    
      backgroundColor: 'transparent'
      padding: 0
      border: 'none'  

    explanation_style = 
      fontSize: 16
      color: '#333'
      marginBottom: 6


    if @props.fresh 
      loc = fetch 'location'
      category = loc.query_params.category or ''
    else 
      category = proposal.cluster 


    available_lists = lists_current_user_can_add_to get_all_lists()



    local = @local

    wrap_in_modal HOMEPAGE_WIDTH(), @props.done_callback, DIV null,


      DIV 
        style: 
          position: 'relative'

        DIV 
          className: 'block'
          LABEL 
            htmlFor:'name'
            translator("engage.edit_proposal.summary_label", "Summary")
          INPUT 
            id:'name'
            name:'name'
            pattern:'^.{3,}'
            placeholder: translator 'engage.proposal_name_placeholder', 'Clear and concise summary'
            required:'required'
            defaultValue: if @props.fresh then null else proposal.name
            style: input_style

        DIV
          className: 'block'        
          LABEL 
            htmlFor:"description-#{proposal.key}"
            translator("engage.edit_proposal.description_label", "Details")
          
          WysiwygEditor
            editor_key:"description-#{proposal.key}"
            style: _.extend {}, input_style,
              minHeight: 20
            html: if @props.fresh then null else proposal.description

        DIV
          className: 'block'

          LABEL 
            htmlFor:'category'
            translator 'category'


          SELECT
            ref: 'category'
            id: "category"
            name: "category"
            style: 
              fontSize: 16
              maxWidth: '100%'
            defaultValue: category
            onChange: (e) => 
              @local.category = e.target.value
              save @local

            [
              if current_user.is_admin

                [
                  OPTION 
                    key: 'new-cat'
                    style: 
                      fontStyle: 'italic'
                    value: 'new category'
                    'Create new category'

                  OPTION 
                    key: 'nothing'
                    disabled: "disabled"
                    '--------'
                ]

              for list_key in available_lists
                OPTION 
                  key: list_key 
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



        # DIV 
        #   style: _.extend {}, block_style,
        #     display: if !current_user.is_admin then 'none'

        #   LABEL 
        #     htmlFor: 'listed_on_homepage'
        #     translator "engage.edit_proposal.show_on_homepage", 'List on homepage?'

        #   INPUT 
        #     id: 'listed_on_homepage'
        #     name: 'listed_on_homepage'
        #     type: 'checkbox'
        #     defaultChecked: if @props.fresh then true else !proposal.hide_on_homepage
        #     style: 
        #       fontSize: 24

        DIV
          className: 'block'        
          style:
            display: if !current_user.is_admin then 'none' else 'flex'
            alignItems: 'center'

          LABEL 
            className: 'toggle_switch'

            INPUT 
              id: 'open_for_discussion'
              name: 'open_for_discussion'
              type: 'checkbox'
              defaultChecked: if @props.fresh then true else proposal.active

            SPAN 
              className: 'toggle_switch_circle'

          LABEL 
            className: 'toggle_label'
            htmlFor: 'open_for_discussion'
            translator "engage.edit_proposal.open_for_discussion", 'Open for discussion'
        


        if current_user.is_admin 
          FORM 
            id: 'proposal_pic_files'
            action: '/update_proposal_pic_hack'

            DIV 
              className: 'input_group block'

              DIV null, 
                LABEL 
                  htmlFor: 'pic'
                  'Icon'

                DIV 
                  style: explanation_style
                  "A custom icon to associate with this proposal, rather than the author's avatar."


              INPUT 
                id: 'pic'
                type: 'file'
                name: 'pic'
                accept: "image/jpg, image/jpeg, image/pjpeg, image/png, image/x-png, image/gif, image/webp"
                onChange: (ev) =>
                  @submit_pic = true

            DIV 
              className: 'input_group block'

              DIV null, 
                LABEL 
                  htmlFor: 'banner'
                  'Banner'

                DIV 
                  style: explanation_style
                  "A background image shown at the top of this proposal's page."


              INPUT 
                id: 'banner'
                type: 'file'
                name: 'banner'
                accept: "image/jpg, image/jpeg, image/pjpeg, image/png, image/x-png, image/gif, image/webp"
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
            className: 'btn'
            style: 
              marginTop: 35
            onClick: @saveProposal

            if @props.fresh 
              translator 'Publish'
            else 
              translator 'Update'

          BUTTON
            className: 'like_link'
            style: 
              fontSize: 20
              color: '#777'
              position: 'relative'
              top: 20
              marginLeft: 12

            onClick: @props.done_callback

            translator 'shared.cancel_button', 'cancel'

        if @local.file_errors
          DIV style: {color: 'red'}, 'Error uploading files!'


  saveProposal : -> 
    current_user = fetch '/current_user'
    proposal = fetch @props.proposal
    
    name = document.getElementById("name").value 
    description = fetch("description-#{proposal.key}").html

    category = @refs.category.value
    if current_user.is_admin && category == 'new category'
      category = @refs.new_category.value    
    category = null if category == ''

    active = document.getElementById('open_for_discussion').checked
    # hide_on_homepage = !document.getElementById('listed_on_homepage').checked

    if @props.fresh
      proposal =
        key : '/new/proposal'
        name : name
        description : description
        cluster: category
        active: active
        # hide_on_homepage: hide_on_homepage

    else 
      _.extend proposal, 
        cluster: category
        name: name
        description: description
        active: active
        # hide_on_homepage: hide_on_homepage


    # Editing the proposal shouldn't mess with the current roles
    # This is sloppy, but can lead to permission problems if we don't. 
    if proposal.roles
      InitializeProposalRoles proposal

    proposal.errors = []
    @local.errors = []
    save @local

    after_save = => 
      if proposal.errors?.length == 0
        @props.done_callback()
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
