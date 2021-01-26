require './auth'

window.styles += """
"""

window.disallow_cancel = ->
  console.log permit('access forum')
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

  render: -> 
    i18n = auth_translations()
    auth = fetch 'auth'

    form = AuthForm 'login', @

    form.Draw 
      task: translator "auth.login.heading", 'Participant Login'
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      disallow_cancel: disallow_cancel()
      render_below_title: toggle_modes


      DIV null,

        form.RenderInput
          name: 'email'
          type: 'email'
          label: i18n.email_label

        form.RenderInput
          name: 'password' 
          type: 'password'
          label: i18n.password_label

        @resetPasswordLink()

        form.ShowErrors()

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


window.CreateAccount = ReactiveComponent
  displayName: 'CreateAccount'

  render: ->     
    i18n = auth_translations()
    current_user = fetch '/current_user'
    auth = fetch 'auth'
    form_name = if @props.by_invitation
                  'create account via invitation'
                else 
                  'create account'
    form = AuthForm form_name, @

    avatar_field = AvatarInput()
    pledges = @getPledges()

    form.Draw
      task: if @props.by_invitation 
              translator 'auth.create-by-invitation.heading', 'Complete registration'
            else 
              translator 'auth.create.heading', 'Create an account'
      disallow_cancel: disallow_cancel()
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      on_submit: (ev) ->
        current_user.signed_pledge = document.querySelectorAll('.pledge-input').length == document.querySelectorAll('.pledge-input:checked').length

        form.Submit ev, 
          has_host_questions: true
          has_avatar_upload: true
          check_considerit_terms: true
      render_below_title: if !@props.by_invitation then toggle_modes


      DIV null,
        form.RenderInput
          name: 'email'
          type: 'email'
          label: i18n.email_label
          disabled: if @props.by_invitation then true

        form.RenderInput
          name: 'password' 
          type: 'password'
          label: i18n.password_label

        form.RenderInput
          name: 'name'
          label: i18n.name_label

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
              padding: "24px 33px"
              backgroundColor: "#eee"
              marginTop: 18
              width: AUTH_WIDTH() - 18 * 2
              marginLeft: -50 + 18

            H4
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
                    id:"pledge-#{idx}"
                    name:"pledge-#{idx}"
                    style: 
                      fontSize: 24
                      verticalAlign: 'baseline'
                      marginLeft: 0

                  LABEL 
                    style: 
                      display: 'inline-block'
                      width: '90%'
                      paddingLeft: 8
                    htmlFor: "pledge-#{idx}"
                    dangerouslySetInnerHTML: __html: pledge

        @ConsideritTerms()

        form.ShowErrors()

        if customization('auth_footer')
          DIV 
            style:
              fontSize: 13
              color: auth_text_gray
              padding: '16px 0'
            dangerouslySetInnerHTML: {__html: customization('auth_footer')}


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
        marginTop: 24

      INPUT
        id: slugify("considerit_termsinputBox")
        key: "considerit_terms_inputBox"
        type:'checkbox'
        style: 
          fontSize: 24
          verticalAlign: 'baseline'
          marginLeft: 1
        defaultChecked: current_user.tags['considerit_terms']
        onChange: (event) =>        
          current_user.tags['considerit_terms'] = !current_user.tags['considerit_terms']

      LABEL
        htmlFor: slugify("considerit_termsinputBox")
        style: 
          fontSize: 18
          paddingLeft: 8
        dangerouslySetInnerHTML: __html: terms


