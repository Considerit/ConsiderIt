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

VIDEO_FILE = 'slowdeathstarcam'

window.SAAS_PAGE_WIDTH = 1000
window.TEXT_WIDTH = 730
window.lefty = false

window.base_text =
  fontSize: 24
  fontWeight: 400
  fontFamily: "'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"

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
      enables()
      FAQ()
      pricing()
      Contact()
      Story()


HEADER_HEIGHT = 30

Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    docked = fetch('header-dock').docked

    nav_links = ['demo', 'faq', 'price', 'contact', 'story']
    
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


Video = ReactiveComponent
  displayName: "video"
  render: ->

    controls = fetch('video_controls')
    chapter = fetch("video_chapter")

    if !@local.ready
      chapter.text = 'Get ready for your video demo!'

    DIV 
      id: 'demo'
      style: 
        marginTop: 25
        width: SAAS_PAGE_WIDTH

      DIV 
        style: _.extend {}, h1,
          color: 'white'
          whiteSpace: 'nowrap'
        chapter.text

      @drawVideo()

      if @local.ready
        A
          href: 'https://fun.consider.it/Death_Star'
          target: '_blank'
          style: 
            cursor: 'pointer'
            color: focus_blue
            textDecoration: 'underline'
            fontSize: 16
            position: 'absolute'
            right: 0
            marginTop: 5
            display: 'inline-block'
          'Explore this example yourself'

  drawVideo : -> 
    
    DIV
      id: "homepage_video"
      style:
        position: 'relative'
        width: SAAS_PAGE_WIDTH - 1
        height: (SAAS_PAGE_WIDTH - 2) * 1080/1920 + 2
        border: "1px solid #ccc"
        borderTop: 'none'
        borderRadius: 8
        backgroundColor: 'white'
        boxShadow: "0 3px 8px rgba(0,0,0,.1)"
        marginTop: 8
      
      VIDEO
        preload: "auto"
        loop: true
        autoPlay: false
        ref: "video"
        controls: true
        style: 
          marginTop: 1
          width: SAAS_PAGE_WIDTH - 2
          height: (SAAS_PAGE_WIDTH - 2) * 1080/1920
          borderRadius: 8

        SOURCE
          src: asset("saas_landing_page/#{VIDEO_FILE}.mp4")
          type: "video/mp4"
        
        SOURCE
          src: asset("saas_landing_page/#{VIDEO_FILE}.webm")
          type: "video/webm"

      if !@local.ready      
        # Draw a white loading if we're not ready to show video
        DIV 
          style:
            top: 0
            left: 0
            borderRadius: 8
            backgroundColor: 'white'
            position: 'absolute'
            height: '100%'
            width: '100%'
            boxShadow: "0 3px 8px rgba(0,0,0,.1)"


          DIV 
            style: 
              id: 'loading_logo'
              position: 'absolute'
              left: '50%'
              top: '50%'
              marginLeft: -(284 / 60 * 100) / 2
              marginTop: -150

            drawLogo 100, 
              logo_red,
              logo_red, 
              false,
              true,
              '#ccc',
              10

  componentDidUpdate: -> @attachToVideo()
  componentDidMount: -> 
    setTimeout => 
      $(@getDOMNode()).find('#i_dot')
        .css css.crossbrowserify
          transition: "transform #{3500}ms"
        .css css.crossbrowserify
          transform: "translate(241.75px, 0)"
    , 1000


    @attachToVideo()

    timer = 5000 # how long to wait before playing video

    setTimeout => 
      controls = fetch('video_controls')
      controls.playing = true
      @refs.video.getDOMNode().play()
      @local.ready = true
      save controls
      save @local
    , timer + 200


  attachToVideo : -> 
    # we use timeupdate rather than tracks / cue changes / vtt
    # because browser implementations are not complete (and often buggy)
    # and polyfills poor. 

    v = @refs.video.getDOMNode()

    chapters = [
      {time:  6.0, caption: "Pretend we're considering a proposal"},
      {time:  5.0, caption: "Consider.it helps us analyze its tradeoffs"},
      {time:  8.5, caption: "Each thought becomes a Pro or Con point"},
      {time:  7.0, caption: "We can learn from our peers"},
      {time:  4.0, caption: "...and even build from them!"},
      
      {time: 11.0, caption: "Weigh the tradeoffs on a slider"},
      {time:  4.5, caption: "Now let's share our opinion"},
      {time:  4.5, caption: "Behold: what people think, and why!"},
      {time:  4.0, caption: "A histogram shows the spectrum of opinions"},
      {time:  4.0, caption: "Points are ranked by importance to the group"},

      {time:  8.5, caption: "Now explore patterns of thought!"},
      {time:  6.0, caption: "Learn the reservations of opposers"},
      {time: 12.5, caption: "Inspect a peer's opinion"},
      {time:  8.0, caption: "See who resonates with the top Pro"},
      {time:  4.0, caption: "Focus on a single point"},
      {time: 11.0, caption: "...and discuss its implications"},
      {time:  0.0, caption: "Those are the basics! Learn more below"},
    ]

    if @v != v
      @v = v
      v.addEventListener 'timeupdate', (ev) -> 
        chapter = fetch("video_chapter")
        controls = fetch('video_controls')

        chapter_time = 0
        for c, idx in chapters
          if v.currentTime < chapter_time + c.time || idx == chapters.length - 1
            text = c.caption
            break
          chapter_time += c.time

        controls.value = v.currentTime / v.duration

        save controls

        if chapter.text != text
          chapter.text = text
          save chapter
      , false

  # drawVideoControls : ->
  #   VIDEO_SLIDER_WIDTH = 250

  #   controls = fetch('video_controls')

  #   DIV 
  #     onMouseEnter: (ev) => @local.hover_player = true; save @local
  #     onMouseLeave: (ev) => @local.hover_player = false; save @local

  #     style: 
  #       width: VIDEO_SLIDER_WIDTH + 80
  #       margin: 'auto'
  #       position: 'relative'
  #       opacity: if @local.hover_player then 1 else .5
  #       top: -10
  #     I 
  #       className: "fa fa-#{if controls.playing then 'pause' else 'play'}"
  #       onClick: (ev) => 
  #         controls = fetch('video_controls')
  #         controls.playing = !controls.playing
  #         save controls
  #         if controls.playing 
  #           @refs.video.getDOMNode().play()
  #         else
  #           @refs.video.getDOMNode().pause()

  #       style:       
  #         fontSize: 10
  #         color: '#ccc'
  #         #position: 'relative'
  #         padding: '12px 12px'
  #         cursor: 'pointer'
  #         visibility: if @local.hover_player then 'visible' else 'hidden'
  #         left: -12

  #     Slider
  #       key: 'video_controls'
  #       width: VIDEO_SLIDER_WIDTH
  #       handle_height: if @local.hover_player then 20 else 4
  #       base_height: 4
  #       base_color: '#ECECEC'
  #       slider_style: 
  #         margin: 'auto'
  #         position: 'absolute'
  #         top: '50%'
  #         marginTop: -2
  #         left: 40
  #       handle_props: 
  #         color: logo_red

  #       onMouseDownCallback: (ev) =>
  #         video = @refs.video.getDOMNode()
  #         video.pause()

  #       onMouseMoveCallback: (ev) => 
  #         controls = fetch('video_controls')
  #         video = @refs.video.getDOMNode()
  #         video.currentTime = controls.value * video.duration

  #       onMouseUpCallback: (ev) => 
  #         controls = fetch('video_controls')
  #         video = @refs.video.getDOMNode()
  #         video.play() if controls.playing

  #       onClickCallback: (ev) =>
  #         controls = fetch('video_controls')
  #         video = @refs.video.getDOMNode()
  #         video.pause()
  #         video.currentTime = controls.value * video.duration
  #         video.play() if controls.playing  



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
        style: _.extend {}, base_text, 
          fontWeight: 300
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
      strong: "Focus on specific ideas"
      body: """
            . Collect opinions on proposals, plans, hypotheticals, 
            job candidates, products, designs, and more.
            """
    bullet
      point_style: 'bullet'
      strong: "Foster considerate interactions"
      body: """
            . The design orients people to consider the topic, 
            rather than responding directly to each other. 
            Opportunities for personal attacks on others are limited.
            """
    bullet
      point_style: 'bullet'
      strong: "Produce an interactive summary of individual opinions"
      body: """
            . Patterns of thought across the whole group can 
            be identified. Perhaps 80% of opposers have a 
            single con point that can be addressed!
            """

enables = -> 
  DIV
    id: 'uses'
    style:
      marginTop: 60

    H1 style: h1,
      'It can help you...'

    bullet
      point_style: 'bullet'
      strong: "Involve five, fifty, or even hundreds of people in deliberation"
      body: ". All voices can be heard without becoming overwhelming."

    bullet
      point_style: 'bullet'
      strong: "Lead change"
      body: """
            . Collect organized feedback from employees, membership, and stakeholders
            for strategic planning, process improvement, program evaluation, and other 
            change efforts. Strong leaders create change by explaining and evolving plans. 
            """

    bullet
      point_style: 'bullet'
      strong: "Decentralize decision making"
      body: """
            . Make decisions as a whole, without resorting to hierarchy. The will of a community, 
            and the thoughts behind that will, become visible and actionable.
            """

    bullet
      point_style: 'bullet'
      strong: "Teach critical thinking"
      body: """
            . Students learn how to develop and express a considered opinion while listening 
            to and engaging with others' ideas. Supports Common Core aligned exercises 
            in English and Social Studies.
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


ExpandingQuestion = ReactiveComponent
  displayName: 'ExpandingQuestion'

  render : -> 
    DIV
      style:
        paddingLeft: 30
        position: "relative"
        margin: "30px auto"
        width: TEXT_WIDTH



      I
        className: "fa fa-chevron-#{if @local.active then 'down' else 'right'}"
        style: 
          fontSize: 30
          position: "absolute"
          left: -15
          top: 6
          color: logo_red
          cursor: 'pointer'

        onClick: => 
          @local.active = !@local.active
          save @local

      DIV
        style: _.extend {}, base_text, 
          fontWeight: if @local.active then 600
          cursor: 'pointer'
        onClick: => 
          @local.active = !@local.active
          save @local

        @props.question

      DIV 
        style: _.extend {}, small_text, 
          #fontWeight: 300
          display: if !@local.active then 'none'

        @props.answer()


FAQ = ReactiveComponent
  displayName: 'FAQ'

  render : -> 
    p = 
      marginTop: 15

    qs = [{
      question: 'What happens when I sign up for Consider.it?'
      answer: ->
        DIV null,
          P style: p,
            'You\'ll get your very own customizable Consider.it site. '
          P style: p,
            """
            Say that you’re a fantasy football fan and want to use Consider.it 
            to debate fantasy football decisions with other rabid fans. When 
            you sign up for Consider.it, you 
            specify a name like "fantasy-football". Congratulations, you are 
            now the proud administrator of https://fantasy-football.consider.it! 
            """
          P style: p,
            """
            First, you might want to give it the look and feel you desire by 
            adding a custom logo and fancy homepage banner image you 
            designed. You might also want to configure who can access 
            the site (in this case, everyone) and who can post content (any 
            registered user). A variety of options are available to make 
            your Consider.it site work the way you wish. 
            """
          P style: p,
            """
            Next you'll want to add a question or two. Or ten. You create a 
            section of questions that allow people to debate whether it is a 
            good idea to start a particular player, and another section that 
            solicits suggestions about the best strategies for managing your 
            fantasy team. Each section is shown on the homepage and you 
            configure it so that any user can add new suggestions. 
            """
          P style: p,
            """Finally, invite your friends and family, or whomever you want 
            to participate!"""

      }, {
      question: 'Can I solicit responses to open ended questions like "Which policies should we revise?"'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Can I moderate user content? Is it hard?'
      answer: ->
        DIV null,
          P style: p,
            'You\'ll get your very own customizable Consider.it site. '
          P style: p,
            """
            Say that you’re a fantasy football fan and want to use Consider.it 
            to debate fantasy football decisions with other rabid fans. When 
            you sign up for Consider.it, you 
            specify a name like "fantasy-football". Congratulations, you are 
            now the proud administrator of https://fantasy-football.consider.it! 
            """
          P style: p,
            """
            First, you might want to give it the look and feel you desire by 
            adding a custom logo and fancy homepage banner image you 
            designed. You might also want to configure who can access 
            the site (in this case, everyone) and who can post content (any 
            registered user). A variety of options are available to make 
            your Consider.it site work the way you wish. 
            """
          P style: p,
            """
            Next you'll want to add a question or two. Or ten. You create a 
            section of questions that allow people to debate whether it is a 
            good idea to start a particular player, and another section that 
            solicits suggestions about the best strategies for managing your 
            fantasy team. Each section is shown on the homepage and you 
            configure it so that any user can add new suggestions. 
            """
          P style: p,
            """Finally, invite your friends and family, or whomever you want 
            to participate!"""

      }, {
      question: 'Can I create a private discussion and send out invitations?"'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Is it possible to set different permissions for who can, for example, post a new idea or write a new pro/con point?'
      answer: ->
        DIV null,
          P style: p,
            'You\'ll get your very own customizable Consider.it site. '
          P style: p,
            """
            Say that you’re a fantasy football fan and want to use Consider.it 
            to debate fantasy football decisions with other rabid fans. When 
            you sign up for Consider.it, you 
            specify a name like "fantasy-football". Congratulations, you are 
            now the proud administrator of https://fantasy-football.consider.it! 
            """
          P style: p,
            """
            First, you might want to give it the look and feel you desire by 
            adding a custom logo and fancy homepage banner image you 
            designed. You might also want to configure who can access 
            the site (in this case, everyone) and who can post content (any 
            registered user). A variety of options are available to make 
            your Consider.it site work the way you wish. 
            """
          P style: p,
            """
            Next you'll want to add a question or two. Or ten. You create a 
            section of questions that allow people to debate whether it is a 
            good idea to start a particular player, and another section that 
            solicits suggestions about the best strategies for managing your 
            fantasy team. Each section is shown on the homepage and you 
            configure it so that any user can add new suggestions. 
            """
          P style: p,
            """Finally, invite your friends and family, or whomever you want 
            to participate!"""

      }, {
      question: 'Can I ask custom questions of users of my site?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Can I style my Consider.it site so that it fits with my brand?'
      answer: ->
        DIV null,
          P style: p,
            'You\'ll get your very own customizable Consider.it site. '
          P style: p,
            """
            Say that you’re a fantasy football fan and want to use Consider.it 
            to debate fantasy football decisions with other rabid fans. When 
            you sign up for Consider.it, you 
            specify a name like "fantasy-football". Congratulations, you are 
            now the proud administrator of https://fantasy-football.consider.it! 
            """
          P style: p,
            """
            First, you might want to give it the look and feel you desire by 
            adding a custom logo and fancy homepage banner image you 
            designed. You might also want to configure who can access 
            the site (in this case, everyone) and who can post content (any 
            registered user). A variety of options are available to make 
            your Consider.it site work the way you wish. 
            """
          P style: p,
            """
            Next you'll want to add a question or two. Or ten. You create a 
            section of questions that allow people to debate whether it is a 
            good idea to start a particular player, and another section that 
            solicits suggestions about the best strategies for managing your 
            fantasy team. Each section is shown on the homepage and you 
            configure it so that any user can add new suggestions. 
            """
          P style: p,
            """Finally, invite your friends and family, or whomever you want 
            to participate!"""

      }, {
      question: 'Does Consider.it work on mobile devices?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'What browsers do you support?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Can we self-host Consider.it on our own servers?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Can we use our own URL?"'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Is Consider.it open source? Can we use and modify the source code?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Consider.it is missing X feature that I need. What do can I do?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Do you support Single-Sign On (SSO)?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }, {
      question: 'Do you integrate with X service?'
      answer: ->
        DIV null,
          P style: p,
            'Yes.'

          P style: p,
            """
            Say that you are using https://startup-inc.consider.it to help your startup 
            of 25 employees (and soon 30) deliberate about how to improve process 
            given rapid growth. You want to help maintain the fun, casual atmosphere, 
            but you also recognize that some formalization of policy may be necessary.
            """

          P style: p,
            'You decide to solicit ideas from your employees. '

      }]

    if !@local.show_all_questions
      qs = qs.slice(0,4)

    DIV 
      id: 'faq'
      style:
        marginTop: 60


      H1
        style: _.extend {}, h1, 
          marginBottom: 30

        "Frequently Asked Questions"

      DIV 
        style: 
          postion: 'relative'

        for q in qs
          ExpandingQuestion q


      DIV 
        style: 
          width: TEXT_WIDTH
          backgroundColor: '#F7F7F7'
          textAlign: 'center'
          textDecoration: 'underline'
          cursor: 'pointer'
          padding: '5px 0'
          margin: 'auto'
        onClick: =>
          @local.show_all_questions = !@local.show_all_questions
          save @local

        if @local.show_all_questions
          "Collapse questions"
        else
          "Show more questions"




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
          width: SAAS_PAGE_WIDTH
          backgroundColor: "white"
          margin: "auto"
          paddingBottom: 20
          marginTop: 20
        BrowserHacks()
        Page()

      Footer()

      Tooltip()

      Computer()



window.Saas = Root

require '../bootstrap_loader'
