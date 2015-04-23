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
require './dock'
require './logo'

SAAS_PAGE_WIDTH = 1000
TEXT_WIDTH = 730
window.lefty = false

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
        video_file_name: 'slowdeathstarcam'
        video_file_name_instr: "Only available video is 'slowdeathstarcam'"
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

    DIV
      style: 
        position: 'relative'

      DIV 
        style: 
          margin: '35px 0'

      DIV 
        id: 'video'
        Video()

      DIV 
        id: 'tech'
        tech()

      enables()
      uses()
      features()
      pricing()
      contact(@local)
      story()


HEADER_HEIGHT = 30

Header = ReactiveComponent
  displayName: "Header"
  render: ->
    console.log 'render'
    current_user = fetch("/current_user")

    docked = fetch('header-dock').docked

    nav_link_style = _.extend {}, base_text,
      fontWeight: 300
      fontSize: 20
      color: 'white' #if @local.in_red then logo_red else 'white'
      marginLeft: 25
      cursor: 'pointer'

    
    DIV
      style:
        position: "relative"
        margin: "0 auto"
        backgroundColor: logo_red #if @local.in_red then 'white' else logo_red
        height: HEADER_HEIGHT
        #overflow: if $(window).scrollTop() > 0 && !@local.in_red then 'hidden'
        #overflow: if $(window).scrollTop() > 0  then 'hidden'
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

          drawLogo HEADER_HEIGHT + 5, \
                  'white', \ #(if @local.in_red then logo_red else 'white'), \
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

            A 
              style: nav_link_style
              href: "#video"
              'demo'

            # A 
            #   style: nav_link_style
            #   href: "#uses"
            #   'Uses'

            # A 
            #   style: nav_link_style
            #   href: "#features"
            #   'Features'

            A 
              style: nav_link_style
              href: "#pricing"
              'price'
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

  componentDidMount : -> 

    # setTimeout => 
    #   $('#i_dot')
    #     .css css.crossbrowserify
    #       transition: "transform #{1500}ms"
    #     .css css.crossbrowserify
    #       transform: "translate(#{252.25 - 142}px, 0)"
    # , 700


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
      
      if ui.frame == 'none'
        @drawVideoControls()
      @drawVideo()

    DIV null,
      @drawCaptions()

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
        marginTop: 20

      # window bar / url
      DIV 
        style: 
          height: 31
          borderRadius: '8px 8px 0 0'
          backgroundColor: '#ccc'
          backgroundImage: "linear-gradient(0deg, #D4D3D4, #EEEDEE)"
          boxShadow: "0 1px 1px rgba(0,0,0,.35)"
          position: 'relative'

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
              color: '#666'
            'https://fun.consider.it/Death_Star'

      DIV null,

        children 


  drawCaptions : -> 
    ui = fetch('homepage_ui')
    chapter = fetch("video_chapter")

    if !@local.ready
      #chapter.text = "Showing what Consider.it does in " + (if @local.time_to_video? then @local.time_to_video else 5)
      chapter.text = "The tour begins in " + (if @local.time_to_video? then @local.time_to_video else 5)

    DIV
      style:
        position: 'relative'
        zIndex: 1
        top: if ui.frame == 'laptop' then -12
        

      H2
        style: _.extend {}, h1,
          #textAlign: "left"
          fontSize: if ui.frame == 'laptop' then 30 else 36
          color: 'white' #if ui.frame == 'laptop' then 'white' else 'black'

        
        chapter.text 

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
        autoPlay: false
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

    timer = 5000 # how long to wait before playing video

    setTimeout => 

      # wait a couple seconds before playing video to give user time to 
      # orient to homepage
      setTimeout => 
        controls = fetch('video_controls')
        controls.playing = true
        save controls
        @local.ready = true
        save @local
        @refs.video.getDOMNode().play()
      , timer + 200

      tick = => 
        if timer > 1000
          setTimeout tick, 1000

        @local.time_to_video = timer / 1000 - 1

        timer -= 1000        
        save @local

      tick()
    , 1500

  attachToVideo : -> 
    # we use timeupdate rather than tracks / cue changes / vtt
    # because browser implementations are not complete (and often buggy)
    # and polyfills poor. 

    v = @refs.video.getDOMNode()

    chapters = [
      {time:  6.0, caption: "Pretend we're considering a proposal"},
      {time:  5.0, caption: "Consider.it helps us analyze the tradeoffs"},
      {time:  8.5, caption: "Each thought becomes a Pro or Con point"},
      {time:  7.0, caption: "We can learn from our peers"},
      {time:  4.0, caption: "...and even build from them!"},
      
      {time: 11.0, caption: "Weigh the tradeoffs on a slider."},
      {time:  4.5, caption: "Seems reasonable. Let's add our opinion to the group."},
      {time:  4.5, caption: "Behold! A summary of what people think and why"},
      {time:  4.0, caption: "The spectrum of opinions is shown on a Histogram"},
      {time:  4.0, caption: "Points are ranked by importance for the group"},

      {time:  8.5, caption: "Now explore patterns of thought!"},
      {time:  6.0, caption: "Learn the reservations of opposers"},
      {time: 12.5, caption: "Inspect a peer's opinion"},
      {time:  8.0, caption: "See who has been persuaded by the top Pro"},
      {time: 16.0, caption: "Focus on a single point and discuss its merits"},
      {time:  0.0, caption: "Those are the basics! Scroll down to learn more."},
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
  ui = fetch('homepage_ui')
  DIV
    style:
      marginTop: if ui.frame == 'laptop' then 30 else 60

    H1 style: h1,
      'The first forum that works better'
      BR null,
      'when more people participate'

    bullet
      point_style: 'bullet'
      strong: "Focus on specific ideas"
      body: ". Collect opinions on proposals, plans, hypotheticals, job candidates, products, designs, and more."

    bullet
      point_style: 'bullet'
      strong: "Foster considerate interactions"
      body: """. The interface orients people to consider the topic, 
               rather than responding directly to each other. The design limits 
               opportunities for personal attacks on others.
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
                 to and engaging with others' ideas. Supports Common Core aligned exercises 
                 in English and Social Studies.
            """

uses = -> 
  DIV 
    id: 'situations'
    # style:
    #   marginTop: 60


    # DIV 
    #   style: h1

    #   'Use Consider.it when:'

    # DIV 
    #   style: _.extend {}, base_text,
    #     width: TEXT_WIDTH
    #     margin: 'auto'

    #   'Placeholder for uses'



features = -> 
  DIV 
    id: 'features'
    # style:
    #   marginTop: 60

    # DIV 
    #   style: h1

    #   'Features include:'

    # DIV 
    #   style: _.extend {}, base_text,
    #     width: TEXT_WIDTH
    #     margin: 'auto'

    #   'Placeholder for features section'

pricing = ->
  DIV 
    id: 'pricing'
    style:
      marginTop: 60

    DIV 
      style: h1

      'Pricing'

    DIV 
      style: _.extend {}, base_text,
        width: TEXT_WIDTH
        margin: 'auto'

      'Free pilots of Consider.it for a limited time! '

      A 
        style: a 
        'Contact us'

      ' to get started today. '
      BR null
      BR null
      'Advanced configuration and custom design available.'

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

story = ->
  caption_text =
    fontSize: 14
    fontWeight: 400   
    lineHeight: 1.4
    paddingTop: 5

  story_link = _.extend {}, a, small_text,
    textDecoration: 'none'
    borderBottom: "1px solid #{logo_red}"

  section_style = 
    marginBottom: 20
    paddingTop: 10

  DIV 
    id: 'story'
    style:
      marginTop: 60

    H1
      style: _.extend {}, h1, 
        marginBottom: 30

      "Our story"

    DIV
      style: section_style

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
          The idea for Consider.it was born on a cloudy Seattle morning 
          while Travis sat on the ground outside of a """
          A 
            href: 'https://www.google.com/maps/place/Montlake+Bicycle+Shop/@47.639382,-122.302025,3a,75y,284.92h,78.85t/data=!3m4!1e1!3m2!1sqE4cgPSn9t_eCx1xr5HsEQ!2e0!4m2!3m1!1s0x549014c486e2f9c1:0x7b96d3f907c7f742'
            style: story_link
            'bike shop'

          """
          . He was feeling 
          down after spending a few dark hours reading hundreds of comments 
          on news articles about the Affordable Care Act. So much talking past 
          one another. Such wasted effort. 
          """

        P 
          style: 
            paddingBottom: 15

          """
          Humanity's ability to listen and learn is ever so fragile, easily broken 
          by poor habits and flawed tools. The problem is not limited to online 
          comment boards. Email threads involving close colleagues and even face 
          to face conversations with loved ones can easily degenerate. Travis 
          knew he was no exception to the problem; but that day, at least, Travis 
          was happy to turn his frustration into a blueprint for improvement.
          """

      DIV 
        style: 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .4
          marginTop: 10

        IMG
          style: 
            width: 400
            display: 'block'
            margin: 'auto'
          src: asset('saas_landing_page/child.png') 

        DIV
          style: caption_text

          """
          The Web is only 2.0 years old (3.0 claim some pundits). 
          It's social. It's getting good at speaking. But it’s not yet very 
          good at listening.
          """



    DIV
      style: section_style




      DIV 
        style: 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .4
          marginTop: 10

        
        IFRAME
          width: 400
          height: 243
          src: "https://www.youtube.com/embed/jl1AsVM_8hk?modestbranding=1&showinfo=0&theme=dark&fs=1" 
          frameborder: "0" 
          allowfullscreen: true

        DIV
          style: caption_text

          'Travis\' Phd defense, from December 2011. Here is the full '
          A 
            style: _.extend {}, story_link, caption_text
            href: 'https://dl.dropboxusercontent.com/u/3403211/papers/dissertation.pdf'
            "dissertation"
          ' for those of you with great '
          SPAN 
            style: 
              textDecoration: 'line-through'
            'foolishness'
          ' fortitude.'           

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .6 - 40
          verticalAlign: 'top'
          marginLeft: 40


        """
        Travis was in a privileged position to spend time thinking about these 
        issues. He was pursuing a PhD in Computer Science at the University of 
        Washington, doing research grounded in the belief that we can 
        improve our capacity for collective action. He was supported by a generous 
        """
        A
          href: "http://www.nsf.gov/awardsearch/showAward?AWD_ID=0966929"
          style: story_link
          "National Science Foundation grant"
        ' he had written with his advisor '
        A
          style: story_link
          href: 'http://www.cs.washington.edu/people/faculty/borning'
          'Alan Borning'
        ' and political communication expert '
        A
          style: story_link
          href: 'http://www.com.washington.edu/bennett/'
          'Lance Bennett'

        '. Previously he had spent a couple of years researching how contributors to the 
        world\'s greatest deliberative project, Wikipedia, '
        A
          style: story_link
          href: 'http://dub.washington.edu/djangosite/media/papers/tmpZ77p1r.pdf'
          'collaborate together'
        ' and '
        A
          style: story_link
          href: 'http://www.aaai.org/Papers/ICWSM/2008/ICWSM08-011.pdf'
          'mediate'
        ' ' 
        A
          style: story_link
          href: 'https://www.cs.ubc.ca/~bestchai/papers/group07.pdf'
          'conflict'

        '. Travis was ready to channel this knowledge into invention.'



    DIV
      style: section_style

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .45 - 40
          marginRight: 40
          verticalAlign: 'top'

          

        P 
          style: 
            paddingBottom: 15

          """
          Travis found a kindred spirit in fellow graduate student Michael Toomim. 
          Michael's incisive and persistent feedback helped Travis transform his 
          abstract knowledge and ideas into concrete designs. They started collaborating 
          with each other on their respective projects. Bits and pieces of ideas 
          that Michael and Travis had kicked around before had suddenly coalesced in 
          that moment when Consider.it was born outside the bike shop. 
          """


      DIV 
        style: 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .55
          marginTop: 10
          position: 'relative'
          height: 380

        
        DIV 
          style: 
            width: 350

          IMG
            style: 
              width: 350
              display: 'block'
            src: asset('saas_landing_page/consult.png') 

          DIV
            style: caption_text

            'Late night collaboration!'

        DIV 
          style: 
            position: 'absolute'
            zIndex: 1
            width: 208
            top: 160
            left: 315

          IMG 
            src: asset('saas_landing_page/mike_talk.png')
            style: 
              width: 208

          DIV
            style: caption_text

            'Mike making a profound point that has been lost to time.'


    DIV 
      style: section_style

      DIV 
        style: 
          display: 'inline-block'
          verticalAlign: 'middle'
          width: SAAS_PAGE_WIDTH * .4
          marginTop: 10

        IMG 
          src: asset('saas_landing_page/sifp.jpg')
          width: 400


        DIV
          style: caption_text

          'Travis delivers the '
          A
            style: _.extend {}, story_link, caption_text
            href: 'https://www.youtube.com/watch?v=RIUD4Ty2ZAE'
            'winning talk'
          """ 
           at Social Innovation Fast Pitch. This excellent experience was an
          awkward transitionary point in our history: straddling academia and the 
          private sector, while representing our non-profit partner in a pitch 
          competition.
          """

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .6 - 40
          verticalAlign: 'top'
          marginLeft: 40

        P 
          style: 
            paddingBottom: 15

          'Consider.it debuted in 2010 as the engine behind the '
          A
            style: story_link
            href:'https://livingvotersguide.org'
            "Living Voters Guide"          
          
          ', in partnership with the civic non-profit '
          A 
            style: story_link
            href: 'http://seattlecityclub.org'

            'Seattle CityClub' 

          """
          . This election season dialogue creates a space for citizens to express 
          their opinions about difficult ballot initiatives and to hear and learn from 
          the opinions of their peers. The research team demonstrated 
          that the technology encouraged voters to listen to both sides, 
          recognize points by people with whom they disagree and change their opinion 
          based on something they read. The voters guide has now weathered five election cycles, with 
          """

          A
            style: story_link
            href: "http://blogs.seattletimes.com/monica-guzman/2012/10/27/seattle-library-fact-check-experiment-risky-but-valuable/"
            'on-demand fact-checking' 

          ' delivered by Seattle Public Librarians since 2012.'

        P 
          style: 
            paddingBottom: 15
          """
          Travis recognized that the technology had broad applicability 
          beyond civic engagement, and he generalized the technology.
          """


    DIV
      style: section_style

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
          As Travis and Michael approached the end of their PhD programs, they 
          decided to leave academia. It had become 
          clear to Travis and Mike that academia's emphasis on prototyping, papers, 
          and peer review limited how far and in what manner ideas could be 
          brought into the world. Instead, they would create their own 
          company/laboratory that supported the form of inquiry they felt would 
          maximize their contributions. We call this organization The 
          Invisible College.
          """          

      DIV 
        style: 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .4
          verticalAlign: 'top'
          position: 'relative'



        IFRAME 
          src: "https://player.vimeo.com/video/12116723?portrait=0&byline=0&title=0" 
          width: 300
          height: 225 
          style: 
            display: 'block'


        DIV
          style: caption_text

          A 
            style: _.extend {}, story_link, caption_text
            href: 'http://engage.cs.washington.edu/reflect/'
            'Reflect'

          """
           is Consider.it’s sister project. Reflect promotes 
          active listening in comment forums. We deployed it in Slashdot 
          and Wikimedia’s strategic planning process. The project is inactive 
          currently, though it is still dear to our hearts. 
          """
          A
            style: _.extend {}, story_link, caption_text
            href: 'http://dub.washington.edu/djangosite/media/papers/tmptxCAiy.pdf'
            'Learn more'
          '.'

    DIV 
      style: section_style

      DIV 
        style: 
          display: 'inline-block'
          verticalAlign: 'middle'
          width: SAAS_PAGE_WIDTH * .4
          marginTop: 10

        IMG 
          src: asset('saas_landing_page/truth.png')
          width: 400


        DIV
          style: caption_text

          'Kevin standing up for Truth and Justice.'

      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .6 - 40
          verticalAlign: 'top'
          marginLeft: 40

        P 
          style: 
            paddingBottom: 15

          """
          While wrapping up their academic pursuits, Mike and Travis 
          met Kevin Miniter. Kevin had just arrived in Seattle, eager for his next 
          adventure after running the campaign for the """
          A
            style: story_link
            href:'http://www.washingtonpost.com/wp-dyn/content/article/2011/02/02/AR2011020203272.html'
            "first openly gay presidential candidate"          

          '. The icy mornings in New Hampshire and the afternoons driving a sound 
          truck blasting reggaeton through '
          A 
            href: 'http://news.yahoo.com/blogs/ticket/ron-paul-topped-ran-fred-karger-puerto-rican-153210979.html'
            style: story_link
            'Puerto Rico' 
          """ had affirmed his love for 
          this country, but did little to cure his skepticism about its politics. 
          Kevin saw that there was a deeper problem of listening and critical 
          thinking behind our political strife. While trudging through the 
          startup world, he learned about Consider.it. He badgered Travis for 
          a meeting and asked the question that always starts an 
          adventure: "How can I help?"
          """
          

    DIV
      style: section_style

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
          And here we are now! 
          As a startup, we are exploring different markets beyond civic 
          engagement. We're using Consider.it to 
          align the opinions of employees during organizational change 
          efforts, where Consider.it's ability to surface knowledge and 
          identify sticking points across a large group of people can help
          the planning process. We're applying Consider.it to decision-making 
          and deliberation in decentralized online communities. Finally, 
          Consider.it's concentration on tradeoffs is a good fit for schools 
          teaching the new Common Core critical thinking skills."""
        P
          style: 
            paddingBottom: 15

          'Thanks for listening to our story. If you like our story 
          and believe in our vision, '
          A 
            href: 'mailto:admin@consider.it' 
            style: story_link
            'send us a message'
          '. Maybe we can collaborate! Or send us witty hate mail if you wish, we welcome adversaries.'


      DIV 
        style: 
          display: 'inline-block'
          width: SAAS_PAGE_WIDTH * .4
          verticalAlign: 'top'
          position: 'relative'

        IMG 
          src: asset('saas_landing_page/kev_mike.png')
          style: 
            width: 400
            position: 'relative'
            zIndex: 1

        DIV
          style: caption_text

          "Kevin and Mike in their natural habitat."


    DIV
      style: section_style


      DIV 
        style: _.extend {}, small_text, 
          display: 'inline-block'
          verticalAlign: 'top'

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
                style:  _.extend {}, story_link
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
                style:  _.extend {}, story_link
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
                style:  _.extend {}, story_link
                href: "http://homes.cs.washington.edu/~borning/papers/kriplean-cscw2014.pdf"
                'On-demand Fact-checking in Public Dialogue'

              DIV 
                style: _.extend {}, small_text, 
                  fontSize: 16
                '2014 ACM Conference on Computer Supported Cooperative Work'





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


Root = ReactiveComponent
  displayName: "Root"

  render: ->
    loc = fetch 'location'
    app = fetch '/application'
    doc = fetch 'document'

    title = 'Consider.it | Think better together'
    if doc.title != title
      doc.title = title
      save doc

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
        Page(key: "/page" + loc.url)

      Footer()

      Tooltip()

      if app.dev
        Development()



window.Saas = Root

require './bootstrap_loader'
