##################
# Auth
#
# There are a number of forms that are displayed via the Auth component:
# - login
# - create account
# - create account via invitation (with fixed email address)
# - reset password
# - verify email
# - edit profile
# - user questions
#
# Each of these screens has some differences. We try to keep these differences
# clearly documented in the render method so that the method doesn't get
# too complicated to understand and modify.

#require './vendor/jquery.form'
require './browser_location' # for loadPage
require './bubblemouth'
require './customizations'
require './shared'


window.logout = -> 
  current_user = fetch('/current_user')
  current_user.logged_in = false
  current_user.trying_to = 'logout'

  auth = fetch 'auth'

  if auth.form && auth.form in ['edit profile']
    loadPage '/'

  reset_key auth

  save current_user, =>
    # We need to get a fresh your_opinion object
    # after logging out. 

    # TODO: the server should dirty keys on the client when the
    # current_user logs out
    #arest.clear_matching_objects((key) -> key.match( /\/page\// ))
    location.reload()


window.auth_ghost_gray = '#a1a1a1' # the gray color for ghost text
window.auth_text_gray = '#444'    # the gray color for solid text


Auth = ReactiveComponent
  displayName: 'Auth'

  render: ->
    current_user = fetch('/current_user')
    auth = fetch('auth')

    # When we switch to new auth_mode screens, wipe out all the old
    # errors, cause we're startin' fresh!
    if not @local.last_auth or @local.auth != auth.auth
      @local.last_auth = auth
      current_user.errors = []
      @local.errors = []
      save @local
      return SPAN null

    return SPAN null if !auth.form

    DIV 
      style: 
        background: if auth.form != 'edit profile' && !@props.naked then (customization('background') or focus_color())

      if auth.form != 'edit profile' && !@props.naked
        A 
          href: 'https://consider.it'
          target: '_blank' 
          style: 
            position: 'absolute'
            left: 10
            top: 10

          drawLogo 
            height: 35
            main_text_color: 'white'
            o_text_color: 'white'
            clip: false
            draw_line: true 
            line_color: 'white'
            transition: true


      DIV
        style:
          margin: "0 auto"
          padding: if !@props.naked then '4em 0'
          position: 'relative'
          zIndex: 0
          width: AUTH_WIDTH()
          

        @buildAuthForm()

  ####
  # buildAuthForm
  #
  # Constructs the correct form given the desired mode.
  # Builds the form from input and section components
  # defined further down the file. Intended to be as
  # declarative as possible for making clear definitions
  # of different auth modes.
  buildAuthForm : ->

    auth = fetch('auth')
    current_user = fetch('/current_user')
    subdomain = fetch '/subdomain'
    
    goal = null
    if auth.goal 
      goal = translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal

    verification_sent_message = translator('auth.verification_sent', 'We just emailed you a verification code. Copy / paste it below.')

    switch auth.form

      # The LOGIN form, with easy switch to register
      when 'login'
        [ @headerAndBorder goal, translator("auth.login.heading", 'Introduce Yourself'),
            @body()
        ]

      # The REGISTER form, with easy switch to log in
      #   ...or a slight variation for completing registration
      #      after invitation, where email is fixed and can't
      #      switch to log in.
      when 'create account', 'create account via invitation'
        
        [ @headerAndBorder goal, translator('auth.create.heading', 'Create an account'),
            @body()
        ]

      # The EDIT PROFILE form
      when 'edit profile'

        [ @headerAndBorder goal, translator("auth.update_profile.heading", "Update Your Profile"),
            @body()
          
          if @local.saved_successfully
            if subdomain.SSO_domain
              loadPage '/'
            DIV style: {textAlign: 'center', backgroundColor: 'white', color: '#888'}, translator("auth.successful_update", "Updated successfully")
        ]

      # The RESET PASSWORD form
      when 'reset password'
        [ @headerAndBorder null, translator("auth.reset_password.heading", 'Reset Your Password'),
            @body verification_sent_message

          DIV 
            style: 
              marginTop: 20
              color: 'white'
              textAlign: 'center'

            TRANSLATE 
              id: "auth.reset_password.help"
              link: 
                component: A
                args: 
                  target: '_blank'
                  href: 'https://vimeo.com/198802322'
                  style: 
                    textDecoration: 'underline'
                    fontWeight: 600

              'Having trouble resetting your password? Watch this brief <link>video tutorial</link>.'
        ]

      # The email VERIFICATION form
      when 'verify email'
        [ @headerAndBorder goal, translator('auth.verify_email.heading', 'Verify Your Email'),
            @body verification_sent_message
        ]

      when 'user questions'
        [ @headerAndBorder goal, translator('auth.more_info.heading', 'Your hosts request more info'),
            @body()
        ]

      else
        throw "Unrecognized authentication form #{auth.form}"


  #####
  # headerAndBorder
  #
  # Creates the header with bubble mouth and blue circle.
  # Also creates an enclosure with blue dashed boarder.
  #
  # goal: The reason this auth form is being shown
  # task: The label for this auth form
  # body: Child nodes that will be rendered inside
  #
  headerAndBorder : (goal, task, body) ->
    auth = fetch('auth')

    # if @props.naked
    #   return body

    if auth.form == 'login'      
      button = translator "auth.log_in", 'Log in'
    else 
      button = translator "auth.submit", 'Submit'


    DIV null,

      # The auth form's header
      DIV
        style :
          width: AUTH_WIDTH()
          position: 'relative'
          margin: 'auto'
          top: 5 # to overlap bubblemouth with enclosure
          

        DIV
          style:
            textAlign: 'center'
            position: 'relative'
            display: if @props.naked then 'none'

          if goal
            DIV
              style:
                fontWeight: 600
                fontSize: 18
                transform: 'translateY(6px)'
                color: 'white'
              goal
              
          H1
            style: 
              display: 'inline-block'
              position: 'relative'
              fontWeight: 'bold'
              fontSize: 48
              whiteSpace: 'nowrap'
              color: if auth.form != 'edit profile' then 'white'
              marginBottom: 10

            task



      DIV
        className: if @local.submitting then ' waiting' else ''
        style:
          padding: '2.5em 80px 1.5em 80px'
          fontSize: 18
          boxShadow: if auth.form != 'edit profile' then '0 2px 4px rgba(0,0,0,.4)'
          backgroundColor: 'white'
          position: 'relative'

        body

        @submitButton button, true

      @form_footer()







  ######
  # body
  #
  # Renders the main part of the auth form. Also
  # renders any user errors.
  #
  # additional_instructions: text rendered before
  #                          the fields
  body: (additional_instructions) ->
    auth = fetch('auth')

    current_user = fetch '/current_user'
    primary_color = @props.primary_color or focus_color()


    name_label = translator('auth.create.name_label', 'Your name')
    email_label = translator('auth.login.email_label', 'Your email')
    password_label = translator('auth.login.password_label', 'Your password')
    password_placeholder = translator('auth.login.password.placeholder', 'password')
    pic_prompt = translator('auth.create.pic_prompt', 'Your picture')
    full_name_placeholder = translator('auth.create.full_name.placeholder', 'first and last name or pseudonym')
    code_label = translator('auth.code_entry', 'Code')
    code_placeholder = translator('auth.code_entry.placeholder', 'verification code from email')


    section_heading_style =             
      color: '#888'
      fontSize: 24
      display: 'block'
      fontWeight: 700
      fontStyle: 'oblique'

    subsection_heading_style = 
      display: 'block'


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

    render_host_questions = =>
      host_questions = @userQuestionInputs()

      if host_questions.length > 0 

        host_framing = customization 'host_questions_framing'

        DIV
          style: 
            padding: "24px 24px"
            backgroundColor: "#eee"
            marginTop: 18
          
          H4
            style: _.extend {}, section_heading_style, 
              marginBottom: 18
            translator('auth.host_questions.heading', 'Questions from the forum host') 

          if host_framing 
            DIV 
              style: 
                fontSize: 14
                marginBottom: 12
              dangerouslySetInnerHTML: __html: host_framing


          UL 
            style: 
              padding: "6px 0px"
              listStyle: 'none'

            for [label, render] in host_questions
              field_id = render?.props?.id or render?[0]?.props?.id
              LI 
                style: 
                  marginBottom: 8

                LABEL
                  htmlFor: field_id
                  style: subsection_heading_style
                  label

                render


    DIV null,
      if additional_instructions
        DIV
          style:
            color: auth_text_gray
            marginBottom: 18
          additional_instructions



      switch auth.form

        # The LOGIN form, with easy switch to register
        when 'login'
          DIV null, 
            render_field "#{email_label}", @inputBox('email', 'email@address.com', 'email')
            render_field "#{password_label}", [@inputBox('password', password_placeholder, 'password'), @resetPasswordLink()]


        # The REGISTER form, with easy switch to log in
        #   ...or a slight variation for completing registration
        #      after invitation, where email is fixed and can't
        #      switch to log in.
        when 'create account', 'create account via invitation'
          
          if avatar_field = @avatarInput()
            avatar_field = [pic_prompt, avatar_field]


          if auth.form == 'create account'
            email_field = [email_label, @inputBox('email', 'email@address.com', 'email')]
          else
            email_field = [email_label, DIV style: {color: auth_text_gray, padding: '4px 8px'}, current_user.email]

          pledges = @getPledges()

          

          DIV null, 
            render_field email_field[0], email_field[1]
            render_field password_label, @inputBox('password', password_label, 'password')
            render_field name_label, @inputBox('name', full_name_placeholder)
            render_field avatar_field[0], avatar_field[1]


            render_host_questions()

            if pledges.length > 0 
            
              DIV
                style: 
                  marginTop: 18
                  padding: "24px 24px"
                  backgroundColor: "#eee"
                H4
                  style: _.extend {}, section_heading_style, 
                    marginBottom: 18
                  translator('auth.create.pledge_heading', 'Participation Pledge') 

                UL 
                  style: 
                    padding: "6px 0px"
                    listStyle: 'none'

                  for pledge, idx in pledges

                    LI
                      style: 
                        marginBottom: 8

                      INPUT
                        className:"pledge-input"
                        type:'checkbox'
                        id:"pledge-#{idx}"
                        name:"pledge-#{idx}"
                        style: 
                          fontSize: 24
                          verticalAlign: 'top'
                          marginLeft: 0

                      LABEL 
                        style: 
                          display: 'inline-block'
                          width: '90%'
                          paddingLeft: 8
                        htmlFor: "pledge-#{idx}"
                        dangerouslySetInnerHTML: __html: pledge


            

        # The EDIT PROFILE form
        when 'edit profile'
          avatar_field = @avatarInput()
          if avatar_field
            avatar_field = [pic_prompt, avatar_field]

          DIV null, 

            # we don't want users on single sign on subdomains to change email/password
            if !fetch('/subdomain').SSO_domain  
              render_field email_label, @inputBox('email', 'email@address.com', 'email')
            if !fetch('/subdomain').SSO_domain 
              render_field password_label, @inputBox('password', password_label, 'password')

            render_field name_label, @inputBox('name', full_name_placeholder)
            render_field avatar_field[0], avatar_field[1]

            render_host_questions()

        # The RESET PASSWORD form
        when 'reset password'

          DIV null, 

            render_field '', INPUT({name: 'user[verification_code]', disabled: true, style: {display: 'none'}} ) # prevent autofill of code with email address
            render_field '', INPUT({type: 'password', name: 'user[password]', disabled: true, style: {display: 'none'}} ) # prevent autofill of code with password
            render_field "#{code_label}:", @inputBox('verification_code', code_placeholder)
            render_field "#{translator('auth.reset_password.new_pass', 'New password')}:", @inputBox('password', translator('auth.reset_password.new_pass.placeholder', "choose a new password"), 'password')


        # The email VERIFICATION form
        when 'verify email'
          render_field "#{code_label}:", @inputBox('verification_code', code_placeholder)

        when 'user questions'
          render_host_questions()

        else
          throw "Unrecognized authentication form #{auth.form}"



      # Considerit terms
      if auth.form in ['create account', 'create account via invitation'] || (auth.form in ['user questions', 'edit profile'] && !@local.agreed_to_terms)

        if !@local.agreed_to_terms?
          @local.agreed_to_terms = !!current_user.tags['considerit_terms.editable']
          save @local 

        default_terms = TRANSLATE
          id: 'auth.create.agree_to_terms'
          as_html: true
          privacy_link: 
            component: "a"
            args: "href='/privacy_policy' style='text-decoration: underline'"

          terms_link:
            component: "a" 
            args: "href='/terms_of_service' style='text-decoration: underline'"

          "I agree to the Consider.it <privacy_link>Privacy Policy</privacy_link> and <terms_link>Terms</terms_link>."

        terms = customization('terms') or default_terms.join('')



        DIV 
          style: 
            marginTop: 24

          INPUT
            id: slugify("considerit_terms.editableinputBox")
            key: "considerit_terms.editable_inputBox"
            type:'checkbox'
            style: 
              fontSize: 24
              verticalAlign: 'top'
            checked: @local.tags['considerit_terms.editable']
            onChange: (event) =>
              @local.tags = @local.tags or {}
              @local.tags['considerit_terms.editable'] = @local.agreed_to_terms = event.target.checked
              save @local
          LABEL 
            htmlFor: slugify("considerit_terms.editableinputBox")
            style: 
              fontSize: 18
              paddingLeft: 8
            dangerouslySetInnerHTML: __html: terms




      if customization('auth_footer')
        auth = fetch('auth')
        if auth.ask_questions && auth.form in ['create account', 'create account via invitation', 'user questions']
          DIV 
            style:
              fontSize: 13
              color: auth_text_gray
              padding: '16px 0'
            dangerouslySetInnerHTML: {__html: customization('auth_footer')}

      if customization('login_footer')
        auth = fetch('auth')
        if auth.form == 'login'
          DIV 
            style:
              fontSize: 13
              color: auth_text_gray
              padding: '16px 0'
            dangerouslySetInnerHTML: {__html: customization('login_footer')}


      if (current_user.errors or []).length > 0 or @local.errors.length > 0
        errors = current_user.errors.concat(@local.errors or [])
        DIV
          role: 'alert'
          style:
            fontSize: 18
            color: 'darkred'
            backgroundColor: '#ffD8D8'
            padding: 10
            marginTop: 10
          for error in errors
            DIV null, 
              I
                className: 'fa fa-exclamation-circle'
                style: {paddingRight: 9}

              SPAN null, error






  #####
  form_footer: ->
    auth = fetch 'auth'
    if auth.form == 'create account'
      toggle_to = translator "auth.log_in", 'Log in'
    else
      toggle_to = translator "auth.login.toggle_to_create", 'Create an account'

    toggle = (e) =>
      current_user = fetch('/current_user')
      auth.form = if auth.form == 'create account' then 'login' else 'create account'
      current_user.errors = []
      @local.errors = []
      save auth
      save @local
      setTimeout =>
        $('#user_email')[0].focus()
      ,0

    DIV
      style:
        textAlign: 'center'


      if auth.form in ['create account', 'login']
        DIV
          style: 
            marginTop: 23
            width: '100%'

          SPAN 
            style: 
              color: 'white'
              fontWeight: 300
              fontSize: 24

            if auth.form == 'create account'
              TRANSLATE 'auth.create.should_you_be_here', 'Already have an account?'
            else 
              TRANSLATE 'auth.login.should_you_be_here', 'Not registered?'
          
          " "
          BUTTON
            className: 'toggle_auth'
            style:
              display: 'inline-block'
              color: 'white'
              textDecoration: 'underline'
              fontWeight: 600
              fontSize: 24
              backgroundColor: 'transparent'
              border: 'none'
              padding: 0
            onClick: toggle
            onKeyDown: (e) => 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                toggle(e)
                e.preventDefault()

            toggle_to
      
      if auth.form not in ['edit profile'] && !@props.disable_cancel && ( location.pathname != '/' || auth.goal != "access this private forum")
        cancel_auth = (e) =>

          if auth.form == 'verify email' || location.pathname == '/proposal/new'
            loadPage '/'

          if auth.form == 'verify email'
            setTimeout logout, 1

          reset_key auth

        BUTTON
          style:
            color: 'white'
            position: 'absolute'
            cursor: 'pointer'
            right: -100
            top: 40
            padding: 10
            fontSize: 24
            backgroundColor: 'transparent'
            border: 'none'
            opacity: .7

          title: translator 'engage.cancel_button', 'cancel'

          onClick: cancel_auth
          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              cancel_auth(e)
              e.preventDefault()

          translator 'engage.cancel_button', 'cancel'


  ####
  # submitButton
  #
  # Renders the blue button for auth form submission.
  #
  # action: the text for the button
  submitButton: (action) ->
    # this is gross code
    primary_color = @props.primary_color or '#676767'

    BUTTON
      style:
        fontSize: 36
        display: 'block'
        width: '100%'
        fontWeight: 700
        backgroundColor: primary_color
        textAlign: 'center'
        borderRadius: 8
        boxShadow: '0 2px 4px rgba(0,0,0,.2)'
        marginTop: 20
        
      className:'primary_button' + (if @local.submitting then ' disabled' else '')
      onClick: @submitAuth
      onKeyDown: (e) => 
        if e.which == 13 || e.which == 32 # ENTER or SPACE
          @submitAuth(e)
          e.preventDefault()
      
      action
        

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
      autoComplete: if name == 'verification_code' then 'off'

  ####
  # avatarInput
  #
  # Outputs a file input for uploading (and previewing) an avatar.
  # Returns null for non-FormData compliant browsers (IE9)...
  #
  avatarInput : ->
    # We're not going to bother with letting IE9 users set a profile picture. Too much hassle. 
    if window.FormData
      # hack for submitting file data in ActiveREST for now
      # we'll just submit the file form after user is signed in


      current_user = fetch '/current_user'
      user = fetch(fetch('/current_user').user)
      @local.preview ?= user.avatar_file_name || current_user.b64_thumbnail || current_user.avatar_remote_url

      FORM 
        id: 'user_avatar_form'
        action: '/update_user_avatar_hack', 

        HEARTBEAT
          public_key: 'preview_refresher' # sometimes we request an image before it is uploaded to AWS
                                          # so we'll just refresh to be safe

        DIV 
          style: 
            height: 60
            width: 60
            borderRadius: '50%'
            backgroundColor: '#e6e6e6'
            overflow: 'hidden'
            display: 'inline-block'
            marginRight: 18
            marginTop: 3

          IMG 
            key: fetch('preview_refresher').beat
            alt: ''
            id: 'avatar_preview'
            style: 
              width: 60
              display: if !@local.preview then 'none'
            src: if @local.newly_uploaded
                    @local.newly_uploaded
                 else if user.avatar_file_name
                    avatarUrl user, 'large'
                 else if current_user.b64_thumbnail 
                    current_user.b64_thumbnail 
                 else if current_user.avatar_remote_url
                    current_user.avatar_remote_url 
                 else 
                    null

          if !@local.preview  
            SVG 
              width: 60
              viewBox: "0 0 100 100" 
              style:
                position: 'relative'
                top: 8

              PATH 
                fill: "#ccc" 
                d: "M64.134,50.642c-0.938-0.75-1.93-1.43-2.977-2.023c8.734-6.078,10.867-18.086,4.797-26.805  c-6.086-8.727-18.086-10.875-26.82-4.797c-8.719,6.086-10.867,18.086-4.781,26.812c1.297,1.867,2.922,3.484,4.781,4.789  c-1.039,0.594-2.039,1.273-2.977,2.023c-6.242,5.031-11.352,11.312-15.023,18.438c-0.906,1.75-1.75,3.539-2.555,5.344  c17.883,16.328,45.266,16.328,63.133,0c-0.789-1.805-1.641-3.594-2.547-5.344C75.509,61.954,70.384,55.673,64.134,50.642z"



        INPUT 
          id: 'user_avatar'
          name: "avatar"
          type: "file"
          style: {marginTop: 24, verticalAlign: 'top'}
          onChange: (ev) => 
            @submit_avatar_form = true
            input = $('#user_avatar')[0]
            if input.files && input.files[0]
              reader = new FileReader()
              reader.onload = (e) =>
                @local.preview = true 
                @local.newly_uploaded = e.target.result
                save @local
                $("#avatar_preview").attr 'src', e.target.result
              reader.readAsDataURL input.files[0]

              #current_user.avatar = input.files[0]
            else
              $("#avatar_preview").attr('src', asset('no_image_preview.png'))
    else 
      null

  ####
  # pledgeInput
  #
  # Generates a list of checkbox pledges. 
  # 



  getPledges: ->
    if !customization('auth_require_pledge')
      return []
    else if customization('pledge')
      return customization('pledge')
    else 
      return [translator('auth.create.pledge.one_account', 'I will use only one account'), 
                 translator('auth.create.pledge.no_attacks', 'I will not attack or mock others')]



  ####
  # resetPasswordLink
  #
  # "I forgot my password!"
  resetPasswordLink : -> 
    reset = (e) => 
      # Tell the server to email us a token
      current_user = fetch('/current_user')
      current_user.trying_to = 'send_password_reset_token'
      save current_user, =>
        if current_user.errors?.length > 0
          arest.updateCache(current_user)
        else
          # Switch to reset_password mode
          reset_key 'auth', {form : 'reset password'}
    DIV 
      style: 
        textAlign: 'right'
        width: '100%'

      BUTTON
        style: 
          textDecoration: 'underline'
          color: '#737373'
          backgroundColor: 'transparent'
          border: 'none'
          fontSize: 12
          padding: 0
          fontWeight: 300
          position: 'relative'
          top: -8

        onClick: reset
        onKeyDown: (e) =>
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            reset(e)  
            e.preventDefault()


        translator('auth.forgot_password.link', 'Help! I forgot my password') 

  ####
  # userQuestionInputs
  #
  # Creates the ui inputs for answering user questions for this subdomain
  userQuestionInputs : -> 
    subdomain = fetch('/subdomain')
    current_user = fetch('/current_user')
    auth = fetch('auth')

    return DIV() if !current_user.tags



    if auth.ask_questions && auth.form in \
          ['edit profile', 'create account', 'create account via invitation', 'user questions']
      questions = customization('auth_questions').slice()
    else 
      questions = []



    if @local.tags != current_user.tags
      @local.tags = current_user.tags
      save @local
      return SPAN null

    inputs = []
    for question in questions
      label = "#{question.question}"      

      switch question.input

        when 'text'
          input = INPUT
            style: _.defaults question.input_style or {}, 
              marginBottom: 6
              width: 300
              border: "1px solid #{auth_ghost_gray}"
              padding: '5px 10px'
              fontSize: 18            
            key: "#{question.tag}_inputBox"
            id: slugify("#{question.tag}inputBox")
            type: 'text'
            value: @local.tags[question.tag]

            onChange: do(question) => (event) =>
              @local.tags = @local.tags or {}
              @local.tags[question.tag] = current_user.tags[question.tag] = event.target.value
              save @local
            onKeyPress: (event) =>
              # submit on enter
              if event.which == 13
                @submitAuth(event)

        when 'boolean'
          input = 

            DIV 
              style: 
                marginBottom: 10

              INPUT
                id: slugify("#{question.tag}inputBox")
                key: "#{question.tag}_inputBox"
                type:'checkbox'
                style: 
                  fontSize: 24
                  verticalAlign: 'top'
                  marginLeft: 0
                checked: @local.tags[question.tag]
                onChange: do(question) => (event) =>
                  @local.tags = @local.tags or {}
                  @local.tags[question.tag] = current_user.tags[question.tag] = event.target.checked
                  save @local

              LABEL 
                htmlFor: slugify("#{question.tag}inputBox")
                style: 
                  display: 'inline-block'
                  width: '90%'
                  paddingLeft: 8
                dangerouslySetInnerHTML: __html: question.question


          label = ''

        when 'checklist'
          input = DIV 
            style: 
              marginBottom: 10

            for option in question.options
              key = "#{question.tag.substring(0, question.tag.length - '.editable'.length)}:#{option} .editable"

              DIV null,

                INPUT
                  id: slugify("#{key}-inputBox")
                  key: "#{key}_inputBox"
                  type:'checkbox'
                  style: 
                    fontSize: 24
                    verticalAlign: 'top'
                    marginLeft: 0
                  checked: @local.tags[key]
                  onChange: do(question, option, key) => (event) =>
                    @local.tags = @local.tags or {}
                    @local.tags[key] = current_user.tags[key] = event.target.checked
                    save @local

                LABEL 
                  htmlFor: slugify("#{key}-inputBox")
                  style: 
                    display: 'inline-block'
                    width: '90%'
                    paddingLeft: 8
                  dangerouslySetInnerHTML: __html: option

        when 'dropdown'
          input = SELECT
            id: slugify("#{question.tag}inputBox")
            key: "#{question.tag}_inputBox"            
            style: _.defaults question.input_style or {},
              fontSize: 18
              marginTop: 4
              maxWidth: '100%'
            value: @local.tags[question.tag]
            onChange: do(question) => (event) =>
              @local.tags = @local.tags or {}
              @local.tags[question.tag] = current_user.tags[question.tag] = event.target.value
              save @local
            [
              OPTION 
                value: ''
                selected: true 
                disabled: true 
                hidden: true
              for value in question.options
                OPTION  
                  value: value
                  value
            ]

        else
          throw "Unsupported question type: #{question.input} for #{question.tag}"

      if !question.required && question.input not in ['boolean', 'checklist']
        op = DIV 
              style: 
                color: '#888'
                fontSize: 12
              translator('optional')

        label = [op, label] 

      inputs.push [label,input]
    inputs



  ####
  # submitAuth
  #
  # Carries out auth form submission. Called from clicking the 
  # submit button or hitting enter. 
  submitAuth : (ev) -> 
    ev.preventDefault()
    $el = $(@getDOMNode())
    subdomain = fetch '/subdomain'
    auth = fetch('auth')

    current_user = fetch('/current_user')

    # Client side validation of user questions
    # Note that we don't have server side validation because
    # the questions are all defined on the client. 
    @local.errors = []    
    if auth.ask_questions && auth.form not in ['login', 'reset password', 'verify email']
      questions = customization('auth_questions')
      for question in questions
        if question.required
          has_response = question.input in ['boolean', 'checklist'] || !!current_user.tags[question.tag]

          if !has_response || (question.require_checked && !current_user.tags[question.tag])
            @local.errors.push translator 
                                 id: 'auth.validation.missing_answer'
                                 question: question.question
                                 "{question} required!" 

          is_valid_input = true
          if question.validation
            is_valid_input = question.validation(current_user.tags[question.tag])
          if !is_valid_input && has_response
            @local.errors.push translator 
                                 id: 'auth.validation.invalid_answer'
                                 response: current_user.tags[question.tag]
                                 question: question.question  
                                 "{response} isn't a valid answer to #{question}!" 

      save @local

    if auth.ask_questions && auth.form not in ['login', 'reset password', 'verify email'] && !@local.agreed_to_terms
      @local.errors.push translator('auth.validation.agree_to_terms', "To proceed, you must agree to the terms") 

    if @local.errors.length == 0
      @local.submitting = true
      save @local

      current_user.signed_pledge = $el.find('.pledge-input').length == $el.find('.pledge-input:checked').length
      current_user.trying_to = auth.form

      save current_user, => 
        if auth.form in ['create account', 'edit profile']
          ensureCurrentUserAvatar()

        if auth.form in ['edit profile']
          @local.saved_successfully = current_user.errors.length + @local.errors.length == 0

        # Once the user logs in, we will stop showing the log-in screen
        else if current_user.logged_in
          if auth.goal == 'Save your Opinion'
            setTimeout((() -> updateProposalMode('results', 'after_save')), 700)
          reset_key auth

        @local.submitting = false
        save @local

      # hack for submitting file data in ActiveREST for now
      # we'll just submit the file form after user is signed in
      # TODO: investigate alternatives for submitting form data
      if @submit_avatar_form

        $('#user_avatar_form').ajaxSubmit
          type: 'PUT'
          data: 
            authenticity_token: current_user.csrf
            trying_to: 'update_avatar_hack'
    else 
      save @local

  componentDidMount : -> 
    writeToLog {what: 'accessed authentication'}


# It is important that a user that just submitted a user picture see the picture
# on the results and in the header. However, this is a bit tricky because the avatars
# are cached on the server and the image is processed in a background task. 
# Therefore, we'll wait until the image is available and then make it available
# in the avatar cache.  
ensureCurrentUserAvatar = (attempts = 0) ->
  
  $.getJSON '/user_avatar_hack', (response) =>
    current_user = fetch '/current_user'

    if response?[0]?.b64_thumbnail && current_user.b64_thumbnail != response[0].b64_thumbnail
      $('head').append("<style type=\"text/css\">#avatar-#{current_user.id} { background-image: url('#{response[0].b64_thumbnail}');}</style>")
      current_user.b64_thumbnail = response[0].b64_thumbnail 
      save current_user
    else if attempts < 20
      # Ugly: wait a little while for offline avatar processing to complete, then refetch
      _.delay -> 
        ensureCurrentUserAvatar(attempts + 1)
      , 1000




# can't combine the placeholder styles into one rule...
styles += """

.auth_text_input::-webkit-input-placeholder{
  color: #{auth_ghost_gray};
} 
.auth_text_input:-moz-placeholder{
  color: #{auth_ghost_gray};
} 
.auth_text_input::-moz-placeholder {
  color: #{auth_ghost_gray};
} 
.auth_text_input::-ms-input-placeholder {
  color: #{auth_ghost_gray};
}
"""

window.Auth = Auth
