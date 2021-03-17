require './auth'

window.styles += """
"""

window.disallow_cancel = ->
  permit('access forum') < 0

toggle_modes = ->
  auth = fetch 'auth'

  if auth.form == 'create account'
    toggle_to = translator "auth.log_in", 'Log in'
  else
    toggle_to = translator "auth.login.toggle_to_create", 'Create an account'

  DIV
    style:
      textAlign: 'center'

    DIV
      style: 
        marginBottom: 12
        width: '100%'

      SPAN 
        style: 
          # color: 'white'
          fontWeight: 300
          fontSize: 16

        if auth.form == 'create account'
          TRANSLATE 'auth.create.should_you_be_here', 'Already have an account?'
        else 
          TRANSLATE 'auth.login.should_you_be_here', 'Not registered?'
      
      " "
      BUTTON
        className: 'toggle_auth'
        style:
          display: 'inline-block'
          # color: 'white'
          textDecoration: 'underline'
          fontWeight: 600
          fontSize: 16
          backgroundColor: 'transparent'
          border: 'none'
          padding: 0
        onClick: (e) =>
          current_user = fetch('/current_user')
          auth.form = if auth.form == 'create account' then 'login' else 'create account'
          save auth
          setTimeout =>
            $('#user_email')[0].focus()
          , 0
        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            e.target.click()
            e.preventDefault()

        toggle_to




window.Login = ReactiveComponent
  displayName: 'Login'
  mixins: [AuthForm, Modal]

  render: -> 
    i18n = @i18n()
    auth = fetch 'auth'

    on_submit = (ev) =>
      @Submit ev,
        action: 'login'

    @Draw 
      task: translator "auth.login.heading", 'Login to Participate'
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      disallow_cancel: disallow_cancel()
      render_below_title: toggle_modes
      on_submit: on_submit
      submit_button: translator "auth.log_in", 'Log in'

      DIV null,

        @RenderInput
          name: 'email'
          type: 'email'
          label: i18n.email_label
          on_submit: on_submit

        @RenderInput
          name: 'password' 
          type: 'password'
          label: i18n.password_label
          on_submit: on_submit

        @resetPasswordLink()

        @ShowErrors()

        if customization('login_footer')
          auth = fetch('auth')
          if auth.form == 'login'
            DIV 
              style:
                fontSize: 13
                color: auth_text_gray
                padding: '16px 0'
              dangerouslySetInnerHTML: {__html: customization('login_footer')}


  ####
  # resetPasswordLink
  #
  # "I forgot my password!"
  resetPasswordLink : -> 
    reset = (e) => 
      # Tell the server to email us a token
      current_user = fetch('/current_user')
      current_user.trying_to = 'send_password_reset_token'
      if @local.updates?.email?.length > 0 
        current_user.email = @local.updates.email 
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
          color: '#333'
          backgroundColor: 'transparent'
          border: 'none'
          fontSize: 16
          padding: 0
          position: 'relative'
          top: -8

        onClick: reset
        onKeyDown: (e) =>
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            reset(e)  
            e.preventDefault()


        translator('auth.forgot_password.link', 'Help! I forgot my password') 


window.CreateAccount = ReactiveComponent
  displayName: 'CreateAccount'
  mixins: [AuthForm, Modal]

  render: ->     
    i18n = @i18n()
    current_user = fetch '/current_user'
    auth = fetch 'auth'
    form_name = if @props.by_invitation
                  'create account via invitation'
                else 
                  'create account'

    avatar_field = AvatarInput()
    pledges = @getPledges()

    on_submit = (ev) =>
      current_user.signed_pledge = document.querySelectorAll('.pledge-input').length == document.querySelectorAll('.pledge-input:checked').length

      @Submit ev, 
        action: form_name
        has_host_questions: true
        has_avatar_upload: true
        check_considerit_terms: true

    @Draw
      task: if @props.by_invitation 
              translator 'auth.create-by-invitation.heading', 'Complete registration'
            else 
              translator 'auth.create.heading', 'Create an account'
      disallow_cancel: disallow_cancel()
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      on_submit: on_submit
      render_below_title: if !@props.by_invitation then toggle_modes
      submit_button: translator "shared.auth.sign_up", "Sign up"

      DIV null,
        @RenderInput
          name: 'email'
          type: 'email'
          label: i18n.email_label
          disabled: if @props.by_invitation then true
          on_submit: on_submit

        @RenderInput
          name: 'password' 
          type: 'password'
          label: i18n.password_label
          on_submit: on_submit

        @RenderInput
          name: 'name'
          label: i18n.name_label
          on_submit: on_submit

        if avatar_field
          DIV 
            className: 'AUTH_field_wrapper'
            style: 
              marginBottom: 8

            LABEL 
              className: 'AUTH_field_label'
              i18n.pic_prompt

            avatar_field

        ShowHostQuestions()

        if pledges.length > 0 
        
          DIV
            style: 
              marginTop: 18

            LABEL
              className: 'AUTH_field_label'
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
                    className: 'bigger'
                    id:"pledge-#{idx}"
                    name:"pledge-#{idx}"
                    style: 
                      verticalAlign: 'baseline'
                      marginLeft: 1
                      marginTop: 7

                  LABEL 
                    style: 
                      display: 'inline-block'
                      width: '90%'
                      paddingLeft: 8
                    htmlFor: "pledge-#{idx}"
                    dangerouslySetInnerHTML: __html: pledge

        @ConsideritTerms()

        @ShowErrors()

        if customization('auth_footer')
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


  getPledges: ->
    if !customization('auth_require_pledge')
      return []
    else if customization('pledge')
      return customization('pledge')
    else 
      return [translator('auth.create.pledge.one_account', 'I will use only one account'), 
                 translator('auth.create.pledge.no_attacks', 'I will not attack or mock others')]

  ConsideritTerms: -> 
    current_user = fetch '/current_user'

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
        margin: '18px 0'

      INPUT
        id: slugify("considerit_termsinputBox")
        key: "considerit_terms_inputBox"
        type:'checkbox'
        className: 'bigger'
        style: 
          verticalAlign: 'baseline'
          marginLeft: 1
        defaultChecked: false

      LABEL
        htmlFor: slugify("considerit_termsinputBox")
        style: 
          fontSize: 18
          paddingLeft: 8
        dangerouslySetInnerHTML: __html: terms


