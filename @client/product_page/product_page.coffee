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

window.SAAS_PAGE_WIDTH = 1000
window.TEXT_WIDTH = 730

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
  fontWeight: 600
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
  #textDecoration: 'underline'
  borderBottom: "1px solid #{logo_red}"



require './story'
require './faq'
require './demo'
require './uses'
require './contact'
require './pricing'



ProductPage = ReactiveComponent
  displayName: "ProductPage"
  render: ->
    DIV
      style: 
        position: 'relative'

      Heading()
      Video()
      tech()
      Customers()      
      Uses()
      #FAQ()
      Pricing()
      Research()
      Contact()
      Footer()



HEADER_HEIGHT = 30

Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    docked = fetch('header-dock').docked

    #nav_links = ['demo', 'faq', 'price', 'contact', 'story']
    nav_links = ['demo', 'uses', 'price', 'contact']
    
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
      red_regions = [] #[[0, 530 + 2 * HEADER_HEIGHT]]
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



Heading = -> 
  DIV 
    style:
      width: SAAS_PAGE_WIDTH
      margin: "60px auto 0 auto"
      position: 'relative'
      textAlign: 'center'

    DIV
      style: 
        fontSize: 66
        marginBottom: 10
      'Think Better Together.'

    DIV
      style:
        marginBottom: 50
        fontSize: 24
        width: TEXT_WIDTH
        margin: 'auto'

      """
      Consider.it can help you collect feedback, engage stakeholders, make group decisions, 
      teach critical thinking, and more.
      """




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
      marginTop: 80

    H1 style: h1,
      'The first forum that works better'
      BR null,
      'when more people participate'

    bullet
      point_style: 'bullet'
      strong: "Think together about specific ideas."
      body: """
             Collect opinions on proposals, plans, hypotheticals, 
            job candidates, products, designs, and more.
            """
    bullet
      point_style: 'bullet'
      strong: "Maintain focus."
      body: """
             The design keeps participants focused on the topic, rather 
            than each other. Long tangents are contained and don't 
            hijack the conversation.
            """
            # . The design orients people to consider the topic, 
            # rather than responding directly to each other. 
            # Opportunities for personal attacks on others are limited, 
            # unlike online commenting and email threads.


    bullet
      point_style: 'bullet'
      strong: "Identify patterns of thought across the whole group."
      body: """
             A visual, interactive summary of opinions helps everyone 
            analyze and understand what the 
            group thinks. Perhaps 80% of those with reservations
            share a couple con points that can be addressed!
            """


Customers = ReactiveComponent
  displayName: 'Customers'

  render: -> 
    customers = [{
        img: 'nasa'
        url: 'http://www.nasa.gov'
      },{
        img: 'spl'
        url: 'http://spl.org'
      }, {
        img: 'ecast'
        url: 'http://ecastnetwork.org'
      }, {
        img: 'cityclub'
        url: 'http://seattlecityclub.org'      
      }, {
        img: 'dialoguepartners'
        url: 'http://dialoguepartners.ca/'      
      }, {
        img: 'mos'
        url: 'http://www.mos.org/'      
      }, {
        img: 'tigard'
        url: 'http://www.tigard-or.gov/'      
      }
    ]

    DIV 
      style: 
        width: SAAS_PAGE_WIDTH
        margin: '60px auto'
        textAlign: 'center'

      H1
        style: _.extend {}, h2, 
          marginBottom: 20

        "Used by:"


      for c in customers
        do (c) => 
          style = 
            cursor: 'pointer'
            padding: "10px 15px"

          if @local.hovered != c.img
            style = css.grayscale style
            style.opacity = .7
          A 
            style: style
            href: c.url
            target: '_blank'
            onMouseEnter: => 
              @local.hovered = c.img
              save @local
            onMouseLeave: => 
              @local.hovered = null
              save @local

            IMG
              src: asset("product_page/#{c.img}.png")
              style: 
                height: 90


Research = -> 
  DIV 
    style: 
      width: SAAS_PAGE_WIDTH
      margin: '60px auto'

    H1
      style: _.extend {}, h1, 
        margin: '20px'

      'Academic research about Consider.it'

    UL
      style: 
        listStyle: 'none'
        width: 615
        margin: 'auto'

      LI 
        style: 
          paddingTop: 5

        A 
          style:  _.extend {}, a, base_text
          href: "http://dub.washington.edu/djangosite/media/papers/kriplean-cscw2012.pdf"
          'Supporting Reflective Public Thought with Consider.it'
        DIV 
          style: _.extend {}, small_text
          '2012 ACM Conference on Computer Supported Cooperative Work'


      LI
        style: 
          paddingTop: 15
        A 
          style:  _.extend {}, a, base_text
          href: "https://dl.dropboxusercontent.com/u/3403211/papers/jitp.pdf"
          'Facilitating Diverse Political Engagement'
        DIV 
          style: _.extend {}, small_text
          'Journal of Information Technology & Politics, Volume 9, Issue 3'

      LI 
        style: 
          paddingTop: 15
        A 
          style:  _.extend {}, a, base_text
          href: "http://homes.cs.washington.edu/~borning/papers/kriplean-cscw2014.pdf"
          'On-demand Fact-checking in Public Dialogue'

        DIV 
          style: _.extend {}, small_text
          '2014 ACM Conference on Computer Supported Cooperative Work'

      LI 
        style: 
          paddingTop: 15
        A 
          style:  _.extend {}, a, base_text
          href: "http://www.sciencedirect.com/science/article/pii/S0747563215003891"
          'Facilitating Personal Deliberation Online: Immediate Effects of Two Consider.it Variations'

        DIV 
          style: _.extend {}, small_text
          'Forthcoming, Computers in Human Behavior, Volume 51, Part A'




Footer = -> 

  DIV
    style: 
      #backgroundColor: logo_red
      margin: '20px 0'
    DIV
      style: _.extend {}, h2,
        width: SAAS_PAGE_WIDTH
        margin: '60px auto'
        #color: 'white'

      'Thanks for listening, friend.'
      BR null, 
      A
        style: _.extend {}, a, 
          fontSize: 36
          #color: 'white'
          #borderBottomColor: 'white'
        href: 'mailto:admin@consider.it'
        'Tell us your story' 
      '. What led you here?'


    Story()


# props is:
#    tabs: [{icon, label, description}]
#    stroke_color
#    text_color
window.VisualTab = ReactiveComponent
  displayName: 'VisualTab'

  render : ->
    position = 0
    if !@local.custom_reason_hover
      @local.custom_reason_hover = @props.tabs[0].icon
      save @local

    bg_color = @props.bg_color or 'white'
    stroke_width = @props.stroke_width or 1

    select_tab = (tab) => 
      @local.custom_reason_hover = tab.icon
      save @local

    DIV 
      style: @props.style
      UL 
        style: 
          listStyle: 'none'
          textAlign: 'center'

        for tab, idx in @props.tabs
          do (tab, idx) => 
            hovering = @local.custom_reason_hover == tab.icon
            if hovering
              position = idx
            LI 
              style: 
                padding: '10px 20px'
                display: 'inline-block'
                opacity: if !hovering then .25
                verticalAlign: 'top'

              onMouseEnter : => select_tab(tab)
              onClick : => select_tab(tab)
              onTouchStart: => select_tab(tab)

              DIV 
                style: 
                  paddingBottom: 10
                  textAlign: 'center'

                window["#{tab.icon}SVG"]
                  height: @props.icon_height
                  fill_color: if hovering then @props.stroke_color else 'black'

                if tab.label
                  DIV 
                    style: 
                      textAlign: 'center'
                      fontSize: 30
                      maxWidth: 180
                    tab.label



      DIV 
        style: _.extend {}, base_text, 
          height: if @props.description_height then @props.description_height
          margin: '0px auto 40px auto'   
          paddingTop: 25
          borderTop: "#{stroke_width}px solid #{@props.stroke_color}"
          position: 'relative'

        SVG 
          height: 8
          width: 30

          style:
            position: 'absolute'
            left: "#{position / @props.tabs.length * 100 + .5 * 100 / @props.tabs.length}%"
            marginLeft: - 30 / 2
            top: -8

          POLYGON
            points: "0,8 15,0 30,8" 
            fill: @props.stroke_color

          POLYGON
            points: "0,#{8 + stroke_width} 15,#{stroke_width} 30,#{8 + stroke_width}" 
            fill: bg_color

        for tab, idx in @props.tabs
          if @local.custom_reason_hover == tab.icon

            if _.isFunction(tab.description)
              tab.description()
            else 
              tab.description


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
            ProductPage key: "homepage"

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
          #backgroundColor: logo_red



      DIV
        style:
          backgroundColor: "white"
        BrowserHacks()
        Page()

      Tooltip()

      Computer()



window.Saas = Root

require '../bootstrap_loader'
