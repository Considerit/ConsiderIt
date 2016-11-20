require '../auth'

window.CustomerSignup = ReactiveComponent
  displayName: 'CustomerSignup'

  render : -> 
    current_user = fetch('/current_user')

    auth = fetch('auth')
    if !current_user.logged_in && !auth.form
      auth.form = 'create account'
      save auth

    domain_hint = 
      color: 'rgba(255,255,255,.8)'
      fontSize: 28
      padding: '0 2px'

    compact = browser.is_mobile || SAAS_PAGE_WIDTH() < 800

    loc = fetch('location')
    if loc.query_params.error 
      @local.errors = [decodeURIComponent(loc.query_params.error)]
      save @local 
      delete loc.query_params.error 
      save loc 

    FORM 
      action: '/subdomain'
      method: 'POST'


      DIV 
        style: 
          paddingTop: 40
          paddingBottom: 60
          width: SAAS_PAGE_WIDTH()
          margin: 'auto'
          fontSize: if compact then 34 else 50
          color: 'white'
          textAlign: 'center'

        'Give your Free Forum a name'

        DIV 
          style: 
            paddingBottom: 10

          SPAN
            style: domain_hint
            'https://'
          INPUT
            type: 'text'
            name: 'subdomain'
            ref: 'subdomain_name'
            style: 
              border: "1px solid #{auth_ghost_gray}"
              padding: '8px 16px'
              fontSize: 20
          SPAN
            style: domain_hint
            '.consider.it'           


        DIV 
          style: 
            fontSize: 14
            color: 'rgba(255,255,255,.6)'
            marginTop: 8

          'You can upgrade later if you want an Unlimited Forum.'


      DIV 
        style: 
          backgroundColor: 'white'
          textAlign: 'center'
          borderTop: "1px solid rgb(101, 136, 64)"
        
        INPUT 
          type: 'hidden'
          name: 'authenticity_token' 
          value: current_user.csrf

        INPUT 
          type: 'hidden'
          name: 'plan' 
          plan: 0

        INPUT 
          type: 'submit'
          disabled: if !current_user.logged_in then true 
          style: _.extend {}, big_button(),
            opacity: if !current_user.logged_in then 0
            backgroundColor: 'rgb(101, 136, 64)'
            cursor: if !current_user.logged_in then 'auto' else 'pointer'
            position: 'relative'
            top: -26

          value: 'Create my forum'

        if @local.errors && @local.errors.length > 0
          DIV 
            style: 
              padding: 40
              backgroundColor: '#FFE2E2'
              maxWidth: 500
              margin: 'auto'

            H1 style: {fontSize: 18}, 'Ooops!'

            for error in @local.errors
              DIV 
                style: 
                  marginTop: 10
                error



      DIV 
        style: 
          backgroundColor: 'white'
          padding: '0px 10px'

        if !current_user.logged_in 

          DIV null,
            H2 
              style: 
                fontSize: 36
                fontWeight: 400
                paddingBottom: 40
                textAlign: 'center'

              'Please introduce yourself first'


            @drawAuth()


        if current_user.logged_in && current_user.is_super_admin
          A
            style: 
              opacity: .1
              marginTop: 40
            onClick: logout
            'Logout'

  componentDidMount: -> 
    @refs.subdomain_name.getDOMNode().focus()

  drawAuth: -> 
    DIV 
      style:
        margin: '0px auto'
        width: DECISION_BOARD_WIDTH()

      Auth
        naked: true
        disable_cancel: true
        primary_color: primary_color()





  drawCreateSubdomain: ->     
    current_user = fetch '/current_user'

    domain_hint = 
      color: '#aaa'
      fontSize: 20

    DIV 
      style:
        margin: '30px auto'
        width: DECISION_BOARD_WIDTH()



