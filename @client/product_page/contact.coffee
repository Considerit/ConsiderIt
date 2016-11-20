window.Contact = ReactiveComponent
  displayName: 'Contact'

  render: -> 

    DIV null,

      @heading()

      @form_chooser()

      @form()

      @letter()

  heading: -> 
    DIV 
      style: 
        paddingTop: 40
        width: SAAS_PAGE_WIDTH()
        margin: 'auto'
        textAlign: 'center'

      H1
        style: 
          fontSize: 50
          fontWeight: 400
          color: 'white'

        "Hi friend, how can we help?"

      DIV 
        style: 
          fontSize: 18
          color: 'white'
          marginTop: 8

        'Please introduce yourself, we’d be delighted to hear from you.'

  form_chooser: -> 
    set_form = => 
      loc = fetch 'location'
      loc.query_params.form = forms[@local.current_form].id 
      save loc 

    if !@local.current_form?
      loc = fetch 'location'
      if loc.query_params.form 
        for form, idx in forms 
          if form.id == loc.query_params.form 
            @local.current_form = idx 
            break 
      @local.current_form ||= 0

    DIV 
      style: 
        position: 'relative'
        textAlign: 'center'
        top: 40

      SELECT 
        className: 'unstyled'
        style: 
          fontSize: 24
          padding: '28px 40px'
          fontWeight: 400
          backgroundSize: '24px 20px'
          backgroundColor: 'white'
          border: '1px solid #979797'
          borderRadius: 32
        value: @local.current_form
        onChange: (e) => 
          @local.current_form = e.target.value 
          save @local
          set_form()
          document.activeElement.blur()

        for n,idx in forms
          OPTION 
            value: idx
            style: {}

            n.question

  form: -> 

    current_form = forms[@local.current_form]
    submit_click = (e) => 
      e.preventDefault()
      
      c = 
        key: '/new/contact_us'

      for p in @refs.form.getDOMNode().elements when p.name.length > 0
        c[p.name] = p.value 

      @local.errors = null
      @local.successful = null 
      save c, (resp) => 
        if c.errors.length > 0
          @local.errors = c.errors
        else 
          @local.successful = true
        save @local
    DIV 
      style: 
        paddingTop: 80
        paddingBottom: 300
        backgroundColor: '#F4F4F4'

      DIV 
        style: 
          backgroundColor: 'white'
          maxWidth: 500
          margin: 'auto'
          padding: '40px 60px'
          boxShadow: '0 1px 2px rgba(0,0,0,.2)'

        FORM 
          action: '/contact_us'
          method: 'post'   
          ref: 'form'       

          for field in current_form.fields
            DIV 
              style: 
                paddingBottom: 24
              LABEL 
                style: 
                  fontSize: 16
                  display: 'block'
                  paddingBottom: 2
                htmlFor: slugify field.label
                field.label

              if field.form 
                field.form()

              else 
                field.tag 
                  name: slugify field.label
                  id: slugify field.label
                  required: if !field.optional then true
                  style: 
                    width: '100%'
                    fontSize: 16
                    padding: '4px 8px'
                    border: '1px solid #ddd'
                    height: if field.tag == TEXTAREA then 100

              if !field.optional
                DIV 
                  style: 
                    fontSize: 10
                    color: '#777'
                  'required'

          DIV 
            style: 
              position: 'relative'
              top: 20
              textAlign: 'center'

            INPUT 
              type: 'hidden'
              name: 'inquiry'
              value: current_form.question

            # INPUT 
            #   type: 'hidden'
            #   value: fetch('/current_user').csrf
            #   name: 'authenticity_token'

            BUTTON

              style: _.extend {}, big_button(), 
                width: '100%'
              onClick: submit_click
              onKeyPress: (e) => 
                if e.which == 32 || e.which == 13
                  submit_click(e)

              'Deliver to Consider.it'

            if @local.errors
              for error in @local.errors 

                DIV 
                  style: 
                    color: 'red'
                    fontSize: 14
                    paddingTop: 20                    
                  error 
            if @local.successful
              DIV 
                style: 
                  color: primary_color()
                  fontSize: 14
                  paddingTop: 20
                'Thank you for your message. We will be in touch.'

  letter: -> 
    height = 390 * SAAS_PAGE_WIDTH() / 1160
    width = 1160 * SAAS_PAGE_WIDTH() / 1160

    full = SAAS_PAGE_WIDTH() > 960 && !browser.is_mobile 

    DIV 
      style: 
        backgroundColor: 'white'

      DIV 
        style: 
          position: 'relative'
          top: -height / 2
          backgroundColor: 'white'
          margin: 'auto'
          width: width
          height: if full then height
          boxShadow: '0 1px 3px rgba(0,0,0,.4)'
          textAlign: if !full then 'center'
          padding: if !full then '40px 40px'

        DIV 
          style:  
            position: if full then 'absolute'
            left: 50
            top: 30
            fontSize: 24
            fontWeight: 600
            color: if !full then primary_color()

          'Shy about filling out a form? '
          if full 
            BR null
          'Mail us a nice letter instead!'

        DIV 
          style: css.crossbrowserify
            position: if full then 'absolute'
            left: '25%'
            top: '40%'
            paddingTop: if !full then 50
            fontSize: 24
            fontWeight: 600
            display: 'flex'
            flexDirection: if !full then 'column'

          DIV 
            style: css.crossbrowserify
              flex: '1 1 auto'

            DIV 
              style: {}
              'Deliver Electronically'

            A 
              href: 'mailto:hello@consider.it'
              style: 
                textDecoration: 'underline'
                fontWeight: 400
                fontSize: if full then 22 else 16
              'hello@consider.it'

          DIV 
            style: css.crossbrowserify
              flex: '1 1 auto'
              padding: 20
              fontWeight: 400
            'or'

          DIV 
            style: css.crossbrowserify
              flex: '1 1 auto'
              padding: '0px 20px'

            DIV 
              style: {}
              'via Postal Service'

            DIV 
              style: 
                fontWeight: 400
                fontSize: if full then 22 else 16

              'Consider.it' 
              BR null
              '2420 NE Sandy Blvd'
              BR null
              'Suite 126' 
              BR null
              'Portland, OR 97232'

        if full 
          DIV 
            style: 
              position: 'absolute'
              right: 20
              top: 16

            IMG 
              src: asset('product_page/wwstamp.png')
              width: SAAS_PAGE_WIDTH() * 84 / 1160
              height: SAAS_PAGE_WIDTH() * 132 / 1160



forms = [
  {
    id: 'general_inquiry'
    question: "General inquiry"
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'Your organization'
        tag: INPUT
      }
      {
        label: 'What can we help you with?'
        tag: TEXTAREA
      }

    ]
  }
  {
    id: 'request_demo'
    question: "Let's schedule a demo"
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'Your organization'
        tag: INPUT
      }
      {
        label: 'A basic description of your goal for a dialogue'
        tag: TEXTAREA
      }
      {
        label: 'How did you learn about Consider.it?'
        tag: TEXTAREA
        optional: true            
      }
    ]
  }
  {
    id: 'consulting_inquiry'
    question: 'Will your consulting services help my project?'
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'Your organization'
        tag: INPUT
      }
      {
        label: 'Describe your project'
        tag: TEXTAREA
      }
      {
        label: 'Approximate budget'
        tag: INPUT
        optional: true
      }
      {
        label: 'How did you learn about Consider.it?'
        tag: TEXTAREA
        optional: true
      }
    ]
  }
  {
    id: 'consultant_partnership'
    question: "I'm interested in the consultant partnership"
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'Your organization'
        tag: INPUT
      }
      {
        label: 'Describe your practice'
        tag: TEXTAREA
        optional: true
      }
      {
        label: 'How did you learn about Consider.it?'
        tag: TEXTAREA
        optional: true
      }
    ]
  }
  {
    id: 'upgrade_to_unlimited'
    question: 'I\'d like to upgrade to an Unlimited Forum'
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'The Consider.it forum you\'re upgrading'
        form: -> 
          url_hint = 
            color: '#aaa'

          DIV null,
            SPAN 
              style: url_hint
              'https://'

            INPUT
              type: 'text'
              name: slugify @label
              id: slugify @label
              style: 
                fontSize: 16
                padding: '4px 8px'
                border: '1px solid #ddd'

            SPAN 
              style: url_hint                
              '.consider.it'
      }
    ]
  }

  {
    id: 'start_enterprise'
    question: "My organization is interested in the Enterprise plan"
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'Your organization'
        tag: INPUT
      }
    ]
  }

  {
    id: 'discount'
    question: "My project could use a discount..."
    fields: [
      {
        label: 'Your name'
        tag: INPUT
      }
      {
        label: 'Your email'
        tag: INPUT
      }
      {
        label: 'Your organization'
        tag: INPUT
      }
      {
        label: 'Describe your project, including its public benefit'
        tag: TEXTAREA
      }
      {
        label: 'Approximate budget'
        tag: INPUT
      }
      {
        label: 'What do you need that the Free Forum does not provide?'
        tag: TEXTAREA
      }
      {
        label: 'How did you learn about Consider.it?'
        tag: TEXTAREA
        optional: true
      }
    ]
  }
]



#     DIV 
#       id: 'contact'
#       style:
#         marginTop: 80
#         backgroundColor: 'white'
#         color: 'white'
#         padding: '80px 0'
#         position: 'relative'

#       DIV 
#         style: cssTriangle 'bottom', 'white', 133, 30,
#           position: 'absolute'
#           left: '50%'
#           marginLeft: - 133 / 2
#           top: 0

#       H1
#         style: _.extend {}, h1, 
#           marginBottom: 30
#           color: 'white'

#         # "Get in touch with us,"
#         # BR null
#         "Contact us"


#       team()

#       DIV 
#         style: _.extend {}, base_text,
#           margin: '20px auto'
#           width: 675 #TEXT_WIDTH 
#           #textAlign: 'center'
#         "Hi, we’re the Consider.it team and we’d love to hear from you. "

#         "Write us a nice electronic letter at "
#         A
#           href: "mailto:admin@consider.it"
#           style: _.extend {}, a, 
#             color: 'white'
#             borderBottomColor: 'white'

#           "admin@consider.it"
#         "."

#         @mailchimpForm "we can write to you", "write to me"


#       DIV 
#         style: cssTriangle 'bottom', logo_red, 133, 30,
#           position: 'absolute'
#           left: '50%'
#           marginLeft: - 133 / 2
#           bottom: -30      

#   mailchimpForm: (prompt, label) -> 

#     DIV 
#       style: {}


#       " Or "

#       A  
#         style:
#           color: 'white'
#           border: 'none'
#           borderBottom: '1px solid white'
#           fontSize: 24
#         onClick: => @local.click_contactme = !@local.click_contactme; save @local

#         prompt

#       if @local.click_contactme 
#         ':' 
#       else 
#         '.'

#       if @local.click_contactme
#         FORM    
#           action: "//Consider.us7.list-manage.com/subscribe/post?u=9cc354a37a52e695df7b580bd&amp;id=d4b6766b00"
#           id: "mc-embedded-subscribe-form"
#           method: "post"
#           name: "mc-embedded-subscribe-form"
#           novalidate: "true"
#           target: "_blank"
#           style:
#             margin: "10px 0 20px 0"
#             # textAlign: 'center'
#             display: 'inline-block'

#           INPUT
#             id: "mce-EMAIL"
#             name: "EMAIL"
#             placeholder: "email address"
#             type: "email"
#             defaultValue: ""
#             style:
#               fontSize: 24
#               padding: "8px 12px"
#               width: 380
#               border: '1px solid white'
#               backgroundColor: logo_red
#               color: 'white'

#           BUTTON
#             name: "subscribe"
#             type: "submit"
#             style:
#               fontSize: 24
#               marginLeft: 8
#               display: "inline-block"
#               backgroundColor: if @local.hover_contactme then 'white' else logo_red
#               color: if @local.hover_contactme then logo_red else 'white'
#               fontWeight: 500
#               border: "1px solid #{if @local.hover_contactme then 'transparent' else 'white'}"
#               borderRadius: 16
#               padding: '8px 18px'
#             onMouseEnter: => @local.hover_contactme = true; save @local
#             onMouseLeave: => @local.hover_contactme = false; save @local

#             label


# team = -> 
#   members = [{
#       img: 'travis1'
#       name: "Travis Kriplean"
#       email: 'travis@consider.it'
#       location: 'Portland, OR'
#     },{
#       img: 'kevin1'
#       name: "Kevin Miniter"
#       email: 'kevin@consider.it'
#       location: 'Portland, OR'      
#     },{
#       img: 'mike1'
#       name: "Mike Toomim"
#       email: 'toomim@consider.it'
#       location: 'Montreal'
#     }
#   ]

#   DIV 
#     style: _.extend {}, base_text,
#       textAlign: 'center'
#       marginTop: 30

#     for t, idx in members
#       DIV
#         key: idx
#         style:
#           display: "inline-block"
#           margin: "20px 30px"
#           textAlign: "center"
#           width: 180


#         A
#           href: "mailto:#{t.email}"

#           IMG
#             src: asset("product_page/#{t.img}.jpg")
#             style:
#               borderRadius: "50%"
#               display: "inline-block"
#               width: 150
#               height: 150
#               textAlign: "center"  
#               boxShadow: "0px 2px 2px rgba(0,0,0,.1)"

#           BR null

#           SPAN
#             style: _.extend {}, a, 
#               textAlign: "center"
#               #borderBottom: 'none'
#               borderBottomColor: 'white'              
#               color: 'white'
#             t.name

#           BR null

#           SPAN 
#             style: _.extend {}, small_text

#             t.location

#           BR null

#           SPAN 
#             style: _.extend {}, small_text,
#               position: 'relative'
#               top: -7

#             t.email





# styles += """

# #contact ::-webkit-input-placeholder{
#   color: white;
#   opacity: .7;
# } 
# #contact  :-moz-placeholder{
#   color: white;
#   opacity: .7;
# } 
# #contact ::-moz-placeholder {
#   color: white;
#   opacity: .7;
# } 
# #contact ::-ms-input-placeholder {
#   color: white;
#   opacity: .7;
# }
# #contact input[type=email]:focus {
#   border-color: white;
#   outline: none;
# }
# """