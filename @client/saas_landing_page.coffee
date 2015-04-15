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

small_text = _.extend {}, base_text,
  fontSize: 20
  fontWeight: 300

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

    ui = fetch('homepage_ui')
    if !ui.initialized
      _.extend ui, 
        initialized: true
        video_file_name: 'deathstar-cam'
        video_file_name_instr: "Only available video is 'deathstar-cam'"
        video_elements_order: "caption,video"
        video_elements_order_inst: """
          A list of video elements to show and in which order (top to bottom). 
          e.g. \"caption,controls,video\"
          Must contain 'video' somewhere.
          """
        frame: 'browser'
        frame_instr: """"
          Whether to draw a frame around the video, and if so, what it should be. 
          Supported values: 
            'laptop', 'browser', 'none'
          """
      save ui

    DIV null, 

      DIV
        style: _.extend h1,
          margin: '50px 0'

        'Champion focused discussion in your'
        BR null,
        'community, organization or classroom'


      Video()
      usedFor()
      enables()
      pricing()
      contact(@local)
      story()


HEADER_HEIGHT = 70
Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    DIV
      style:
        position: "relative"
        margin: "0 auto"
        backgroundColor: logo_red
        height: HEADER_HEIGHT


      DIV
        style:
          width: SAAS_PAGE_WIDTH
          margin: 'auto'

        IMG
          src: asset("saas_landing_page/considerit_logo.svg")
          style:
            position: "relative"
            top: HEADER_HEIGHT * .05 + 16
            left: 0
            height: HEADER_HEIGHT * .95

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

        # DIV 
        #   style:
        #     fontSize: 24
        #     fontWeight: 300
        #     color: logo_red
        #     position: 'absolute'
        #     top: 4 + HEADER_HEIGHT
        #   "for thinking together"



VIDEO_SLIDER_WIDTH = 250

Video = ReactiveComponent
  displayName: "video"
  render: ->
    
    ui = fetch('homepage_ui')
    controls = fetch('video_controls')

    if !controls.playing?
      controls.playing = false
      save controls

    video = DIV null,
      @drawCaptions()
      if ui.frame == 'none'
        @drawVideoControls()
      @drawVideo()

    if ui.frame == 'laptop'
      @drawInLaptop video
    else if ui.frame == 'browser'
      @drawInBrowserWindow video
    else 
      @drawWithoutFrame video


  drawInLaptop : (children) -> 

    DIV 
      style: 
        #marginTop: 70
        height: 756
        position: 'relative'

      DIV 
        style: 
          position: 'relative'
          top: 39
        children    

      IMG
        src: asset('saas_landing_page/laptop-frame.png')
        style: 
          top: 0
          position: 'absolute'
          left: -130
          pointerEvents: 'none'

  drawWithoutFrame : (children) -> 

    DIV 
      style: 
        marginTop: 70

      children

  drawInBrowserWindow : (children) ->
    DIV 
      style: 
        border: "1px solid #ccc"
        borderTop: 'none'
        borderRadius: 8
        backgroundColor: 'white'
        boxShadow: "0 3px 8px rgba(0,0,0,.1)"
        marginTop: 70

      # window bar / url
      DIV 
        style: 
          height: 31
          borderRadius: '8px 8px 0 0'
          backgroundColor: '#ccc'
          backgroundImage: "linear-gradient(0deg, #D4D3D4, #EEEDEE)"
          boxShadow: "0 1px 1px rgba(0,0,0,.35)"

        # url area
        DIV 
          style: 
            position: 'relative'
            width: 300
            margin: 'auto'
            height: 20
            top: (31 - 20) / 2
            borderRadius: 4
            backgroundColor: 'white'
            boxShadow: "0 1px 1px rgba(0,0,0,.1)"
            textAlign: 'center'
            fontSize: 12

          SPAN
            style: 
              position: 'relative'
              top: 3
            'http://video-demo.consider.it'

      DIV null,

        children 


  drawCaptions : -> 
    ui = fetch('homepage_ui')
    chapter = fetch("video_chapter")

    if !chapter.text?
      chapter.text = "Proposals often require careful thought"

    DIV
      style:
        position: 'relative'
        zIndex: 1
        top: if ui.frame == 'laptop' then -12

      H2
        style: _.extend {}, h2,
          textAlign: "center"
          fontSize: if ui.frame == 'laptop' then 30 else 36
          color: if ui.frame == 'laptop' then 'white' else 'black'

        
        if chapter.text 
          chapter.text 
        else 
          ""

  drawVideoControls : ->
    controls = fetch('video_controls')

    DIV 
      onMouseEnter: (ev) => @local.hover_player = true; save @local
      onMouseLeave: (ev) => @local.hover_player = false; save @local

      style: 
        width: VIDEO_SLIDER_WIDTH + 80
        margin: 'auto'
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


  drawVideo : -> 
    ui = fetch('homepage_ui')


    DIV
      id: "homepage_video"
      style:
        width: SAAS_PAGE_WIDTH - 1
        height: 551

      VIDEO
        preload: "auto"
        loop: true
        autoPlay: true
        width: SAAS_PAGE_WIDTH - 2
        height: 551
        ref: "video"
        controls: if ui.frame != 'none' then true

        SOURCE
          src: asset("saas_landing_page/#{ui.video_file_name}.mp4")
          type: "video/mp4"
        
        SOURCE
          src: asset("saas_landing_page/#{ui.video_file_name}.webm")
          type: "video/webm"


  componentDidUpdate: -> @attachToVideo()
  componentDidMount: -> 
    @attachToVideo()

    # # wait a couple seconds before playing video to give user time to 
    # # orient to homepage
    # console.log 'SET'
    # setTimeout => 
    #   controls = fetch('video_controls')
    #   controls.playing = true
    #   save controls
    #   @refs.video.getDOMNode().play()
    #   console.log 'PLAY'
    # , 1000

  attachToVideo : -> 
    # we use timeupdate rather than tracks / cue changes / vtt
    # because browser implementations are not complete (and often buggy)
    # and polyfills poor. 

    v = @refs.video.getDOMNode()

    if @v != v
      @v = v
      v.addEventListener 'timeupdate', (ev) -> 
        chapter = fetch("video_chapter")
        controls = fetch('video_controls')

        text = 
          if v.currentTime < 5.5
            "Proposals often require careful thought"
          else if v.currentTime < 10.5
            # "The Pro/Con list encourages thinking about tradeoffs"
            # "The Pro/Con list emphasizes tradeoffs"
            # "The Pro/Con list emphasizes considering tradeoffs"
            # "The Pro/Con list focuses thought on tradeoffs"
            # "The Pro/Con list stresses tradeoffs"
            "The Pro/Con list focuses attention on tradeoffs"

          else if v.currentTime < 18
            "Each thought becomes a Pro or Con point"
          else if v.currentTime < 25
            "Learn and include the thoughts of peers"
          else if v.currentTime < 33.5
            "Express your conclusion on a sliding scale"
          else if v.currentTime < 39
            "Add your opinion to the group"
          else if v.currentTime < 43
            "The spectrum of opinion is shown on a Histogram"
          else if v.currentTime < 46
            "Points are ranked by importance for the group"
          else if v.currentTime < 55
            "Now explore patterns of thought!"
          else if v.currentTime < 61
            "Learn the reservations of opposers"
          else if v.currentTime < 67.5
            "Inspect a peer's opinion"
          else if v.currentTime < 72
            "See who has been persuaded by the top Pro"
          else if v.currentTime < 87
            "Have a focused discussion about a single point"
          else
            "...and those are the basics of Consider.it!"

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
  ui = fetch('homepage_ui')
  DIV
    style:
      marginTop: if ui.frame == 'laptop' then 30 else 60

    H1 style: h1,
      'The first forum to function better'
      BR null,
      'when more people participate'

    bullet
      point_style: 'bullet'
      strong: "Collect opinions on specific ideas"
      body: ", proposals, plans, or hypotheticals. Even job candidates, products, or designs."

    bullet
      point_style: 'bullet'
      strong: "Foster considerate interactions"
      body: """. The interface focuses people on considering all sides 
                 of the topic, rather than each other. There is little 
                 opportunity for personal attacks and trolling.
            """

    bullet
      point_style: 'bullet'
      strong: "Produce an interactive summary of group thought"
      body: """. Patterns of thought across the whole group can 
                 be identified. Perhaps 80% of opposers have a 
                 single con point that can be addressed!
            """

enables = -> 
  DIV
    style:
      marginTop: 60

    H1 style: h1,
      'You can use Consider.it to...'

    bullet
      point_style: 'bullet'
      strong: "Involve five, fifty, or even hundreds of people"
      body: " in deliberating an issue together, without becoming overwhelming."

    bullet
      point_style: 'bullet'
      strong: "Lead change"
      body: """. Collect organized feedback from employees, membership, and stakeholders
                 for strategic planning, process improvement, program evaluation, and other 
                 change efforts. Strong leaders create change by explaining and evolving plans. 
            """

    bullet
      point_style: 'bullet'
      strong: "Decentralize decision making"
      body: """. Make decisions as a whole, without resorting to hierarchy. The will of a community, 
                 and the thoughts behind that will, become visible and actionable.
            """

    bullet
      point_style: 'bullet'
      strong: "Teach critical thinking"
      body: """. Students learn how to develop and express a considered opinion while listening 
                 to and engaging with other’s ideas. Works well for Common Core aligned exercises 
                 in English and Social Studies.
            """


pricing = ->
  DIV 
    id: 'pricing'

    DIV 
      style: h1

      'Pricing'

    DIV 
      style: 
        width: TEXT_WIDTH
        margin: 'auto'

      'We are offering free pilots for a limited time. '

      A 
        style: a 
        'Contact us'

      ' to get started today! '
      BR null
      BR null
      'If advanced configuration or custom design is needed, we can discuss whether compensation is necessary.'

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
  story_link = _.extend {}, a, small_text,
    fontWeight: 500
    textDecoration: 'none'

  DIV 
    id: 'story'
    style:
      marginTop: 60

    H1
      style: _.extend {}, h1, 
        marginBottom: 30

      "Our story"

    DIV
      style:
        marginBottom: 20

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .6 - 40
          marginRight: 40
          verticalAlign: 'top'

          

        P 
          style: 
            paddingBottom: 15

          """
          Consider.it was invented in 2010 by Travis Kriplean as part of his 
          Computer Science """

          A 
            style: story_link
            href: 'https://dl.dropboxusercontent.com/u/3403211/papers/dissertation.pdf'
            "PhD dissertation" 

          
          ' at the University of Washington, in collaboration with fellow graduate '
          'student Michael Toomim, Professor '

          A
            style: story_link
            href: 'http://www.cs.washington.edu/people/faculty/borning'
            'Alan Borning'

          ', Jonathan Morgan, and a team of political communication researchers. The project was funded by a generous '
          A
            href: "http://www.nsf.gov/awardsearch/showAward?AWD_ID=0966929"
            style: story_link
            "National Science Foundation grant"
          '.'

        P null,
          """
          Kevin Miniter joined Consider.it serendipitously in 2012. Motivated by
          his experiencing running a ... , and his life philosophy of simply 
          asking “how can I help?”
          """

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .4
          marginTop: 10

        
        IFRAME
          width: 400
          height: 243
          src: "https://www.youtube.com/embed/jl1AsVM_8hk?modestbranding=1&showinfo=0&theme=dark&fs=1" 
          frameborder: "0" 
          allowfullscreen: true

        SPAN
          style: 
            fontSize: 14
            fontWeight: 400
          'Travis\' Phd defense, from December 2011'


    DIV 
      style:
        marginBottom: 20

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          verticalAlign: 'middle'
          width: SAAS_PAGE_WIDTH * .4
          marginTop: 10

        IMG 
          src: asset('saas_landing_page/sifp.jpg')
          width: 400
        SPAN
          style: 
            fontSize: 14
            fontWeight: 400
          'Travis delivers the '
          A
            style: _.extend {}, a, 
              fontSize: 14
            href: 'https://www.youtube.com/watch?v=RIUD4Ty2ZAE'
            'winning talk'
          ' at Social Innovation Fast Pitch'          

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .6 - 40
          verticalAlign: 'top'
          marginLeft: 40

        P 
          style: 
            paddingBottom: 15

          'The original and longest-running Consider.it application is the '
          
          A 
            style: story_link
            href: "http://www.evergreenapps.org/congratulations-to-the-winners-of-the-evergreen-apps-challenge/"
            'award'
          '-'
          A 
            style: story_link
            href: "http://www.socialventurepartners.org/seattle/2012/10/25/2012-sifp-winners/"
            'winning'
          ' '
          A
            style: story_link
            href:'https://livingvotersguide.org'
            "Living Voters Guide"

          """, a crowd-sourced guide to public
          thought on Washington State’s ballot measures, with """
          A
            style: story_link
            href: "http://blogs.seattletimes.com/monica-guzman/2012/10/27/seattle-library-fact-check-experiment-risky-but-valuable/"
            "on-demand fact-checking"
          ' provided by Seattle Public Librarians. Our partners '
          A 
            style: story_link
            href: 'http://seattlecityclub.org'
            "Seattle CityClub"
          ' have hosted the dialogue for five years and counting.'

        P 
          style: 
            paddingBottom: 15

          """
          We have since generalized Consider.it to apply to a variety of 
          situations, from helping organizations align behind new strategic 
          directions to its use in classrooms for teaching critical thinking 
          skills. 
          """

    DIV
      style:
        marginBottom: 20

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .6 - 40
          marginRight: 40
          verticalAlign: 'top'

        P 
          style: 
            paddingBottom: 15

          """
          We decided to leave our comfortable ivory tower for the 
          excitement of the jungle of capitalism after growing 
          frustrated by the academic system. Out of the 
          frying pan and into the fire, right?
          """

        P 
          style: 
            paddingBottom: 15
          """
          We are creating a decentralized R&D laboratory to 
          bring new social technologies into the world. We call this organization 
          The Invisible College. The Invisible College’s non-profit mission is 
          funded by internal for-profit companies based on the social technologies 
          we create. Consider.it is the most mature of these companies. 
          """          


        DIV null,
          """
          Published research about Consider.it:
          """
          UL
            style: 
              listStyle: 'none'

            LI 
              style: 
                paddingTop: 5

              A 
                style:  _.extend {}, story_link, 
                  textDecoration: 'underline'
                href: "http://dub.washington.edu/djangosite/media/papers/kriplean-cscw2012.pdf"
                'Supporting Reflective Public Thought with Consider.it'
              DIV 
                style: _.extend {}, small_text, 
                  fontSize: 16
                '2012 ACM Conference on Computer Supported Cooperative Work'


            LI
              style: 
                paddingTop: 15
              A 
                style:  _.extend {}, story_link, 
                  textDecoration: 'underline'
                href: "https://dl.dropboxusercontent.com/u/3403211/papers/jitp.pdf"
                'Facilitating Diverse Political Engagement'
              DIV 
                style: _.extend {}, small_text, 
                  fontSize: 16
                'Journal of Information Technology & Politics, Volume 9, Issue 3'

            LI 
              style: 
                paddingTop: 15
              A 
                style:  _.extend {}, story_link, 
                  textDecoration: 'underline'
                href: "http://homes.cs.washington.edu/~borning/papers/kriplean-cscw2014.pdf"
                'On-demand Fact-checking in Public Dialogue'

              DIV 
                style: _.extend {}, small_text, 
                  fontSize: 16
                '2014 ACM Conference on Computer Supported Cooperative Work'



      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .4
          verticalAlign: 'top'
          position: 'relative'


        IMG 
          src: asset('saas_landing_page/b&w_kev_mike.png')
          style: 
            width: 250
            position: 'relative'
            zIndex: 1

        IMG 
          src: asset('saas_landing_page/consult.png')
          style: 
            width: 250
            position: 'absolute'
            top: 150
            left: 80

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
      'Tell us '
      A
        style: _.extend {}, a, 
          fontSize: 36
          color: 'white'
        href: 'mailto:admin@consider.it'
        'your story' 
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
          width: SAAS_PAGE_WIDTH
          backgroundColor: "white"
          margin: "auto"
          paddingBottom: 20
          marginTop: 20
        BrowserHacks()
        Page(key: "/page" + loc.url)

      Footer()

      Tooltip()

      if app.dev
        Development()



window.Saas = Root

require './bootstrap_loader'
