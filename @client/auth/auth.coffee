##################
# Auth
#
# Contains some shared methods used by the following auth forms:
# - login
# - create account
# - create account via invitation (with fixed email address)
# - reset password
# - verify email
# - edit profile
# - user questions

require '../browser_location' # for loadPage
require '../bubblemouth'
require '../customizations'
require '../shared'

require './upload_avatar'
require './reset_password'
require './verify_email'
require './host_questions'
require './login_and_register'


# AuthTransition doesn't actually render anything.  It just handles state
# transitions for current_user, e.g. for CSRF and logging in and out.
window.AuthTransition = ReactiveComponent
  displayName: 'AuthTransition'
  render : ->
    current_user = fetch('/current_user')
    auth = fetch('auth')

    @local.logged_in_last_render ?= current_user.logged_in

    if current_user.csrf
      arest.csrf(current_user.csrf)


    # When we switch to new auth_mode screens, wipe out all the old
    # errors, cause we're startin' fresh!
    if @local.current_auth != auth.form
      @local.current_auth = auth.form
      current_user.errors = []

    # Once the user logs in, we will stop showing the log-in screen 
    # and transition if needed
    if !@local.logged_in_last_render && current_user.logged_in
      if auth.after == 'transition to proposal results'
        setTimeout -> 
          updateProposalMode('results', 'after_save')
        , 700
      reset_key auth

    # Publish pending opinions if we can
    if @root.opinions_to_publish.length > 0

      remaining_opinions = []

      for opinion_key in @root.opinions_to_publish
        opinion = fetch(opinion_key)
        can_opine = permit('publish opinion', opinion.proposal)

        if can_opine > 0 && !opinion.published
          opinion.published = true
          save opinion
        else 
          remaining_opinions.push opinion_key

          # TODO: show some kind of prompt to user indicating that despite 
          #       creating an account, they still aren't permitted to publish 
          #       their opinion.
          # if can_opine == Permission.INSUFFICIENT_PRIVILEGES
          #   ...

      if remaining_opinions.length != @root.opinions_to_publish.length
        @root.opinions_to_publish = remaining_opinions
        save @root

    # users following an email invitation need to complete 
    # registration (name + password)
    if current_user.needs_to_complete_profile && auth.form not in ['edit profile', 'create account via invitation']
      subdomain = fetch('/subdomain')

      reset_key 'auth',
        key: 'auth'
        form: if subdomain.SSO_domain then 'edit profile' else 'create account via invitation'
        goal: 'To participate, please introduce yourself below.'

      if subdomain.SSO_domain
        loadPage '/dashboard/edit_profile'
        
    # there's a required question this user has yet to answer
    else if current_user.logged_in && !current_user.completed_host_questions && !auth.form
      reset_key 'auth',
        form: 'user questions'
        goal: 'To participate, please answer these questions from the forum host.'


    else if current_user.needs_to_verify && !window.send_verification_token
      current_user.trying_to = 'send_verification_token'
      save current_user

      window.send_verification_token = true 

      reset_key 'auth',
        key: 'auth'
        form: 'verify email'
        goal: 'To participate, please demonstrate you control this email.'

    @local.logged_in_last_render = current_user.logged_in

    SPAN null




# Router for the auth forms
window.Auth = ReactiveComponent
  displayName: 'Auth'

  render: ->
    current_user = fetch('/current_user')
    auth = fetch('auth')

    if auth.form == 'reset password'
      return ResetPassword()
    else if auth.form == 'verify email'
      return VerifyEmail()
    else if auth.form == 'login'
      return Login()
    else if auth.form == 'create account'
      return CreateAccount()
    else if auth.form == 'create account via invitation'
      return CreateAccount by_invitation: true
    else if auth.form == 'user questions'
      return HostQuestions()
    else 
      SPAN null 

  componentDidMount : -> 
    writeToLog {what: 'accessed authentication'}





window.logout = -> 
  current_user = fetch('/current_user')
  current_user.logged_in = false
  current_user.trying_to = 'logout'

  auth = fetch 'auth'
  loc = fetch 'location'
  if loc.url.match('/dashboard')
    loadPage '/'

  reset_key auth

  save current_user, =>
    # We need to get a fresh your_opinion object
    # after logging out. 
    location.reload()



window.auth_text_gray = '#444'    # the gray color for solid text



# default styles for auth forms
window.styles += """
  .AUTH {
    background: linear-gradient(180deg, rgba(223,98,100,1) 250px, rgba(238,238,238,1) 250px);
    min-height: 100vh;
  }

  .AUTH_wrapper {
    margin: 0 auto;
    padding: 4em 0;
    position: relative;
    z-index: 0;
  }

  .AUTH_header {
    text-align: center;
    margin-bottom: 24px;
  }

  .AUTH_goal {
    font-size: 16px;
    text-align: center;
    color: white;
    margin-bottom: 8px;
    font-style: italic;
  }

  .AUTH_task {
    font-size: 44px;
    font-weight: 400;
    white-space: nowrap;
  }

  .AUTH_body_wrapper {
    padding: 1.5em 50px 2.5em 50px;
    font-size: 18px;
    box-shadow: 0 2px 4px rgba(0,0,0,.4);
    background-color: white;
    position: relative;
  }

  .AUTH_cancel {
    color: white;
    position: absolute;
    cursor: pointer;
    right: -100px;
    top: 40px;
    padding: 10px;
    font-size: 24px;
    background-color: transparent;
    border: none;
    opacity: .7;
  }

  .AUTH_submit_button {
    color: white;
    background-color: #676767;
    font-size: 36px;
    display: block;
    width: 100%;
    font-weight: bold;
    text-align: center;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,.2);
    margin-top: 20px;
  }

  .AUTH_field_wrapper {
    margin-bottom: 8px;
  }

  .AUTH_field_label {
    color: #222;
    font-size: 18px;
    display: block;
    font-weight: bold;
  }

  .AUTH_text_input {
    margin-bottom: 6px;
    width: 100%;
    border: 1px solid #ccc;
    padding: 10px 14px;
    fontSize: #{if browser.is_mobile then 36 else 20}px;
    display: inline-block;
    background-color: #f2f2f2;
  }


"""


window.AuthForm = (action, bind_to) ->
  current_user = fetch '/current_user'

  Draw = (options, children) -> 
    DIV 
      className: 'AUTH'

      DIV
        className: 'AUTH_wrapper'
        style:
          width: AUTH_WIDTH()

        if !options.disallow_cancel
          BUTTON
            className: 'AUTH_cancel'
            title: translator 'engage.cancel_button', 'cancel'

            onKeyDown: (e) => 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.target.click()
                e.preventDefault()

            onClick: (e) ->
              options.before_cancel?()
              if location.pathname == '/proposal/new'
                loadPage '/'
              reset_key 'auth'

            translator 'engage.cancel_button', 'cancel'

        if options.goal
          DIV
            className: 'AUTH_goal'
            options.goal


        DIV
          className: "AUTH_body_wrapper"

          # The auth form's header
          DIV
            className: 'AUTH_header'
                
            H1
              className: 'AUTH_task'

              options.task

            options.render_below_title?()


          children 

          BUTTON
            className: "AUTH_submit_button #{if @local.submitting then 'disabled'}"
            onClick: options.on_submit or Submit
            onKeyDown: (e) => 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.target.click()
                e.preventDefault()
            
            options.submit_button or auth_translations().submit_button      


  RenderInput = (opts) -> 
    type = opts.type or 'text'
    name = opts.name

    field_id = "user_#{name}"
    @local.updates ?= {}
    @local.updates[name] ?= current_user[name]
    
    DIV 
      className: 'AUTH_field_wrapper'

      LABEL
        className: 'AUTH_field_label'
        htmlFor: field_id
        opts.label

      if opts.render 
        opts.render()
      else 

        INPUT
          id: 'user_' + name
          key: "#{name}_inputBox"
          name: "user[#{name}]"
          type: type
          className: 'AUTH_text_input'
          defaultValue: @local.updates[name]
          'aria-label': opts.label
          autoComplete: 'off'
          disabled: opts.disabled

          onChange: (event) =>
            if type == 'email'
              @local.updates[name] = (event.target.value).trim()
            else 
              @local.updates[name] = event.target.value

            save @local

          onKeyPress: (event) =>
            if event.which == 13 # enter key
              (opts.submit_data or @submitAuth)?(event)

  Submit = (ev, opts) -> 
    ev.preventDefault()
    opts ?= {}

    # Client side validation of user questions
    if opts.has_host_questions 
      @local.errors = errors_in_host_questions current_user.tags
    else 
      @local.errors = []

    if opts.check_considerit_terms && !current_user.tags?['considerit_terms']
      @local.errors.push translator('auth.validation.agree_to_terms', "To proceed, you must agree to the terms") 


    if @local.errors.length == 0
      current_user.trying_to = action

      if @local.updates
        _.extend current_user, @local.updates

      @local.submitting = true

      save current_user, => 
        @local.saved_successfully = current_user.errors.length + @local.errors.length == 0
        @local.submitting = false
        save @local

      if opts.has_avatar_upload
        upload_avatar()

    save @local

  ShowErrors = (errors) -> 
    errors = (current_user.errors or []).concat(@local.errors or [])
    return SPAN null if !errors || errors.length == 0

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



  Draw = Draw.bind bind_to
  Submit = Submit.bind bind_to
  RenderInput = RenderInput.bind bind_to
  ShowErrors = ShowErrors.bind bind_to

  {Draw, Submit, RenderInput, ShowErrors}



window.auth_translations = ->
  name_label: translator('auth.create.name_label', 'Your name')
  email_label: translator('auth.login.email_label', 'Your email')
  password_label: translator('auth.login.password_label', 'Your password')
  pic_prompt: translator('auth.create.pic_prompt', 'Your picture')
  code_label: translator('auth.code_entry', 'Code')
  code_placeholder: translator('auth.code_entry.placeholder', 'verification code from email')
  successful_update: translator("auth.successful_update", "Updated successfully")
  verification_sent_message: translator('auth.verification_sent', 'We just emailed you a verification code. Copy / paste it below.')
  submit_button: translator("auth.submit", 'Submit')

