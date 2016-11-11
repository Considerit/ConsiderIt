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
require '../logo'
require '../bubblemouth'
require '../translations'
require '../customizations'
require '../homepage'
require '../legal'

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
  #textDecoration: 'underline'
  borderBottom: "1px solid #{logo_red}"



require './story'
require './faq'
require './demo'
require './uses'
require './contact'
require './pricing'
require './features'
require './metrics'

Proposals = ReactiveComponent
  displayName: 'Proposals'

  render: -> 
    users = fetch '/users'
    proposals = fetch '/proposals'
    subdomain = fetch '/subdomain'

    return SPAN null if !subdomain.name

    TagHomepage()


HEADER_HEIGHT = 30

Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    nav_links = ['demo', 'uses', 'features', 'price', 'contact', 'about']
    
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
                  (if @local.in_red then 'transparent' else logo_red), 
                  !@local.in_red,
                  false

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

            for nav,idx in nav_links
              A 
                key: idx
                style: _.extend {}, base_text,
                  fontWeight: if nav == 'faq' then 400 else 300
                  fontSize: 20
                  color: 'white'
                  marginLeft: 25
                  cursor: 'pointer'
                  fontVariant: if nav == 'faq' then 'small-caps'
                onClick: do (nav) => => 
                  if nav == 'about'
                    showStory()

                href: "##{nav}"
                nav

  componentDidMount : -> 

    checkBackground = =>   
      try 
        red_regions = ['#uses', '#contact', '#footer', '#collaborate'] #[[0, 530 + 2 * HEADER_HEIGHT]]
        y = $(window).scrollTop() + $(@getDOMNode()).outerHeight()

        in_red = false
        for region in red_regions
          el = $(region)
          start = el.offset().top
          end = start + el.outerHeight()

          if y <= end && start <= y
            in_red = true
            break
        if @local.in_red != in_red
          @local.in_red = in_red
          save @local
      catch e  
        noop = 1

    $(window).on "scroll.header", => checkBackground()
    checkBackground()

  componentWillUnmount : -> 
    $(window).off "scroll.header"



Heading = -> 
  DIV 
    style:
      width: SAAS_PAGE_WIDTH
      margin: "80px auto 0 auto"
      position: 'relative'
      textAlign: 'center'

    DIV
      style: 
        fontSize: 66
        marginBottom: 10
        color: logo_red
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

    P style: base_text,
      SPAN
        style: 
          fontWeight: 500
        props.strong
      SPAN 
        style: light_base_text
        props.body


tech = ->
  DIV
    id: 'tech'
    style:
      marginTop: 50

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
             The design helps participants focus on the topic, rather 
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
            share two con points that can be addressed!
            """


Customers = ReactiveComponent
  displayName: 'Customers'

  render: -> 
    customers = [ {
        img: 'seattle'
        url: 'http://2035.seattle.gov' 
        type: 'svg'     
      }, {
        img: 'nasa'
        url: 'http://www.nasa.gov'
      },{
        img: 'ecast'
        url: 'http://ecastnetwork.org'
      }, {
        img: 'dialoguepartners'
        url: 'http://dialoguepartners.ca/'      
      }, {
        img: 'mos'
        url: 'http://www.mos.org/'      
      }, {
        img: 'cityclub'
        url: 'http://seattlecityclub.org'      
      },
      # , {
      #   img: 'tigard'
      #   url: 'http://www.tigard-or.gov/'      
      # }
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
            key: c.url
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
              src: asset("product_page/#{c.img}.#{c.type || 'png'}")
              style: 
                height: 90


Research = -> 

  # | 323666 | Travis Kriplean, PhD, Computer Science, University of Washington                |
  # | 324669 | Deen Freelon, Assistant Professor of Communication Studies, American University |
  # | 324670 | Alan Borning, Professor of Computer Science, University of Washington           |
  # | 324671 | Lance Bennett, Professor of Political Science, University of Washington         |
  # | 324672 | Jonathan Morgan, PhD, Human Centered Design, University of Washington           |
  # | 324673 | Caitlin Bonnar, Computer Science, University of Washington                      |
  # | 324674 | Brian Gill, Professor of Statistics, Seattle Pacific University                 |
  # | 324675 | Bo Kinney, Librarian, Seattle Public Library                                    |
  # | 324678 | Menno De Jong, Professor of Behavioral Sciences, University of Twente           |
  # | 324679 | Hans Stiegler, Behavioral Sciences, University of Twente                        |

  authors = (author_list) -> 
    DIV 
      style:
        position: 'absolute'
        top: 5
        right: -40

      UL 
        style:
          display: 'inline'

        for author,idx in author_list
          LI 
            key: idx
            style: 
              display: 'inline-block'
              listStyle: 'none'
              zIndex: 10 - idx
              position: 'absolute'
              left: 25 * idx
              top: 25 * idx

            Avatar
              key: "/user/#{author}"
              user: "/user/#{author}"
              img_size: 'large'
              style: 
                width: 50
                height: 50


  papers = [
    {
      url: "http://dub.washington.edu/djangosite/media/papers/kriplean-cscw2012.pdf"
      title: 'Supporting Reflective Public Thought with Consider.it'
      venue: '2012 ACM Conference on Computer Supported Cooperative Work'
      authors: [323666, 324672, 324669, 324670, 324671]
    },    {
      url: "https://dl.dropboxusercontent.com/u/3403211/papers/jitp.pdf"
      title: 'Facilitating Diverse Political Engagement'
      venue: 'Journal of Information Technology & Politics, Volume 9, Issue 3'
      authors: [324669, 323666, 324672, 324671, 324670]
    },    {
      url: "http://homes.cs.washington.edu/~borning/papers/kriplean-cscw2014.pdf"
      title: 'On-demand Fact-checking in Public Dialogue'
      venue: '2014 ACM Conference on Computer Supported Cooperative Work'
      authors: [324673, 323666, 324670, 324675, 324674]
    },    {
      url: "http://www.sciencedirect.com/science/article/pii/S0747563215003891"
      title: 'Facilitating Personal Deliberation Online: Immediate Effects of Two Consider.it Variations'
      venue: 'Forthcoming, Computers in Human Behavior, Volume 51, Part A'
      authors: [324679, 324678]
    }
  ]

  DIV 
    style: 
      width: SAAS_PAGE_WIDTH
      margin: '80px auto'

    H1
      style: _.extend {}, h1, 
        margin: '20px'

      'Academic research about Consider.it'

    UL
      style: 
        listStyle: 'none'
        width: TEXT_WIDTH - 50
        position: 'relative'
        left: '50%'
        marginLeft: -TEXT_WIDTH / 2 - 50

      for paper in papers
        LI 
          key: paper.title
          style: 
            padding: '16px 32px'
            position: 'relative'
            backgroundColor: considerit_gray
            boxShadow: '#b5b5b5 0 1px 1px 0px'
            borderRadius: 32
            marginBottom: 20

          A 
            style:  _.extend {}, a, base_text
            href: paper.url
            paper.title
          DIV 
            style: _.extend {}, small_text
            paper.venue

          DIV
            style: css.crossbrowserify
              transform: 'rotate(90deg)'
              position: 'absolute'
              right: -27
              top: 20

            Bubblemouth 
              apex_xfrac: 0
              width: 30
              height: 30
              fill: considerit_gray
              stroke: 'transparent'
              stroke_width: 0
              box_shadow:   
                dx: '3'
                dy: '0'
                stdDeviation: "2"
                opacity: .5


          authors paper.authors

Footer = -> 

  DIV
    id: 'footer'
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
    DIV
      style: _.extend {}, h2,
        width: SAAS_PAGE_WIDTH
        margin: 'auto'
        color: 'white'

      'Thanks for listening, friend.'
      BR null, 
      A
        style: _.extend {}, a, 
          fontSize: 36
          color: 'white'
          borderBottomColor: 'white'
        href: 'mailto:admin@consider.it'
        'Tell us your story' 
      '. What led you here?'


    DIV 
      style: cssTriangle 'bottom', logo_red, 133, 30,
        position: 'absolute'
        left: '50%'
        marginLeft: - 133 / 2
        bottom: -30      


# props is:
#    tabs: [{icon, label, description}]
#    stroke_color
#    text_color
window.VisualTab = ReactiveComponent
  displayName: 'VisualTab'

  render : ->
    svg_padding = @props.svg_padding or '10px 20px'

    if !@local.selected
      @local.selected = @props.tabs[0].icon
      save @local

    bg_color = @props.bg_color or 'white'
    stroke_width = @props.stroke_width or 1

    select_tab = (tab) => 
      @local.selected = tab.icon
      save @local
    hover_tab = (tab) => 
      @local.hovering = tab.icon
      save @local

    DIV 
      style: @props.style
      UL 
        style: 
          listStyle: 'none'
          textAlign: 'center'

        for tab, idx in @props.tabs
          do (tab, idx) => 
            selected = @local.selected == tab.icon
            hovering = @local.hovering == tab.icon
            LI 
              key: idx
              style: 
                padding: svg_padding
                display: 'table-cell'
                opacity: if selected then 1.0 else if hovering then .6 else .25
                verticalAlign: 'top'
                cursor: 'pointer'
                position: 'relative'

              onMouseEnter : => hover_tab(tab)
              onMouseLeave : => @local.hovering = null; save @local
              onClick : => select_tab(tab)
              onTouchStart: => select_tab(tab)

              DIV 
                style: 
                  paddingBottom: 10
                  textAlign: 'center'

                window["#{tab.icon}SVG"]
                  height: @props.icon_height
                  fill_color: if selected || hovering then @props.stroke_color else 'black'

                if tab.label
                  DIV 
                    style: 
                      textAlign: 'center'
                      fontSize: 30
                      maxWidth: 180
                    tab.label

              if selected
                SVG 
                  height: 8
                  width: 30

                  style:
                    position: 'absolute'
                    left: '50%'
                    marginLeft: - 30 / 2
                    bottom: -stroke_width
                    zIndex: 1

                  POLYGON
                    points: "0,8 15,0 30,8" 
                    fill: @props.stroke_color

                  POLYGON
                    points: "0,#{8 + stroke_width} 15,#{stroke_width} 30,#{8 + stroke_width}" 
                    fill: bg_color






      DIV 
        style: _.extend {}, base_text, 
          minHeight: if @props.description_height then @props.description_height
          margin: '0px auto 40px auto'   
          paddingTop: 25
          borderTop: "#{stroke_width}px solid #{@props.stroke_color}"
          position: 'relative'


        for tab, idx in @props.tabs
          if @local.selected == tab.icon
            DIV 
              key: idx
              if _.isFunction(tab.description)
                tab.description()
              else 
                tab.description

Collaborate = ReactiveComponent
  displayName: 'Collaborate'

  render: -> 

    DIV 
      id: 'collaborate'
      style:
        marginTop: 1
        backgroundColor: considerit_gray
        #color: 'white'
        padding: '30px 0'
        paddingBottom: 80
        position: 'relative'

      DIV 
        style: cssTriangle 'bottom', 'white', 133, 30,
          position: 'absolute'
          left: '50%'
          marginLeft: - 133 / 2
          top: 0

      DIV 
        style: 
          width: SAAS_PAGE_WIDTH
          margin: 'auto'
          textAlign: 'center'           

        DIV 
          style: 
            position: 'relative'
            left: 9
            top: -4

          collaborationSVG
            height: 100
            fill_color: '#414141'


        DIV
          style: 
            textAlign: 'center'
            width: 570
            margin: 'auto'
            fontSize: 24
            marginTop: 10
            color: '#414141'

          "Have a different use in mind? Want to collaborate on a larger project? We'd love to "
          A
            href: '#contact'
            style: 
              textDecoration: "underline"
            'hear from you'
          "."

      DIV 
        style: cssTriangle 'bottom', considerit_gray, 133, 30,
          position: 'absolute'
          left: '50%'
          marginLeft: - 133 / 2
          bottom: -30      



Page = ReactiveComponent

  displayName: "Page"
  mixins: [ AccessControlled ]

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
      Collaborate()
      Features()
      Pricing()
      Contact()
      Research()      
      Footer()
      Story()

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

  # Track whether the user is currently swipping. Used to determine whether
  # a touchend event should trigger a click on a link.
  # TODO: I'd like to have this defined at a higher level  
  onTouchMove: -> 
    window.is_swipping = true
  onTouchEnd: -> 
    window.is_swipping = false

  render: ->
    loc = fetch 'location'

    DIV null,
      BrowserLocation()
      StateDash()

      # Dock
      #   dock_on_zoomed_screens: false
      #   skip_jut: true
      #   key: 'header-dock'

      DIV 
        style: 
          position: 'fixed'
          top: 0
          left: 0
          zIndex: 999
          width: '100%'

        Header()


      DIV
        style:
          backgroundColor: "white"
        BrowserHacks()

        switch loc.url 
          when '/proposals'
            Proposals()

          when '/privacy_policy'
            PrivacyPolicy()
          when '/terms_of_service'
            TermsOfService()

          when '/metrics'
            Metrics()
          else 
            Page()

      Tooltip()

      Computer()



window.Saas = Root

require '../bootstrap_loader'
