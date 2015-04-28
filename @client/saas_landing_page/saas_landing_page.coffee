require '../activerest-m'
require '../auth'
require '../avatar'
require '../browser_hacks'
require '../browser_location'
require '../tooltip'
require '../shared'
require '../slider'
require '../development'
require '../state_dash'
require '../dock'
require '../logo'
require './story'
require './faq'
require './demo'
require './uses'

window.SAAS_PAGE_WIDTH = 1000
window.TEXT_WIDTH = 730
window.lefty = false

window.base_text =
  fontSize: 24
  fontWeight: 400
  fontFamily: "'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"

window.light_base_text = _.extend {}, base_text, 
  fontWeight: 300
          
window.small_text = _.extend {}, base_text,
  fontSize: 20
  fontWeight: if browser.high_density_display then 300 else 400

window.h1 = _.extend {}, base_text,
  fontSize: 48
  fontWeight: 400
  textAlign: 'center'

window.h2 = _.extend {}, base_text,
  fontSize: 36
  fontWeight: 300
  textAlign: 'center'

window.strong = _.extend {}, base_text,
  fontWeight: 600

window.a = _.extend {}, base_text,
  color: logo_red
  cursor: 'pointer'
  textDecoration: 'underline'



SaasHomepage = ReactiveComponent
  displayName: "SaasHomepage"
  render: ->
    DIV
      style: 
        position: 'relative'

      Video()
      tech()
      Uses()
      #FAQ()
      pricing()
      Contact()
      Story()


HEADER_HEIGHT = 30

Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    docked = fetch('header-dock').docked

    #nav_links = ['demo', 'faq', 'price', 'contact', 'story']
    nav_links = ['demo', 'price', 'contact', 'story']
    
    DIV
      style:
        position: "relative"
        margin: "0 auto"
        backgroundColor: logo_red
        height: HEADER_HEIGHT
        zIndex: 1

      DIV
        style:
          width: SAAS_PAGE_WIDTH
          margin: 'auto'

        DIV 
          style:
            position: "relative"
            top: 4
            left: if window.innerWidth > 1055 then -23.5 else 0

          drawLogo HEADER_HEIGHT + 5, 
                  'white', 
                  (if @local.in_red then 'white' else logo_red), 
                  !@local.in_red,
                  !docked

        # nav menu
        DIV 
          style: 
            width: SAAS_PAGE_WIDTH
            margin: 'auto'
            position: 'relative'
            top: -37

          DIV 
            style: 
              position: 'absolute'
              right: 0

            for nav in nav_links
              A 
                style: _.extend {}, base_text,
                  fontWeight: if nav == 'faq' then 400 else 300
                  fontSize: 20
                  color: 'white'
                  marginLeft: 25
                  cursor: 'pointer'
                  fontVariant: if nav == 'faq' then 'small-caps'
                href: "##{nav}"
                nav

  componentDidMount : -> 

    checkBackground = =>   
      red_regions = [[0, 530 + 2 * HEADER_HEIGHT]]
      y = $(window).scrollTop()

      in_red = false
      for region in red_regions
        if y <= region[1] && region[0] <= y
          in_red = true
          break
      if @local.in_red != in_red
        @local.in_red = in_red
        save @local

    $(window).on "scroll.header", => checkBackground()
    checkBackground()

  componentWillUnmount : -> 
    $(window).off "scroll.header"






bullet = (props) ->
  DIV
    style:
      paddingLeft: 30
      position: "relative"
      margin: "30px auto"
      width: TEXT_WIDTH

    DIV
      style:
        position: "absolute"
        left: -15
        top: 6

      switch props.point_style
        when "bullet"
          "•"
        when "pro"
          "+"
        when "con"
          "–"

    P null,
      SPAN
        style: strong
        props.strong
      SPAN 
        style: light_base_text
        props.body


tech = ->
  DIV
    id: 'tech'
    style:
      marginTop: 60

    H1 style: h1,
      'The first forum that works better'
      BR null,
      'when more people participate'

    bullet
      point_style: 'bullet'
      strong: "Focuses on specific ideas"
      body: """
            . Collect opinions on proposals, plans, hypotheticals, 
            job candidates, products, designs, and more.
            """
    bullet
      point_style: 'bullet'
      strong: "Fosters considerate interactions"
      body: """
            . The design orients people to consider the topic, 
            rather than responding directly to each other. 
            Opportunities for personal attacks on others are limited.
            """
    bullet
      point_style: 'bullet'
      strong: "Automatically produces an interactive summary of opinions"
      body: """
            . Patterns of thought across the whole group can 
            be identified. Perhaps 80% of opposers have a 
            single con point that can be addressed!
            """



pricing = ->
  DIV 
    id: 'price'
    style:
      marginTop: 60

    DIV 
      style: h1

      'Pricing'

    DIV 
      style: _.extend {}, base_text,
        width: TEXT_WIDTH
        margin: 'auto'

      """Free pilots of Consider.it for a limited time! 
      Custom design and advanced configuration available."""

      BR null
      BR null

      A 
        style: a 
        'Contact us'

      ' to get started today. '


Contact = ReactiveComponent
  displayName: 'Contact'

  render: -> 
    teamMember = (props) ->
      DIV
        style:
          display: "inline-block"
          margin: "20px 15px"
          textAlign: "center"
        IMG
          src: props.src
          style:
            borderRadius: "50%"
            display: "inline-block"
            width: 200
            textAlign: "center"

        DIV
          style:
            textAlign: "center"
          props.name

        A
          href: "mailto:#{props.email}"
          style: _.extend {}, a, 
            textAlign: "center"
          props.email

    DIV 
      id: 'contact'
      style:
        marginTop: 60

      H1
        style: _.extend {}, h1, 
          marginBottom: 30

        # "Get in touch with us,"
        # BR null
        "We'd love to get to know you!"

      DIV 
        style: _.extend {}, base_text,
          margin: 'auto'
          width: TEXT_WIDTH 
          textAlign: 'center'
        "Write us a "
        A
          href: "mailto:admin@consider.it"
          style: a
          "nice electronic letter"

        ". Or we can reach out to you:"

        FORM
          action: "//chalkboard.us7.list-manage1.com/subscribe/post?u=9cc354a37a52e695df7b580bd&amp;id=d4b6766b00"
          id: "mc-embedded-subscribe-form"
          method: "post"
          name: "mc-embedded-subscribe-form"
          novalidate: "true"
          target: "_blank"
          style:
            display: "inline-block"
            margin: "10px 0 20px 0"

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
              border: '1px solid #999'

          BUTTON
            name: "subscribe"
            type: "submit"
            style:
              fontSize: 24
              marginLeft: 8
              display: "inline-block"
              backgroundColor: if @local.hover_contactme then logo_red else 'white'
              color: if @local.hover_contactme then 'white' else '#999'
              fontWeight: 500
              border: "1px solid #{if @local.hover_contactme then 'transparent' else '#999'}"
              borderRadius: 16
              padding: '8px 18px'
            onMouseEnter: => @local.hover_contactme = true; save @local
            onMouseLeave: => @local.hover_contactme = false; save @local
            "Contact me"

        DIV null,
          "We work out of Seattle, WA, Portland, OR, and the Internet."

      DIV 
        style: _.extend {}, base_text,
          textAlign: 'center'
          marginTop: 30

        teamMember
          src: asset("saas_landing_page/travis.jpg")
          name: "Travis Kriplean"
          email: "travis@consider.it"

        teamMember
          src: asset("saas_landing_page/kevin.jpg")
          name: "Kevin Miniter"
          email: "kevin@consider.it"
     
        teamMember
          src: asset("saas_landing_page/mike.jpg")
          name: "Michael Toomim"
          email: "toomim@consider.it"


Footer = -> 

  DIV
    style: 
      backgroundColor: logo_red
      padding: '20px 0'
    DIV
      style: _.extend {}, h2,
        width: SAAS_PAGE_WIDTH
        margin: 'auto'
        color: 'white'

      'That is our story, friend!'
      BR null, 
      A
        style: _.extend {}, a, 
          fontSize: 36
          color: 'white'
        href: 'mailto:admin@consider.it'
        'Tell us your story' 
      '. What led you here?'


Page = ReactiveComponent

  displayName: "Page"
  mixins: [ AccessControlled ]

  render: ->
    loc = fetch("location")
    auth = fetch("auth")

    DIV null,
      if auth.form
        Auth()
      else unless @accessGranted()
        SPAN null
      else
        switch loc.url
          when "/dashboard/create_subdomain"
            CreateSubdomain key: "/page/dashboard/create_subdomain"
          else
            SaasHomepage key: "homepage"

Computer = ReactiveComponent
  displayName: 'Computer'

  render: -> 
    app = fetch '/application'
    doc = fetch 'document'

    title = 'Consider.it | Think better together'
    if doc.title != title
      doc.title = title
      save doc

    if app.dev
      Development()
    else
      SPAN null

Root = ReactiveComponent
  displayName: "Root"

  render: ->
    DIV null,
      BrowserLocation()
      StateDash()

      Dock
        dock_on_zoomed_screens: false
        skip_jut: true
        key: 'header-dock'

        Header()
  
      DIV 
        style: 
          position: 'absolute'
          left: 0
          top: 0
          width: '100%'
          height: 622 - HEADER_HEIGHT
          backgroundColor: logo_red



      DIV
        style:
          backgroundColor: "white"
          paddingBottom: 20
          marginTop: 20
        BrowserHacks()
        Page()

      Footer()

      Tooltip()

      Computer()



window.Saas = Root

require '../bootstrap_loader'
