require '../browser_hacks'
require '../auth/auth'
require './translations'

window.styles += """
  #EDITPROFILE label.AUTH_field_label {
    color: #8F8F8F;
    text-transform: uppercase;
    margin-bottom: 2px;
    margin-top: 4px;
  }
  #EDITPROFILE input.AUTH_text_input {
    display: block;
    margin-bottom: 6px;
  }

  #EDITPROFILE #SHOWHOSTQUESTIONS {
    padding: 12px 0 0 33px;
    background-color: transparent;
  }
"""


window.EditProfile = ReactiveComponent
  displayName: 'EditProfile'
  mixins: [AuthForm]

  render: -> 

    i18n = @i18n()

    is_SSO = fetch('/subdomain').SSO_domain  

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
            label: i18n.password_label
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
            marginTop: 12

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
        onKeyPress: (event) =>
          # submit on enter
          if event.which == 13 # enter
            on_submit(event)
        onClick: on_submit

        translator 'shared.save_changes_button', 'Save changes'

      if @local.saved_successfully
        DIV 
          style: 
            backgroundColor: 'white'
            color: '#888'
          i18n.successful_update

      @ShowErrors()







  