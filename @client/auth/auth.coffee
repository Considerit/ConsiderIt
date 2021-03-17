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
    if (!@local.logged_in_last_render && current_user.logged_in) || \
       (auth.form == 'verify email' && current_user.verified) || \
       (auth.form == 'user questions' && !current_user.needs_to_complete_profile)
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
      ResetPassword()
    else if auth.form == 'verify email'
      VerifyEmail()
    else if auth.form == 'login'
      Login()
    else if auth.form == 'create account'
      CreateAccount()
    else if auth.form == 'create account via invitation'
      CreateAccount by_invitation: true
    else if auth.form == 'user questions'
      HostQuestions()
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
    margin-bottom: 24px;
  }

  #AUTH_goal {
    font-size: 16px;
    text-align: center;
    color: white;
    margin-bottom: 8px;
    font-style: italic;
  }

  #AUTH_task {
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
    margin-bottom: 12px;
  }

  .AUTH_field_label {
    color: #444;
    font-size: 16px;
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


"""



########
# AuthForm
# 
# Mixin for common methods for auth forms
window.AuthForm =

  Draw: (options, children) -> 
    docked_node_height = @refs.dialog?.getDOMNode().offsetHeight
    if @local.docked_node_height != docked_node_height
      @local.docked_node_height = docked_node_height
      save @local 

    cancel_modal = (e) ->
      options.before_cancel?()
      if location.pathname == '/proposal/new'
        loadPage '/'
      reset_key 'auth'

    DIV 
      className: 'AUTH'

      DIV 
        id: 'lightbox'

      DIV
        id: 'modal'
        ref: 'dialog'
        role: 'dialog'
        'aria-labeledby': 'AUTH_task'
        'aria-describedby': if options.goal then 'AUTH_goal'


        DIV 
          id: 'AUTH_wrapper'
          style:
            width: AUTH_WIDTH()

          if !options.disallow_cancel

            BUTTON
              className: 'AUTH_cancel floating'
              title: translator 'shared.cancel_button', 'cancel'

              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  e.target.click()
                  e.preventDefault()

              onClick: cancel_modal

              DIV 
                dangerouslySetInnerHTML: __html: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" fill="white" viewBox="0 0 64 80" enable-background="new 0 0 64 64" xml:space="preserve"><g><path d="M17.586,46.414C17.977,46.805,18.488,47,19,47s1.023-0.195,1.414-0.586L32,34.828l11.586,11.586   C43.977,46.805,44.488,47,45,47s1.023-0.195,1.414-0.586c0.781-0.781,0.781-2.047,0-2.828L34.828,32l11.586-11.586   c0.781-0.781,0.781-2.047,0-2.828c-0.781-0.781-2.047-0.781-2.828,0L32,29.172L20.414,17.586c-0.781-0.781-2.047-0.781-2.828,0   c-0.781,0.781-0.781,2.047,0,2.828L29.172,32L17.586,43.586C16.805,44.367,16.805,45.633,17.586,46.414z"/><path d="M32,64c8.547,0,16.583-3.329,22.626-9.373C60.671,48.583,64,40.547,64,32s-3.329-16.583-9.374-22.626   C48.583,3.329,40.547,0,32,0S15.417,3.329,9.374,9.373C3.329,15.417,0,23.453,0,32s3.329,16.583,9.374,22.626   C15.417,60.671,23.453,64,32,64z M12.202,12.202C17.49,6.913,24.521,4,32,4s14.51,2.913,19.798,8.202C57.087,17.49,60,24.521,60,32   s-2.913,14.51-8.202,19.798C46.51,57.087,39.479,60,32,60s-14.51-2.913-19.798-8.202C6.913,46.51,4,39.479,4,32   S6.913,17.49,12.202,12.202z"/></g></svg>'
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
              className: "AUTH_submit_button #{if @local.submitting then 'disabled'}"
              onClick: options.on_submit
              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  e.target.click()
                  e.preventDefault()
              
              options.submit_button or @i18n().submit_button      

            if !options.disallow_cancel
              DIV 
                style: 
                  textAlign: 'right'
                BUTTON
                  ref: 'cancel_dialog'
                  className: 'AUTH_cancel embedded'
                  title: translator 'shared.cancel_button', 'cancel'

                  onKeyDown: (e) => 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      e.target.click()
                      e.preventDefault()

                  onClick: cancel_modal

                  translator 'shared.cancel_button', 'cancel'


  RenderInput: (opts) -> 
    current_user = fetch '/current_user'
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

    if opts.check_considerit_terms && !document.getElementById('considerit_termsinputbox').checked
      @local.errors.push translator('auth.validation.agree_to_terms', "To proceed, you must agree to the terms") 

    if @local.errors.length == 0
      current_user.trying_to = opts.action

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
    name_label: translator('auth.create.name_label', 'Your name')
    email_label: translator('auth.login.email_label', 'Your email')
    password_label: translator('auth.login.password_label', 'Your password')
    pic_prompt: translator('auth.create.pic_prompt', 'Your picture')
    code_label: translator('auth.code_entry', 'Code')
    successful_update: translator("auth.successful_update", "Updated successfully")
    verification_sent_message: translator('auth.verification_sent', 'We just emailed you a verification code. Copy / paste it below.')
    submit_button: translator("auth.submit", 'Submit')


######
# Modal
#
# Mixin for handling some aspects of accessible modal forms
# Currently makes the first element with role=dialog exclusively focusable, unless there exists an @refs.dialog
# Will cancel on ESC if there exists a cancel button with @ref=cancel_dialog
# Code influenced by: 
#    - https://uxdesign.cc/how-to-trap-focus-inside-modal-to-make-it-ada-compliant-6a50f9a70700
#    - https://bitsofco.de/accessible-modal-dialog/
window.styles += """
#lightbox {
  position: fixed;
  top: 0;
  left: 0;
  background: rgba(0,0,0,.8);
  width: 100vw;
  height: 100vh;
  z-index: 99999;
}
"""

window.Modal =

  accessibility_on_keydown: (e) ->

    # cancel on ESC if a cancel button has been defined
    if e.key == 'Escape' || e.keyCode == 27
      @refs.cancel_dialog?.getDOMNode().click()

    # trap focus
    is_tab_pressed = e.key == 'Tab' or e.keyCode == 9
    if !is_tab_pressed
      return
    if e.shiftKey
      # if shift key pressed for shift + tab combination
      if document.activeElement == @first_focusable_element
        @last_focusable_element.focus()
        # add focus for the last focusable element
        e.preventDefault()
    else
      # if tab key is pressed
      if document.activeElement == @last_focusable_element
        # if focused has reached to last focusable element then focus first focusable element after pressing tab
        @first_focusable_element.focus()
        # add focus for the first focusable element
        e.preventDefault()

    return

  componentDidMount: ->
    @focused_element_before_opening = document.activeElement

    ######################################
    # For capturing focus inside the modal
    # add all the elements inside modal which you want to make focusable
    focusable_elements = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    modal = @refs?.dialog?.getDOMNode() or document.querySelector '[role=dialog]'

    # select the modal by it's id
    @first_focusable_element = modal.querySelectorAll(focusable_elements)[0]
    # get first element to be focused inside modal
    focusable_content = modal.querySelectorAll(focusable_elements)
    @last_focusable_element = focusable_content[focusable_content.length - 1]

    # get last element to be focused inside modal
    document.addEventListener 'keydown', @accessibility_on_keydown

    modal.querySelector('input').focus()


    #####################
    # For preventing scroll outside of the modal, and allowing scroll within, 
    # all while making it seem like the whole page is scrollable. 
    _.extend modal.style,
      position: 'fixed'
      top: 0
      left: 0
      width: '100vw'
      height: '100vh'
      overflow: 'auto'
      zIndex: 99999
      paddingBottom: if browser.is_mobile then "150px"

    scroll_bar_width = window.innerWidth - document.body.offsetWidth
    _.extend document.body.style,
      marginRight: scroll_bar_width
      overflow: 'hidden'
      position: 'fixed'
  
  componentWillUnmount: -> 
    # return the focus to the element that had focus when the modal was launched
    if @focused_element_before_opening && document.body.contains(@focused_element_before_opening)
      @focused_element_before_opening.focus()
    document.removeEventListener 'keydown', @accessibility_on_keydown

    _.extend document.body.style,
      marginRight: null
      overflow: null
      position: null







require './upload_avatar'
require './reset_password'
require './verify_email'
require './host_questions'
require './login_and_register'
