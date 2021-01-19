require '../auth'



# merge this with other definition when code gets refactored with styles 
# declared with window.styles
section_heading_style =             
  color: '#222'
  fontSize: 18
  display: 'block'
  fontWeight: 700

window.EditProfile = ReactiveComponent
  displayName: 'EditProfile'
  render: -> 
    #####
    # if these are changed, make sure it is changed in auth.coffee too
    name_label = translator('auth.create.name_label', 'Your name')
    email_label = translator('auth.login.email_label', 'Your email')
    password_label = translator('auth.login.password_label', 'Your password')
    password_placeholder = translator('auth.login.password.placeholder', 'password')
    pic_prompt = translator('auth.create.pic_prompt', 'Your picture')
    full_name_placeholder = translator('auth.create.full_name.placeholder', 'first and last name or pseudonym')
    code_label = translator('auth.code_entry', 'Code')
    code_placeholder = translator('auth.code_entry.placeholder', 'verification code from email')
    #####

    is_SSO = fetch('/subdomain').SSO_domain  

    avatar_field = AvatarInput()
    if avatar_field
      avatar_field = [pic_prompt, avatar_field]


    render_field = (label, render, label_style) -> 
      field_id = render?.props?.id or render?[0]?.props?.id
      if field_id 
        field_id = field_id.replace('user_avatar_form', 'user_avatar')

      label_style ||= section_heading_style

      DIV 
        style: 
          marginBottom: 8

        LABEL
          htmlFor: field_id
          style: section_heading_style
          label

        render

    DIV null, 

      # we don't want users on single sign on subdomains to change email/password
      if !is_SSO  
        render_field email_label, @inputBox('email', 'email@address.com', 'email')
      if !is_SSO
        render_field password_label, @inputBox('password', password_label, 'password')

      render_field name_label, @inputBox('name', full_name_placeholder)
      render_field avatar_field[0], avatar_field[1]

      ShowHostQuestions()






  ####
  # inputBox
  #
  # Renders an input form element for modifying current_user.
  #
  # name: the name of the field being modified
  # placeholder: text for html5 field placeholder
  # type: input type; text, email or password
  # onChange: optional callback for when text is typed
  # pattern: html5 constraints on values
  #
  inputBox : (name, placeholder, type, onChange, pattern) ->
    current_user = fetch('/current_user')
    auth = fetch('auth')

    if !onChange
      onChange = (event) =>
        if type == 'email'
          @local[name] = current_user[name] = (event.target.value).trim()
        else 
          @local[name] = current_user[name] = event.target.value

        save @local

    if @local[name] != current_user[name]
      @local[name] = current_user[name]
      save @local
      return SPAN null

    # There is a react bug where input cursor will jump to end for
    # controlled components. http://searler.github.io/react.js/2014/04/11/React-controlled-text.html
    # This makes it annoying to edit text. I've contained this issue to edit_profile only
    # by only setting value in the Input component when in edit_profile mode

    INPUT
      id: 'user_' + name
      className: 'auth_text_input'
      style:
        marginBottom: 6
        width: '100%'
        border: "1px solid #ccc"
        padding: '10px 14px'
        fontSize: if browser.is_mobile then 36 else 20
        display: 'inline-block'
        backgroundColor: '#f2f2f2'
      value: if auth.form in ['edit profile'] then @local[name] else null
      name: "user[#{name}]"
      key: "#{name}_inputBox"
      #placeholder: placeholder
      'aria-label': if name == 'password' then placeholder
      required: "required"
      type: type || 'text'
      onChange: onChange
      onKeyPress: (event) =>
        # submit on enter
        if event.which == 13
          @submitAuth(event)
      pattern: pattern
      autoComplete: if name == 'verification_code' || auth.form in ['edit profile'] then 'off'
