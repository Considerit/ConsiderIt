require '../browser_hacks'
require '../auth/auth'
require './translations'

window.styles += """
  #EDITPROFILE label.AUTH_field_label {
    color: #8F8F8F;
    text-transform: uppercase;
    margin-bottom: 2px;
    margin-top: 8px;
  }
  #EDITPROFILE input.AUTH_text_input {
    display: block;
    margin-bottom: 16px;
  }

  #EDITPROFILE #SHOWHOSTQUESTIONS {
    padding: 12px 0 0 33px;
    background-color: transparent;
  }

  @media #{PHONE_MEDIA} {
    #EDITPROFILE #SHOWHOSTQUESTIONS {
      padding: 0 18px;
    }    
  }
"""


window.EditProfile = ReactiveComponent
  displayName: 'EditProfile'
  mixins: [AuthForm]

  render: -> 
    current_user = bus_fetch '/current_user'
    i18n = @i18n()

    is_SSO = bus_fetch('/subdomain').SSO_domain  

    if @local.saved_successfully && is_SSO
      loadPage '/'

    on_submit = (ev) =>
      @Submit ev, 
        action: 'edit profile'
        has_host_questions: true
        has_avatar_upload: true

    DIV 
      id: 'EDITPROFILE'

      # Single Sign On users can't change email or password
      if !is_SSO 
        [
          @RenderInput 
            type: 'email'
            name: 'email'
            label: i18n.email_label
            on_submit: on_submit
          @RenderInput 
            type: 'password'
            name: 'password'
            label: i18n.new_password_label
            on_submit: on_submit  

          if @local.updates.password != current_user.password || @local.updates.email != current_user.email
            @RenderInput   
              type: 'password'
              name: 'old_password'
              label: i18n.old_password_label
              on_submit: on_submit  
              
        ]

      @RenderInput
        name: 'name' 
        label: i18n.name_label
        on_submit: on_submit

      DIV 
        className: 'AUTH_field_wrapper'
        style: 
          marginBottom: 8

        LABEL 
          className: 'AUTH_field_label'
          i18n.pic_prompt

        AvatarInput()

      if forum_has_host_questions()
        DIV 
          style: 
            backgroundColor: considerit_gray
            marginBottom: 24
            marginTop: 52

          H4 
            style: 
              marginBottom: 12
              padding: '24px 36px 8px 36px'
              fontSize: 22
              fontWeight: 400

            translator 'auth.additional_info.heading', 'Questions from your host'

          ShowHostQuestions
            disable_unchecking_required_booleans: true

      BUTTON 
        className: "btn #{if @local.submitting then 'disabled' else ''}"
        onClick: on_submit

        translator 'shared.save_changes_button', 'Save changes'

      if @local.saved_successfully
        DIV 
          style: 
            backgroundColor: 'white'
            color: '#888'
          i18n.successful_update

      @ShowErrors()


      DIV 
        style: 
          marginTop: 80

        FORM 
          id: 'delete_account_form'
          

          INPUT
            type: 'submit' 
            value: translator 'auth.delete_account', 'Delete your account'
            # className: 'like_link'
            style: 
              color: '#b74e4e'
              fontWeight: 600
              padding: '10px 18px'
              borderRadius: 8
              border: 'none'
              backgroundColor: '#efefef'
              boxShadow: '0 1px 2px rgba(0,0,0,.2)'

            onClick: (ev) =>
              ev.preventDefault()

              if confirm translator 'auth.delete_account_confirmation', "We're sorry to see you go! Just to check first, though: this will irreversibly delete your account and any material you have contributed to this or any other Consider.it forums with be removed or anonymized. Do you still want to proceed?"
                error_msg = "Something went wrong trying to delete your account. Please contact help@consider.it and we'll get it done. If you've created a Consider.it forum in the past, that is the most likely cause."
                
                ajax_submit_files_in_form
                  uri: '/current_user'
                  type: 'delete'
                  form: '#delete_account_form'
                  additional_data: 
                    authenticity_token: arest.csrf()

                  success: (resp) =>
                    if resp.length > 0 && JSON.parse(resp)?.error?
                      @local.errors = [translator('auth.delete_account_contact_us', error_msg)]
                      save @local
                    else 
                      window.location.href = location.origin

                  error: (results) => 
                    @local.errors = [translator('auth.delete_account_contact_us', error_msg)]
                    save @local 

        FORM 
          id: 'delete_data_form'
          

          INPUT
            type: 'submit' 
            value: translator 'auth.delete_data', 'Delete your data on this forum'
            # className: 'like_link'
            style: 
              marginTop: 18
              color: '#b74e4e'
              fontWeight: 600
              padding: '10px 18px'
              borderRadius: 8
              border: 'none'
              backgroundColor: '#efefef'
              boxShadow: '0 1px 2px rgba(0,0,0,.2)'

            onClick: (ev) =>
              ev.preventDefault()

              if confirm translator 'auth.delete_data_confirmation', "Your opinions, comments, and other data associated with this forum will be irreversibly deleted or anonymized. Your Consider.it account will remain active. Do you still want to proceed?"
                error_msg = "Something went wrong trying to delete your data. Please contact help@consider.it and we'll get it done."
                
                ajax_submit_files_in_form
                  uri: '/delete_data_for_forum'
                  type: 'delete'
                  form: '#delete_data_form'
                  additional_data: 
                    authenticity_token: arest.csrf()

                  success: (resp) =>
                    if resp.length > 0 && JSON.parse(resp)?.error?
                      @local.errors = [translator('auth.delete_data_contact_us', error_msg)]
                      save @local
                    else 
                      window.location.href = location.origin

                  error: (results) => 
                    @local.errors = [translator('auth.delete_data_contact_us', error_msg)]
                    save @local 



      DIV 
        style: 
          marginTop: 36

        TRANSLATE
          id: 'contact.about_data_export'
          LINK: 
            component: A 
            args: 
              href: 'mailto:help@consider.it'
              treat_as_external_link: true

          "Please contact us at <LINK>help@consider.it</LINK> if you would like an export of your data from this forum."

            







  