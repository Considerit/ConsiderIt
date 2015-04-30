window.Contact = ReactiveComponent
  displayName: 'Contact'

  render: -> 
  
    DIV 
      id: 'contact'
      style:
        marginTop: 80
        backgroundColor: logo_red
        color: 'white'
        padding: '80px 0'
        position: 'relative'

      DIV 
        style: cssTriangle 'bottom', 'white', 133, 30,
          position: 'absolute'
          left: '50%'
          marginLeft: - 133 / 2
          top: 0

      H1
        style: _.extend {}, h1, 
          marginBottom: 30
          color: 'white'

        # "Get in touch with us,"
        # BR null
        "Contact us"


      team()

      DIV 
        style: _.extend {}, base_text,
          margin: '30px auto'
          width: 675 #TEXT_WIDTH 
          #textAlign: 'center'
        "Hi, we’re the Consider.it team and we’d love to hear from you. "
        A
          href: "mailto:admin@consider.it"
          style: _.extend {}, a, 
            color: 'white'
            borderBottomColor: 'white'

          "Write us"
        " a nice electronic letter. Or we can write to you:"

      @contactForm()

      DIV 
        style: cssTriangle 'bottom', logo_red, 133, 30,
          position: 'absolute'
          left: '50%'
          marginLeft: - 133 / 2
          bottom: -30      

  contactForm: -> 
    FORM
      action: "//chalkboard.us7.list-manage1.com/subscribe/post?u=9cc354a37a52e695df7b580bd&amp;id=d4b6766b00"
      id: "mc-embedded-subscribe-form"
      method: "post"
      name: "mc-embedded-subscribe-form"
      novalidate: "true"
      target: "_blank"
      style:
        margin: "10px 0 20px 0"
        textAlign: 'center'

      INPUT
        id: "mce-EMAIL"
        name: "EMAIL"
        placeholder: "email address"
        type: "email"
        defaultValue: ""
        style:
          fontSize: 24
          padding: "8px 12px"
          width: 380
          border: '1px solid white'
          backgroundColor: logo_red
          color: 'white'

      BUTTON
        name: "subscribe"
        type: "submit"
        style:
          fontSize: 24
          marginLeft: 8
          display: "inline-block"
          backgroundColor: if @local.hover_contactme then 'white' else logo_red
          color: if @local.hover_contactme then logo_red else 'white'
          fontWeight: 500
          border: "1px solid #{if @local.hover_contactme then 'transparent' else 'white'}"
          borderRadius: 16
          padding: '8px 18px'
        onMouseEnter: => @local.hover_contactme = true; save @local
        onMouseLeave: => @local.hover_contactme = false; save @local
        "Contact me"

team = -> 
  members = [{
      img: 'travis'
      name: "Travis Kriplean"
      email: 'travis@consider.it'
      location: 'Portland, OR'
    },{
      img: 'kevin'
      name: "Kevin Miniter"
      email: 'kevin@consider.it'
      location: 'Portland, OR'      
    },{
      img: 'mike'
      name: "Mike Toomim"
      email: 'toomim@consider.it'
      location: 'Montreal'
    }
  ]

  DIV 
    style: _.extend {}, base_text,
      textAlign: 'center'
      marginTop: 30

    for t in members
      DIV
        style:
          display: "inline-block"
          margin: "20px 30px"
          textAlign: "center"


        A
          href: "mailto:#{t.email}"

          IMG
            src: asset("saas_landing_page/#{t.img}.jpg")
            style:
              borderRadius: "50%"
              display: "inline-block"
              width: 150
              height: 150
              textAlign: "center"  
              boxShadow: "0px 2px 2px rgba(0,0,0,.1)"

          BR null

          A
            style: _.extend {}, a, 
              textAlign: "center"
              #borderBottom: 'none'
              borderBottomColor: 'white'              
              color: 'white'
            t.name

          BR null

          SPAN 
            style: _.extend {}, small_text

            t.location




styles += """

#contact ::-webkit-input-placeholder{
  color: white;
  opacity: .7;
} 
#contact  :-moz-placeholder{
  color: white;
  opacity: .7;
} 
#contact ::-moz-placeholder {
  color: white;
  opacity: .7;
} 
#contact ::-ms-input-placeholder {
  color: white;
  opacity: .7;
}
#contact input[type=email]:focus {
  border-color: white;
  outline: none;
  box-shadow: 0px 1px 12px rgba(255,255,255,.8);
}
"""