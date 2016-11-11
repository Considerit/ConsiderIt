require '../auth'

window.CustomerSignup = ReactiveComponent
  displayName: 'CustomerSignup'

  render : -> 
    current_user = fetch('/current_user')

    auth = fetch('auth')
    if !current_user.logged_in && !auth.form
      auth.form = 'create account'
      save auth

    DIV 
      style: 
        padding: "20px 40px"
        marginTop: 60
        color: 'white'


      if !@local.successful

        H2
          style: _.extend {}, h2

          "Let's get you setup with the Basic Plan"

      if !@local.successful
        DIV
          style: _.extend {}, small_text,
            textAlign: 'center'
            

          SPAN 
            style:
              textDecoration: if current_user.logged_in then 'line-through'
              display: 'inline-block'
              marginRight: 40
              fontWeight: if !current_user.logged_in then 600

            'Step 1: Create your account'

          SPAN 
            style: 
              textDecoration: if @local.successful then 'line-through'            
              fontWeight: if current_user.logged_in && !@local.successful then 600 else 300

            'Step 2: Create your site'


      if !current_user.logged_in 
        @drawAuth()
      else if @local.successful
        @drawGotoSubdomain()
      else
        @drawCreateSubdomain()

      if current_user.logged_in && current_user.is_super_admin && !@local.successful
        A
          style: 
            display: 'block'
            opacity: .1
            marginTop: 40
          onClick: logout
          'Logout'

  drawAuth: -> 
    DIV 
      style:
        margin: '30px auto'
        width: DECISION_BOARD_WIDTH()

      Auth
        naked: true

  drawGotoSubdomain: -> 

    new_sub = fetch('new_subdomain')
    current_user = fetch('/current_user')
    
    DIV
      style:
        margin: '40px auto'
        textAlign: 'center'
        color: 'white'

      DIV 
        style:           
          borderRadius: 8
          backgroundColor: logo_red
          fontSize: 24

        "Success! Visit your shiny new Consider.it site:"

      A 
        style: 
          display: 'inline-block'
          marginTop: 30
          backgroundColor: logo_red
          fontSize: 48
          borderBottom: '2px solid white'

        href: "#{location.protocol}//#{@local.successful}.#{location.hostname}?u=#{current_user.email}&t=#{new_sub.t}&nvn=1"

        "#{location.protocol}//#{@local.successful}.#{location.hostname}"


      DIV 
        style: 
          marginTop: 30

        IMG
          src: asset("product_page/kevin1.jpg")
          style:
            borderRadius: "50%"
            display: "inline-block"
            width: 75
            height: 75
            textAlign: "center"  
            boxShadow: "0px 2px 2px rgba(0,0,0,.1)"

        SPAN
          style: 
            display: 'inline-block'
            marginLeft: 30
            fontSize: 24
            position: 'relative'
            top: -27

          "Kevin will reach out soon to help you get situated."




  drawCreateSubdomain: ->     
    current_user = fetch '/current_user'

    DIV 
      style:
        margin: '30px auto'
        width: DECISION_BOARD_WIDTH()

      DIV 
        style: 
          margin: '20px 0'

        "#{current_user.name.split(' ')[0]}, please name your Consider.it site:"


      INPUT
        ref: 'subdomain_name'
        style: 
          display: 'block'
          border: "1px solid #{auth_ghost_gray}"
          padding: '8px 16px'
          fontSize: 20
          width: DECISION_BOARD_WIDTH()
         
        placeholder: 'Name your Consider.it site'


      BUTTON 
        className: 'primary_button'
        type: 'submit'
        style: 
          fontSize: 24

        onClick: => 
          subdomain_name = $(@refs.subdomain_name.getDOMNode()).val()
          name = subdomain_name.replace(/ /g, '-').replace(/\W/g, '')

          $.ajax '/subdomain', 
            data: 
              subdomain: name
              app_title: subdomain_name
              authenticity_token: current_user.csrf
              plan: @props.plan
            type: 'POST'
            success: (data) => 
              if data[0].errors
                @local.errors = data[0].errors
              else
                @local.successful = data[0].name
                save data[0]
              save @local


        'Create my site'

      if @local.errors && @local.errors.length > 0
        DIV 
          style: 
            borderRadius: 8
            margin: 20
            padding: 20
            backgroundColor: '#FFE2E2'

          H1 style: {fontSize: 18}, 'Ooops!'

          for error in @local.errors
            DIV 
              style: 
                marginTop: 10
              error
