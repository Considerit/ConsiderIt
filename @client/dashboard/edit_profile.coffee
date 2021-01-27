require '../browser_hacks'
require '../auth/auth'
require './translations'

window.styles += """
  #EDITPROFILE label.AUTH_field_label {
    color: #8F8F8F;
    font-size: 12px; 
    text-transform: uppercase;
  }
  #EDITPROFILE input.AUTH_text_input {
    display: block;
    margin-bottom: 6px;
    width: 350px;
    border: 1px solid #ccc;
    padding: 10px 14px;
    font-size: #{if browser.is_mobile then 36 else 20}px;
    background-color: #f2f2f2;    
  }
"""


window.EditProfile = ReactiveComponent
  displayName: 'EditProfile'
  mixins: [AuthForm]

  render: -> 

    i18n = auth_translations()

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

      ShowHostQuestions()

      BUTTON 
        className: "#{if @local.submitting then 'disabled' else ''}"
        onKeyPress: (event) =>
          # submit on enter
          if event.which == 13 # enter
            on_submit(event)
        onClick: on_submit

        #TODO: translate
        'Save changes'

      if @local.saved_successfully
        DIV 
          style: 
            backgroundColor: 'white'
            color: '#888'
          i18n.successful_update

      @ShowErrors()







  