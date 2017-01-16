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
      try 
        goal = "To #{t(auth.goal).toLowerCase()}"
      catch 
        goal = "To #{auth.goal.toLowerCase()}" 

    switch auth.form

      # The LOGIN form, with easy switch to register
      when 'login'
        [ @headerAndBorder goal, t('Introduce Yourself'),
            @body [
                    ["#{t('login_as')}:", @inputBox('email', 'email@address', 'email')],
                    ["My #{t("password")}:", [@inputBox('password', t("password"), 'password'), @resetPasswordLink()]]
                  ].concat @userQuestionInputs()
          @footerForRegistrationAndLogin() ]

      # The REGISTER form, with easy switch to log in
      #   ...or a slight variation for completing registration
      #      after invitation, where email is fixed and can't
      #      switch to log in.
      when 'create account', 'create account via invitation'
        
        if avatar_field = @avatarInput()
          avatar_field = ["#{t('pic_prompt')}:", avatar_field]

        if pledges = @pledgeInput()
          pledges_field = ['My pledge:', pledges]

        if auth.form == 'create account'
          email_field = ["#{t('login_as')}:", @inputBox('email', 'email@address', 'email')]
          footer = [@footerForRegistrationAndLogin(), @privacyAndTerms()]
        else
          email_field = ["#{t('login_as')}:", DIV style: {color: auth_text_gray, padding: '4px 8px'}, current_user.email]
          footer = [@submitButton(t('Create new account')), @privacyAndTerms()]

        [ @headerAndBorder goal, t('Introduce Yourself'),
            @body [
                    email_field,
                    ["My #{t("password")}:", @inputBox('password', t("password"), 'password')],
                    avatar_field,
                    [t('name_prompt'), @inputBox('name', t('full_name'))],
                    pledges_field].concat @userQuestionInputs()
          footer ]

      # The EDIT PROFILE form
      when 'edit profile'
        if avatar_field = @avatarInput()
          avatar_field = ["#{t('pic_prompt')}:", avatar_field]

        [ @headerAndBorder goal, t('Your Profile'),
            @body [
              # we don't want users on single sign on subdomains to change email/password
              if !fetch('/subdomain').SSO_domain       
                ["#{t('login_as')}:", @inputBox('email', 'email@address', 'email')]
              if !fetch('/subdomain').SSO_domain
                ["My #{t("password")}:", @inputBox('password', t("password"), 'password')]
              ["#{t('name_prompt')}:", @inputBox('name', t('full_name'))]
              avatar_field
            ].concat @userQuestionInputs()
          @submitButton(t('Update'))
          if @local.saved_successfully
            if subdomain.SSO_domain
              loadPage '/'
            SPAN style: {color: 'green'}, t("Updated successfully")
        ]

      # The RESET PASSWORD form
      when 'reset password'
        [ @headerAndBorder null, t('Reset Your Password'),
            @body [
                   ['', INPUT({name: 'user[verification_code]', disabled: true, style: {display: 'none'}} )] # prevent autofill of code with email address
                   ['', INPUT({type: 'password', name: 'user[password]', disabled: true, style: {display: 'none'}} )] # prevent autofill of code with password
                   ["#{t('Code')}:", @inputBox('verification_code', t('code_from_email'))],
                   ["#{t('New password')}:", @inputBox('password', t("choose_password"), 'password')], 

                  ], t('verification_sent')
          @submitButton(t('Log in')) 
          DIV 
            style: 
              marginTop: 20
            'Having trouble resetting your password? Watch this brief '

            A 
              target: '_blank'
              href: 'https://vimeo.com/198802322'
              style: 
                textDecoration: 'underline'
                fontWeight: 600
              'video tutorial'
            '.'

        ]

      # The email VERIFICATION form
      when 'verify email'
        [ @headerAndBorder goal, t('Verify Your Email'),
            @body [["#{t('Code')}:", @inputBox('verification_code', t('code_from_email'))]],
                  t('verification_sent')
          @submitButton(t('Verify')) ]

      when 'user questions'
        [ @headerAndBorder goal, t('more_info'),
            @body @userQuestionInputs()
          @submitButton("#{t('Done')}!") ]

      else
        throw "Unrecognized authentication form #{auth.form}"

  privacyAndTerms: -> 
    DIV 
      style: 
        color: '#999'
        marginTop: 20
        fontSize: 14
        textAlign: 'center'

      "By creating an account, you agree to our "
      A
        href: '/terms_of_service'
        target: '_blank'
        style: 
          textDecoration: 'underline'
        'Terms'
      ' and that you have read our '
      A
        href: '/privacy_policy'
        target: '_blank'        
        style: 
          textDecoration: 'underline'
        'Privacy Policy'
      '.'

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

    if @props.naked
      return body

    primary_color = @props.primary_color or focus_blue

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

          if goal
            DIV
              style:
                fontWeight: 600
                fontSize: 18
                color: primary_color
                transform: 'translateY(6px)'
              goal

          DIV
            style:
              position: 'relative'
              marginBottom: 10
              fontWeight: 600
              whiteSpace: 'nowrap'

            H1
              style: 
                display: 'inline-block'
                position: 'relative'
                fontWeight: 600
                fontSize: 61
                color: primary_color

              task

            if auth.form not in ['edit profile']
              cancel_auth = (e) =>

                if auth.form == 'verify email' || location.pathname == '/proposal/new'
                  loadPage '/'

                if auth.form == 'verify email'
                  setTimeout logout, 1

                reset_key auth

              if !@props.disable_cancel && ( location.pathname != '/' || auth.goal != "access this private forum")
                BUTTON
                  style:
                    color: auth_ghost_gray
                    position: 'absolute'
                    cursor: 'pointer'
                    right: 0
                    top: 70
                    padding: 10
                    fontSize: 24
                    backgroundColor: 'transparent'
                    border: 'none'

                  title: t('cancel')

                  onClick: cancel_auth
                  onKeyDown: (e) => 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      cancel_auth(e)
                      e.preventDefault()

                  I className: 'fa-close fa'

                  ' ' + t('cancel')

        DIV
          style:
            left: AUTH_WIDTH() / 2
            height: 50
            width: 50
            top: 0
            borderRadius: '50%'
            marginLeft: -50 / 2
            backgroundColor: primary_color
            position: 'relative'
            boxShadow: "0px 1px 0px black, inset 0 1px 2px rgba(255,255,255, .4), 0px 0px 0px 1px #{primary_color}"


        DIV 
          key: 'auth_bubblemouth'
          style: css.crossbrowserify
            left: AUTH_WIDTH() / 2 - 34/2
            top: 10 + 3 + 1 # +10 is because of the decision board translating down 10, 3 is for its border
            position: 'relative'

          Bubblemouth 
            apex_xfrac: .5
            width: 34
            height: 28
            fill: 'white', 
            stroke: primary_color, 
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
          borderColor: primary_color

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
    primary_color = @props.primary_color or focus_blue

    DIV null,
      if additional_instructions
        DIV
          style:
            color: auth_text_gray
            marginBottom: 18
          additional_instructions

      TABLE null, TBODY null,
        for field in fields when field
          field_id = field[1]?.props?.id or field[1]?[0]?.props?.id
          if field_id 
            field_id = field_id.replace('user_avatar_form', 'user_avatar')
          [TR null,
            TD
              style:
                paddingTop: 4
                verticalAlign: 'top'
                width: '36%'

              LABEL
                htmlFor: field_id
                style:
                  color: primary_color
                  fontWeight: 600
                  fontSize: if browser.is_mobile then 24
                field[0]

                if field.length > 2
                  DIV 
                    style: 
                      display: 'block'
                      color: auth_ghost_gray
                      fontSize: 14
                      fontWeight: 400
                    field[2]
            TD
              style:
                verticalAlign: 'bottom'
                width: '100%'
                paddingLeft: 18
              field[1]

           TR style: {height: 10}]

      if customization('auth_footer')
        auth = fetch('auth')
        if auth.ask_questions && auth.form in ['create account', 'create account via invitation', 'user questions']
          DIV 
            style:
              fontSize: 13
              color: auth_text_gray
              padding: '16px 0'
            dangerouslySetInnerHTML: {__html: customization('auth_footer')}

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
  # footerForRegistrationAndLogin
  #
  # The footer for switching between create new account and login
  #
  footerForRegistrationAndLogin : ->
    auth = fetch 'auth'
    if auth.form == 'create account'
      toggle_to = t('Log in')
      button = t('Create new account')
    else
      button = t('Log in')
      toggle_to = t('Create new account')

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
        #position: 'relative'
        #left: '50%'
        #marginLeft: -(widthWhenRendered(button, {fontSize: 24}) + 36*2) / 2

      @submitButton button, true

      SPAN
        style: 
          marginTop: 23
          textAlign: 'left'
          width: '100%'

        SPAN
          style:
            color: '#444'
            fontSize: 18
            paddingLeft: 18
            paddingRight: 7
          t('or') + ' '

        BUTTON
          className: 'toggle_auth'
          style:
            display: 'inline-block'
            color: '#444'
            textDecoration: 'underline'
            fontWeight: 400
            fontSize: 20
            backgroundColor: 'transparent'
            border: 'none'
          onClick: toggle
          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              toggle(e)
              e.preventDefault()

          toggle_to
      



  ####
  # submitButton
  #
  # Renders the blue button for auth form submission.
  #
  # action: the text for the button
  # inline: is the button inline-block?
  submitButton : (action, inline) ->
    # this is gross code
    primary_color = @props.primary_color or focus_blue

    BUTTON
      style:
        fontSize: 28
        display: if inline then 'inline-block' else 'block'
        width: if !inline then '100%'
        fontWeight: 700
        backgroundColor: primary_color
        
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
        width: Math.max 300, AUTH_WIDTH() * .55
        border: "1px solid #{auth_ghost_gray}"
        padding: '5px 10px'
        fontSize: if browser.is_mobile then 36 else 18
        display: 'inline-block'
      value: if auth.form in ['edit profile'] then @local[name] else null
      name: "user[#{name}]"
      key: "#{name}_inputBox"
      placeholder: placeholder
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
            alt: ''
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

    if !customization('auth_require_pledge')
      return null
    else
      pledges = ['I will use only one account', 
                 'I will not attack or mock others']


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
          color: auth_ghost_gray
          backgroundColor: 'transparent'
          border: 'none'
          fontSize: 18
          padding: 0

        onClick: reset
        onKeyDown: (e) =>
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            reset(e)  
            e.preventDefault()


        t('forgot_password') 

  ####
  # userQuestionInputs
  #
  # Creates the ui inputs for answering user questions for this subdomain
  userQuestionInputs : -> 
    subdomain = fetch('/subdomain')
    current_user = fetch('/current_user')
    auth = fetch('auth')

    if auth.ask_questions && auth.form in \
          ['edit profile', 'create account', 'create account via invitation', 'user questions']
      questions = customization('auth_questions')
    else 
      questions = []


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
          input = INPUT
            id: slugify("#{question.tag}inputBox")
            key: "#{question.tag}_inputBox"
            type:'checkbox'
            style: _.defaults question.input_style or {},  
              fontSize: 32
              marginTop: 10
            checked: @local.tags[question.tag]
            onChange: do(question) => (event) =>
              @local.tags = @local.tags or {}
              @local.tags[question.tag] = current_user.tags[question.tag] = event.target.checked
              save @local

        when 'dropdown'
          input = SELECT
            id: slugify("#{question.tag}inputBox")
            key: "#{question.tag}_inputBox"            
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
    if auth.ask_questions && auth.form in ['create account', 'create account via invitation']
      questions = customization('auth_questions')
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

        if auth.form in ['edit profile']
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
