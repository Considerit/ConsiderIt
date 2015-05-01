VIDEO_FILE = 'slowdeathstarcam'

window.Video = ReactiveComponent
  displayName: "video"
  render: ->

    controls = fetch('video_controls')
    chapter = fetch("video_chapter")

    if !@local.ready
      chapter.text = 'Get ready for your video demo!'

    DIV 
      id: 'demo'
      style: 
        width: SAAS_PAGE_WIDTH
        margin: "25px auto 0 auto"
        position: 'relative'

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

        for format in ['mp4', 'webm']
          asset_path = asset("saas_landing_page/#{VIDEO_FILE}.#{format}")
          if asset_path?.length > 0
            SOURCE
              src: asset_path
              type: "video/#{format}"
          

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