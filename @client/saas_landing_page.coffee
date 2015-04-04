require './activerest-m'
require './auth'
require './avatar'
require './browser_hacks'
require './browser_location'
require './tooltip'
require './shared'
require './slider'
require './development'
require './state_dash'

SAAS_PAGE_WIDTH = 1000
TEXT_WIDTH = 730

base_text =
  fontSize: 24
  fontWeight: 400
  fontFamily: "'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"

h1 = _.extend {}, base_text,
  fontSize: 48
  fontWeight: 400
  textAlign: 'center'

h2 = _.extend {}, base_text,
  fontSize: 36
  fontWeight: 300
  textAlign: 'center'

strong = _.extend {}, base_text,
  fontWeight: 600

nav_link_style = _.extend {}, base_text,
  fontWeight: 600
  fontSize: 24
  color: 'white'
  marginLeft: 40
  cursor: 'pointer'

a = _.extend {}, base_text,
  color: logo_red
  cursor: 'pointer'
  textDecoration: 'underline'


SaasHomepage = ReactiveComponent
  displayName: "SaasHomepage"
  render: ->
    DIV null, 
      Video()
      usedFor()
      pricing()
      contact(@local)
      story()


Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    DIV null,
      DIV
        style:
          position: "relative"
          margin: "0 auto"
          backgroundColor: logo_red
          height: 75

        IMG
          src: asset("saas_landing_page/considerit_logo.svg")
          style:
            position: "relative"
            top: 23
            left: 12
            height: 68

      # nav menu
      DIV 
        style: 
          width: SAAS_PAGE_WIDTH
          margin: 'auto'
          position: 'relative'
          top: -34


        DIV 
          style: 
            position: 'absolute'
            right: 0

          A 
            style: nav_link_style
            href: "#pricing"
            'pricing'
          A 
            style: nav_link_style
            href: "#contact"
            'contact'
          A 
            style: nav_link_style
            href: "#story"
            'story'              

      DIV 
        style:
          fontSize: 24
          fontWeight: 300
          color: logo_red
          position: 'relative'
          left: 16
          top: 4
        "for thinking together"



VIDEO_SLIDER_WIDTH = 250
Video = ReactiveComponent
  displayName: "video"
  render: ->
    
    chapter = fetch("video_chapter")
    controls = fetch('video_controls')

    if !controls.playing?
      controls.playing = true
      save controls

    DIV null,        
      DIV
        id: "homepage_video"
        style:
          width: SAAS_PAGE_WIDTH

        VIDEO
          preload: "auto"
          loop: true
          autoPlay: true
          width: SAAS_PAGE_WIDTH
          ref: "video"

          SOURCE
            src: asset("saas_landing_page/with_screen.mp4")
            type: "video/mp4"
          
          SOURCE
            src: asset("saas_landing_page/with_screen.webm")
            type: "video/webm"   


      DIV
        style:
          marginTop: 10
          position: 'relative'


        H2
          style: _.extend {}, h2,
            textAlign: "center"
          
          if chapter.text 
            chapter.text 
          else 
            "Sometimes a proposal bears careful thought"

        DIV 
          onMouseEnter: (ev) => @local.hover_player = true; save @local
          onMouseLeave: (ev) => @local.hover_player = false; save @local

          style: 
            width: VIDEO_SLIDER_WIDTH + 80
            margin: 'auto'
            #padding: '15px 10px'
            position: 'relative'
            opacity: if @local.hover_player then 1 else .5
            top: -10
          I 
            className: "fa fa-#{if controls.playing then 'pause' else 'play'}"
            onClick: (ev) => 
              controls = fetch('video_controls')
              controls.playing = !controls.playing
              save controls
              if controls.playing 
                @refs.video.getDOMNode().play()
              else
                @refs.video.getDOMNode().pause()

            style:       
              fontSize: 10
              color: '#ccc'
              #position: 'relative'
              padding: '12px 12px'
              cursor: 'pointer'
              visibility: if @local.hover_player then 'visible' else 'hidden'
              left: -12

          Slider
            key: 'video_controls'
            width: VIDEO_SLIDER_WIDTH
            handle_height: if @local.hover_player then 20 else 4
            base_height: 4
            base_color: '#ECECEC'
            slider_style: 
              margin: 'auto'
              position: 'absolute'
              top: '50%'
              marginTop: -2
              left: 40
            handle_props: 
              color: logo_red

            onMouseDownCallback: (ev) =>
              video = @refs.video.getDOMNode()
              video.pause()

            onMouseMoveCallback: (ev) => 
              controls = fetch('video_controls')
              video = @refs.video.getDOMNode()
              video.currentTime = controls.value * video.duration

            onMouseUpCallback: (ev) => 
              controls = fetch('video_controls')
              video = @refs.video.getDOMNode()
              video.play() if controls.playing

            onClickCallback: (ev) =>
              controls = fetch('video_controls')
              video = @refs.video.getDOMNode()
              video.pause()
              video.currentTime = controls.value * video.duration
              video.play() if controls.playing

        

  componentDidMount: ->

    # we use timeupdate rather than tracks / cue changes / vtt
    # because browser implementations are not complete (and often buggy)
    # and polyfills poor. 
    v = @refs.video.getDOMNode()
    v.addEventListener 'timeupdate', (ev) -> 
      chapter = fetch("video_chapter")
      controls = fetch('video_controls')

      text = 
        if v.currentTime < 5
          "Proposals often require careful thought"
        else if v.currentTime < 10
          "The Pro/Con list encourages thinking about tradeoffs"
        else if v.currentTime < 14.5
          "Singular points describe a consideration"
        else if v.currentTime < 15
          "Singular points describe a consideration"
        else if v.currentTime < 23
          "Learn and build from other\’s thoughts"
        else if v.currentTime < 32
          "Use a slider to express your conclusion"
        else if v.currentTime < 37
          "Integrate your considered opinion with the group"
        else if v.currentTime < 41
          "Histogram shows the spectrum of opinion"
        else if v.currentTime < 46
          "Points ranked by salience across all individuals"
        else if v.currentTime < 53
          "Now explore patterns of thought!"
        else if v.currentTime < 58
          "Understand the reservations of proposal opposers"
        else if v.currentTime < 65
          "Inspect what a particular individual believes"
        else if v.currentTime < 67.5
          "Figure out who has been persuaded by the top Pro"
        else if v.currentTime < 84
          "Drill into points for focused discussion"
        else
          "For small and large groups alike"

      controls.value = v.currentTime / v.duration

      save controls

      if chapter.text != text
        chapter.text = text
        save chapter
    , false



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
        style: _.extend {}, base_text, 
          fontWeight: 300
        props.body


usedFor = ->

  DIV
    style:
      marginTop: 60

    H1 style: h1,
      'Consider.it creates focused discussion by:'

    bullet
      point_style: 'bullet'
      strong: "Collecting opinions on specific ideas"
      body: ", proposals, plans of action, or hypotheticals. Even job candidates, products, or designs."

    bullet
      point_style: 'bullet'
      strong: "Fostering considerate interactions"
      body: ". The interface makes it easy to consider all sides without putting people in direct conflict. Personal attacks and trolling don’t fit the format."

    bullet
      point_style: 'bullet'
      strong: "Producing an interactive summary of group thought"
      body: ". Patterns of thought across the whole group can be identified. Perhaps 80% of opposers have a single con point that can be addressed!"

    bullet
      point_style: 'bullet'
      strong: "Scaling to hundreds of people"
      body: " deliberating an issue together, without becoming overwhelming or requiring strong central leadership/facilitation."


pricing = ->

contact = (local) ->

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

      "Get in touch with us,"
      BR null
      "We'd love to get to know you!"

    DIV 
      style: 
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
        action: "http://chalkboard.us7.list-manage1.com/subscribe/post?u=9cc354a37a52e695df7b580bd&amp;id=d4b6766b00"
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
            backgroundColor: if local.hover_contactme then logo_red else 'white'
            color: if local.hover_contactme then 'white' else '#999'
            fontWeight: 500
            border: "1px solid #{if local.hover_contactme then 'transparent' else '#999'}"
            borderRadius: 16
            padding: '8px 18px'
          onMouseEnter: => local.hover_contactme = true; save local
          onMouseLeave: => local.hover_contactme = false; save local
          "Contact me"

      DIV null, 
        "We work out of Seattle, WA, Portland, OR, and the Internet."

    DIV 
      style: 
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

story = ->

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


Root = ReactiveComponent
  displayName: "Root"

  render: ->
    loc = fetch 'location'
    app = fetch '/application'

    DIV
      style: base_text

      BrowserLocation()
      StateDash()
      Header()
      DIV
        style:
          width: 1000
          backgroundColor: "white"
          margin: "auto"
          paddingBottom: 20
        BrowserHacks()
        Page(key: "/page" + loc.url)

      Tooltip()

      if app.dev
        Development()



window.Saas = Root

require './application_loader'
