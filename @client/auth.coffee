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
#
# Each of these screens has some differences. We try to keep these differences
# clearly documented in the render method so that the method doesn't get
# too complicated to understand and modify.

require './vendor/jquery.form'
require './admin' # for DashHeader
require './browser_location' # for loadPage
require './bubblemouth'
require './customizations'
require './form'
require './shared'

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

    DIV null,
      if auth.form == 'edit profile'
        DashHeader(name: 'Edit Profile')

      DIV
        style:
          margin: "0 auto 0 #{if customization('lefty') then '300px' else 'auto'}"
          padding: '4em 0'
          position: 'relative'
          zIndex: 0
          width: DECISION_BOARD_WIDTH

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
    
    goal = if auth.goal then "To #{auth.goal}" else null

    switch auth.form

      # The LOGIN form, with easy switch to register
      when 'login'
        [ @headerAndBorder goal, 'Introduce Yourself',
            @body [['Hi, I log in as:',
                    [ @inputBox('email', 'email@address'),
                      @inputBox('password', "password", 'password'),
                      @resetPasswordLink() ]]].concat @userQuestionInputs()
          @footerForRegistrationAndLogin() ]

      # The REGISTER form, with easy switch to log in
      #   ...or a slight variation for completing registration
      #      after invitation, where email is fixed and can't
      #      switch to log in.
      when 'create account', 'create account via invitation'
        
        if avatar_field = @avatarInput()
          avatar_field = ['I look like:', avatar_field]

        if pledges = @pledgeInput()
          pledges_field = ['I pledge to:', pledges]

        if auth.form == 'create account'
          email_field = @inputBox('email', 'email@address')
          footer = @footerForRegistrationAndLogin()
        else
          email_field = DIV
            style: {color: auth_text_gray, padding: '4px 8px'},
            current_user.email
          footer = @submitButton('Create new account')

        [ @headerAndBorder goal, 'Introduce Yourself',
            @body [['Hi, I log in as:',
                      [ email_field,
                        @inputBox('password', "password", 'password')]],
                    avatar_field,
                    ['My name is:', @inputBox('name', 'first and last name')],
                    pledges_field].concat @userQuestionInputs()
          footer ]

      # The EDIT PROFILE form
      # We don't render an enclosing header and border,
      # and add feedback when the user is updated.
      when 'edit profile'
        if avatar_field = @avatarInput()
          avatar_field = ['I look like:', avatar_field]

        [ @body [
            ['Hi, I log in as:',
              [ @inputBox('email', 'email@address'),
                @inputBox('password', "password", 'password')]
            ],
            ['My name is:', @inputBox('name', 'first and last name')],
            avatar_field].concat @userQuestionInputs()
          @submitButton('Update')
          if @local.saved_successfully
            SPAN style: {color: 'green'}, "Updated successfully"
        ]

      # The RESET PASSWORD form
      when 'reset password'
        [ @headerAndBorder null, 'Reset Your Password',
            @body [['Code:', @inputBox('verification_code', 'verification code from email')],
                   ['New password:', @inputBox('password', "choose a new password", 'password')]
                  ], 'We sent you a verification code via email.'
          @submitButton('Log in') ]

      # The email VERIFICATION form
      when 'verify email'
        [ @headerAndBorder goal, 'Verify Your Email',
            @body [['Code:', @inputBox('verification_code', 'verification code from email')]],
                  'We sent you a verification code via email.'
          @submitButton('Verify') ]

      when 'user questions'
        [ @headerAndBorder goal, 'Please give some info',
            @body @userQuestionInputs()
          @submitButton('Done!') ]

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

    real_task_width = widthWhenRendered(task, {fontSize: 61, fontWeight: 600})
    DIV null,

      # The auth form's header
      DIV
        style :
          width: BODY_WIDTH
          position: 'relative'
          margin: 'auto'
          top: 5 # to overlap bubblemouth with enclosure

        DIV
          style:
            textAlign: 'center'
            position: 'relative'

          if goal
            DIV
              style:
                fontWeight: 600
                fontSize: 18
                color: focus_blue
                transform: 'translateY(6px)'
              goal

          DIV
            style:
              position: 'relative'
              marginBottom: 10
              fontWeight: 600
              fontSize: 61
              whiteSpace: 'nowrap'
              color: focus_blue
            SPAN
              style: 
                position: 'relative'
                marginLeft: -(real_task_width - BODY_WIDTH) / 2
              task

            SPAN
              style:
                color: auth_ghost_gray
                position: 'absolute'
                cursor: 'pointer'
                right: -133
                top: 46
                fontSize: 21
              title: 'cancel'

              onClick: =>
                if auth.form == 'verify email' || location.pathname == '/proposal/new'
                  loadPage '/'
                reset_key auth

              I className: 'fa-close fa'

              ' cancel'

        DIV
          style:
            left: BODY_WIDTH / 2
            height: 50
            width: 50
            top: 0
            borderRadius: '50%'
            marginLeft: -50 / 2
            backgroundColor: focus_blue
            position: 'relative'
            boxShadow: "0px 1px 0px black, inset 0 1px 2px rgba(255,255,255, .4), 0px 0px 0px 1px #{focus_blue}"


        DIV 
          key: 'auth_bubblemouth'
          style: css.crossbrowserify
            left: BODY_WIDTH / 2 - 34/2
            top: 10 + 3 + 1 # +10 is because of the decision board translating down 10, 3 is for its border
            position: 'relative'

          Bubblemouth 
            apex_xfrac: .5
            width: 34
            height: 28
            fill: 'white', 
            stroke: focus_blue, 
            stroke_width: 11
            dash_array: "25 10"


      # Dashed enclosure in which auth form is rendered
      DIV
        className: if @local.submitting then ' waiting' else ''
        style:
          padding: '2.5em 46px 1.5em 46px'
          fontSize: 18
          marginTop: 10
          borderRadius: 16
          borderStyle: 'dashed'
          borderWidth: 3
          borderColor: focus_blue

        body


  ######
  # body
  #
  # Renders the main part of the auth form. Also
  # renders any user errors.
  #
  # fields: a list of input fields and labels to
  #         be rendered in a table.
  # additional_instructions: text rendered before
  #                          the fields
  body : (fields, additional_instructions) ->
    current_user = fetch '/current_user'

    DIV null,
      if additional_instructions
        DIV
          style:
            color: auth_text_gray
            marginBottom: 18
          additional_instructions

      TABLE null, TBODY null,
        for field in fields
          if field
            [TR null,
              TD
                style:
                  paddingTop: 4
                  verticalAlign: 'top'
                  width: '30%'
                LABEL
                  style:
                    color: focus_blue
                    fontWeight: 600
                  field[0]
              TD
                style:
                  verticalAlign: 'top'
                  width: '100%'
                  paddingLeft: 18
                field[1]
             TR style: {height: 10}]

      if (current_user.errors or []).length > 0 or @local.errors.length > 0
        errors = current_user.errors.concat(@local.errors or [])
        DIV
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
  # footerForRegistrationAndLogin
  #
  # The footer for switching between create new account and login
  #
  footerForRegistrationAndLogin : ->
    auth = fetch 'auth'
    if auth.form == 'create account'
      toggle_to = 'Log in'
      button = 'Create new account'
      left = 421
    else
      button = 'Log in'
      toggle_to = 'Create new account'
      left = 349

    DIV
      style:
        position: 'relative'
        textAlign: 'center'

      @submitButton button, true

      SPAN
        style: 
          position: 'absolute'
          left: left
          marginTop: 23
          textAlign: 'left'
          width: '100%'

        SPAN
          style:
            color: '#444'
            fontSize: 24
            paddingLeft: 18
            paddingRight: 7
          'or '
        A
          style:
            display: 'inline-block'
            color: '#444'
            textDecoration: 'underline'
            fontWeight: 400
            fontSize: 24
          onClick: =>
            current_user = fetch('/current_user')
            auth.form = if auth.form == 'create account' then 'login' else 'create account'
            current_user.errors = []
            @local.errors = []
            save auth
            save @local

          toggle_to
      
      if customization('auth.additional_auth_footer')
        additional = customization('auth.additional_auth_footer')()




  ####
  # submitButton
  #
  # Renders the blue button for auth form submission.
  #
  # action: the text for the button
  # inline: is the button inline-block?
  submitButton : (action, inline) ->
    # this is gross code
    el =  DIV
        style:
          fontSize: 24
          display: if inline then 'inline-block' else 'block'
        className:'primary_button' + (if @local.submitting then ' disabled' else '')
        onClick: @submitAuth
        action

    if !inline && customization('auth.additional_auth_footer')
      additional = customization('auth.additional_auth_footer')()

    if additional
      DIV null, 
        el
        additional
    else
      el
        


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
        width: 300
        border: "1px solid #{auth_ghost_gray}"
        padding: '5px 10px'
        fontSize: 18
      value: if auth.form == 'edit profile' then @local[name] else null
      name: "user[#{name}]"
      key: "#{name}_inputBox"
      placeholder: placeholder
      required: "required"
      type: type || 'text'
      onChange: onChange
      onKeyPress: (event) =>
        # submit on enter
        if event.which == 13
          @submitAuth(event)
      pattern: pattern

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
      FORM 
        id: 'user_avatar_form'
        action: '/update_user_avatar_hack', 

        DIV 
          style: 
            height: 60
            width: 60
            borderRadius: '50%'
            backgroundColor: '#e6e6e6'
            overflow: 'hidden'
            display: 'inline-block'
            marginRight: 18

          IMG 
            id: 'avatar_preview'
            style: {width: 60}
            src: if current_user.b64_thumbnail 
                    current_user.b64_thumbnail 
                 else if current_user.avatar_remote_url 
                    current_user.avatar_remote_url 
                 else 
                    null

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
              reader.onload = (e) ->
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
  pledgeInput : -> 
    subdomain = fetch('/subdomain')

    if !subdomain.has_civility_pledge
      return null
    else
      pledges = ['Use only one account', 
                 'Speak only on behalf of myself', 
                 'Not attack or mock others']

    UL style: {paddingTop: 6},

      for pledge, idx in pledges
        LI 
          style: 
            listStyle: 'none'
            position: 'relative'
            paddingLeft: 30
            paddingBottom: 3
            color: auth_text_gray

          INPUT
            className:"pledge-input"
            type:'checkbox'
            id:"pledge-#{idx}"
            name:"pledge-#{idx}"
            style: 
              fontSize: 24
              position: 'absolute'
              left: 0
              top: 5
              margin: 0

          LABEL 
            htmlFor: "pledge-#{idx}"
            style: 
              fontSize: 18
            pledge

  ####
  # resetPasswordLink
  #
  # "I forgot my password!"
  resetPasswordLink : -> 
    DIV style: {textAlign: 'right'}, 
      A 
        style: 
          textDecoration: 'underline'
          color: auth_ghost_gray
        onClick: => 
          # Tell the server to email us a token
          current_user = fetch('/current_user')
          current_user.trying_to = 'send_password_reset_token'
          save current_user, =>
            if current_user.errors?.length > 0
              arest.updateCache(current_user)
            else
              # Switch to reset_password mode
              reset_key 'auth', {form : 'reset password'}

        'I forgot my password!'

  ####
  # userQuestionInputs
  #
  # Creates the ui inputs for answering user questions for this subdomain
  userQuestionInputs : -> 
    subdomain = fetch('/subdomain')
    current_user = fetch('/current_user')
    auth = fetch('auth')

    questions = if auth.ask_questions then customization 'auth.user_questions'
    questions = questions or []

    if @local.tags != current_user.tags
      @local.tags = current_user.tags
      save @local
      return SPAN null

    inputs = []
    for question in questions
      label = "#{question.question}:"      

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
          input = INPUT
            type:'checkbox'
            style: _.defaults question.input_style or {},  
              fontSize: 24
              marginTop: 10
            checked: @local.tags[question.tag]
            onChange: do(question) => (event) =>
              @local.tags = @local.tags or {}
              @local.tags[question.tag] = current_user.tags[question.tag] = event.target.checked
              save @local

        when 'dropdown'
          input = SELECT
            style: _.defaults question.input_style or {},
              fontSize: 18
              marginTop: 4
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
    if auth.ask_questions
      questions = customization('auth.user_questions')
      @local.errors = []
      for question in questions
        if question.required
          has_response = !!current_user.tags[question.tag]
          @local.errors.push "#{question.question} required!" if !has_response

          is_valid_input = true
          if question.validation
            is_valid_input = question.validation(current_user.tags[question.tag])
          @local.errors.push "#{current_user.tags[question.tag]} isn't a valid answer to #{question.question}!" if !is_valid_input && has_response

      save @local

    if @local.errors.length == 0
      @local.submitting = true
      save @local

      current_user.signed_pledge = $el.find('.pledge-input').length == $el.find('.pledge-input:checked').length
      current_user.trying_to = auth.form

      save current_user, => 
        if auth.form in ['create account', 'edit profile']
          ensureCurrentUserAvatar()

        if auth.form == 'edit profile'
          @local.saved_successfully = current_user.errors.length == 0 && (@local.errors or []).length == 0

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
