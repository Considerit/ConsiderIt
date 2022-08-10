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
require '../customizations'
require '../shared'
require '../modal'



window.AuthCallout = ReactiveComponent
  displayName: 'AuthCallout'

  render: ->
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    return SPAN null if current_user.logged_in || customization('contribution_phase') == 'frozen'

    create_account_button_style = 
                    backgroundColor: selected_color
                    marginRight: 8
                    # border: 'none'
                    # fontWeight: 700
                    # padding: "4px 18px"
                    # color: 'white'   
                    # borderRadius: 16   
    DIV  
      style: 
        width: '100%'

      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: 'auto'
          padding: 12
          # backgroundColor: '#f1f1f1'
        
        DIV 
          style: 
            fontSize: 20
            fontWeight: 600
            textAlign: 'center'

          if subdomain.SSO_domain

            TRANSLATE
              id: 'create_account.call_out'
              BUTTON1: 
                component: A 
                args: 
                  className: "btn create_account"
                  href: '/login_via_saml'
                  treat_as_external_link: true
                  style: create_account_button_style
                    

              "<BUTTON1>Create an Account</BUTTON1> to share your thoughts"
          else 
            TRANSLATE
              id: 'create_account.call_out'
              BUTTON1: 
                component: BUTTON 
                args: 
                  key: 'create_button'
                  'data-action': 'create'
                  onClick: (e) =>
                    reset_key 'auth',
                      form: 'create account'
                  style: create_account_button_style
                  className: "btn create_account"
              "<BUTTON1>Create an Account</BUTTON1> to share your thoughts"

          if '*' not in subdomain.roles.participant
            DIV 
              style: 
                fontSize: 12
                marginTop: 4
              translator 'engage.permissions.only_some_participate', 'Only some accounts are authorized to participate.'
        
        if @props.children 
          @props.children

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
    # and execute any callbacks
    if (!@local.logged_in_last_render && current_user.logged_in && !auth.show_user_questions_after_account_creation) || \
       (auth.form == 'verify email' && current_user.verified) || \
       (auth.form == 'user questions' && (current_user.completed_host_questions && !auth.show_user_questions_after_account_creation)) || \
       (auth.form == 'create account via invitation' && !current_user.needs_to_complete_profile)
      auth.after?()
      reset_key auth


    # users following an email invitation need to complete 
    # registration (name + password)
    if current_user.needs_to_complete_profile && auth.form not in ['edit profile', 'create account via invitation']
      subdomain = fetch('/subdomain')

      reset_key 'auth',
        key: 'auth'
        form: if subdomain.SSO_domain then 'edit profile' else 'create account via invitation'
        goal: ''

      if subdomain.SSO_domain
        loadPage '/dashboard/edit_profile'
        
    # there's a required question this user has yet to answer
    else if current_user.logged_in && ((!current_user.completed_host_questions && !auth.form) || auth.show_user_questions_after_account_creation) 
      reset_key 'auth',
        form: 'user questions'
        goal: ''
        show_user_questions_after_account_creation: auth.show_user_questions_after_account_creation


    else if current_user.needs_to_verify && !window.send_verification_token
      current_user.trying_to = 'send_verification_token'
      save current_user

      window.send_verification_token = true 

      reset_key 'auth',
        key: 'auth'
        form: 'verify email'
        goal: 'To participate, please demonstrate you control this email.'

    @local.logged_in_last_render = current_user.logged_in


    if embedded_demo() && fetch('/subdomain').name == 'galacticfederation'
      if auth.form == 'create account' 
        id = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 15)
        _.extend current_user, 
          name: "temp"
          email: "temp-#{id}@galacticfederation.gov"
          password: "#{Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 15)}"
          trying_to: 'create account'
        save current_user

        reset_key 'auth'
      else if current_user.tags.federation_allegiance && current_user.name == 'temp'
        allegiance = current_user.tags.federation_allegiance
        id = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 15)
        switch allegiance 
          when 'Dark'
            name = "Stormtrooper ##{id}"
            email = "stormtrooper-#{id}@deathstar.org"
            avatar_url = "https://d2rtgkroh5y135.cloudfront.net/system/avatars/287330/large/stormtrooper1.png"
            break
          when 'Light' 
            name = "Ewok ##{id}"
            email = "endorite-#{id}@endor.net"
            avatar_url = "https://f.consider.it/galacticfederation/ewok.png"                  
            break
          when "Wouldn't you like to know"
            name = "Wookiee ##{id}"
            email = "kashyyyk-wook#{id}@oo.com"
            avatar_url = 'https://f.consider.it/galacticfederation/wookiee.jpeg'
            break
          when 'Non-binary' 
            name = "Rodian ##{id}"
            email = "rodia-#{id}@bountyhuntersrus.com"
            avatar_url = 'https://f.consider.it/galacticfederation/rodian.jpeg'
            break

        _.extend current_user, {name, email, avatar_url}
        save current_user


    SPAN null




# Router for the auth forms
window.Auth = ReactiveComponent
  displayName: 'Auth'

  render: ->
    current_user = fetch('/current_user')
    auth = fetch('auth')

    if auth.form == 'reset password'
      ResetPassword @props
    else if auth.form == 'verify email'
      VerifyEmail @props
    else if auth.form == 'login'
      Login @props
    else if auth.form == 'create account'
      CreateAccount @props
    else if auth.form == 'create account via invitation'
      CreateAccount by_invitation: true
    else if auth.form == 'user questions'
      HostQuestions @props
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
  .AUTH {}

  #AUTH_wrapper {
    margin: 0 auto;
    position: relative;
    z-index: 0;
    padding: 3em 0;
  }

  .AUTH_header {
    text-align: center;
    margin-bottom: 48px;
  }

  #AUTH_goal {
    font-size: 16px;
    text-align: center;
    color: white;
    margin-bottom: 8px;
    font-style: italic;
  }

  #AUTH_task {
    font-size: 38px;
    font-weight: 700;
    margin-bottom: 18px;
  }

  .AUTH_body_wrapper {
    padding: 3.5em 105px 4em 90px;
    font-size: 16px;
    box-shadow: 0 2px 4px rgba(0,0,0,.4), 0 0 100px rgb(255 255 255 / 40%);
    background-color: white;
    position: relative;
    border-radius: 16px;
  }

  .AUTH_cancel {
    background-color: transparent;
    border: none;
    opacity: .7;
  }

  .AUTH_cancel.floating {
    color: white;
    position: absolute;
    cursor: pointer;
    right: -46px;
    top: 16px;
    padding: 10px;
    font-size: 24px;
  }
  .AUTH_cancel.embedded {
    margin-top: 8px;
    padding: 8px 0 8px 8px;
    font-size: 18px;
    text-decoration: underline;
  }

  .AUTH_submit_button {
    font-size: 22px;
    display: block;
    width: 100%;
    margin-top: 20px;
    border-radius: 16px;
    padding: .8rem 1.5rem .8rem;
    background-color: #{selected_color};
  }

  .AUTH_field_wrapper {
    margin-bottom: 12px;
  }

  .AUTH_field_label {
    color: #444;
    font-size: 12px;
    display: block;
    text-transform: uppercase;
  }

  .AUTH_text_input {
    margin-bottom: 6px;
    width: 100%;
    border: 1px solid #ccc;
    padding: 10px 14px;
    font-size: #{if browser.is_mobile then 36 else 20}px;
    display: inline-block;
    background-color: #f2f2f2;
  }


  @media (max-width: 637px) {
    .AUTH_body_wrapper {
      padding: 2.5em 32px 3em 36px;
    }
  }


"""




########
# AuthForm
# 
# Mixin for common methods for auth forms
window.AuthForm =

  Draw: (options, children) -> 
    # docked_node_height = @refs.dialog?.offsetHeight
    # if @local.docked_node_height != docked_node_height
    #   @local.docked_node_height = docked_node_height
    #   save @local 

    cancel_modal = (e) ->
      options.before_cancel?()
      if location.pathname == '/proposal/new'
        loadPage '/'
      reset_key 'auth'


    DIV 
      className: 'AUTH'

      if !@props.no_modal
        DIV 
          id: 'lightbox'

      DIV
        id: if !@props.no_modal then 'modal'
        ref: if !@props.no_modal then 'dialog'
        role: if !@props.no_modal then 'dialog'
        'aria-labelledby': 'AUTH_task'
        'aria-describedby': if options.goal then 'AUTH_goal'


        DIV 
          id: 'AUTH_wrapper'
          style:
            maxWidth: AUTH_WIDTH()

          if !options.disallow_cancel && !@props.disallow_cancel

            BUTTON
              className: 'AUTH_cancel floating'
              title: translator 'shared.cancel_button', 'cancel'
              onClick: cancel_modal

              DIV 
                dangerouslySetInnerHTML: __html: '<svg x="0px" y="0px" fill="white" viewBox="0 0 64 80" enable-background="new 0 0 64 64" xml:space="preserve"><g><path d="M17.586,46.414C17.977,46.805,18.488,47,19,47s1.023-0.195,1.414-0.586L32,34.828l11.586,11.586   C43.977,46.805,44.488,47,45,47s1.023-0.195,1.414-0.586c0.781-0.781,0.781-2.047,0-2.828L34.828,32l11.586-11.586   c0.781-0.781,0.781-2.047,0-2.828c-0.781-0.781-2.047-0.781-2.828,0L32,29.172L20.414,17.586c-0.781-0.781-2.047-0.781-2.828,0   c-0.781,0.781-0.781,2.047,0,2.828L29.172,32L17.586,43.586C16.805,44.367,16.805,45.633,17.586,46.414z"/><path d="M32,64c8.547,0,16.583-3.329,22.626-9.373C60.671,48.583,64,40.547,64,32s-3.329-16.583-9.374-22.626   C48.583,3.329,40.547,0,32,0S15.417,3.329,9.374,9.373C3.329,15.417,0,23.453,0,32s3.329,16.583,9.374,22.626   C15.417,60.671,23.453,64,32,64z M12.202,12.202C17.49,6.913,24.521,4,32,4s14.51,2.913,19.798,8.202C57.087,17.49,60,24.521,60,32   s-2.913,14.51-8.202,19.798C46.51,57.087,39.479,60,32,60s-14.51-2.913-19.798-8.202C6.913,46.51,4,39.479,4,32   S6.913,17.49,12.202,12.202z"/></g></svg>'
                style: 
                  width: 30

          if options.goal
            DIV
              id: 'AUTH_goal'
              options.goal


          DIV
            className: "AUTH_body_wrapper"

            # The auth form's header
            DIV
              className: 'AUTH_header'
                  
              H1
                id: 'AUTH_task'

                options.task

              options.render_below_title?()


            children 

            BUTTON
              className: "btn AUTH_submit_button #{if @local.submitting then 'disabled'}"
              onClick: options.on_submit
              
              options.submit_button or @i18n().submit_button 

            if options.under_submit
              options.under_submit   

            # if !options.disallow_cancel
            #   DIV 
            #     style: 
            #       textAlign: 'right'
            #     BUTTON
            #       ref: 'cancel_dialog'
            #       className: 'AUTH_cancel embedded'
            #       title: translator 'shared.cancel_button', 'cancel'

            #       onClick: cancel_modal

            #       translator 'shared.cancel_button', 'cancel'


  RenderInput: (opts) -> 
    current_user = fetch '/current_user'
    type = opts.type or 'text'
    name = opts.name

    field_id = "user_#{name}"
    @local.updates ?= {}
    @local.updates[name] ?= current_user[name]
    
    DIV 
      key: field_id
      className: 'AUTH_field_wrapper'
      style: 
        opacity: if opts.disabled then .5

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
              opts.on_submit(event)

  Submit: (ev, opts) -> 
    current_user = fetch '/current_user'
    ev.preventDefault()
    opts ?= {}

    # Client side validation of user questions
    if opts.has_host_questions 
      @local.errors = errors_in_host_questions current_user.tags
    else 
      @local.errors = []

    if @local.errors.length == 0
      current_user.trying_to = opts.action

      if @local.updates
        _.extend current_user, @local.updates

      @local.submitting = true

      save current_user, =>
        @local.saved_successfully = current_user.errors.length + @local.errors.length == 0
        @local.submitting = false
        save @local
        if @local.saved_successfully
          opts.onSuccess?()

      if opts.has_avatar_upload
        upload_avatar()

    save @local

  ShowErrors: (errors) ->  
    current_user = fetch '/current_user'
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


  i18n: ->
    name_label: translator('auth.create.name_label', 'Your name or pseudonym')
    email_label: translator('auth.login.email_label', 'Your email')
    password_label: translator('auth.login.password_label', 'Your password')
    pic_prompt: translator('auth.create.pic_prompt', 'Your picture')
    code_label: translator('auth.code_entry', 'Code')
    successful_update: translator("auth.successful_update", "Updated successfully")
    verification_sent_message: translator('auth.verification_sent', 'We just emailed you a verification code. Copy / paste it below.')
    submit_button: translator("auth.submit", 'Done')






require './upload_avatar'
require './reset_password'
require './verify_email'
require './host_questions'
require './login_and_register'
