require "../bubblemouth"
require "../svg"

VIDEO_FILE = 'slowdeathstarcam'


chapters = [
  {time:  6.0, caption: "Pretend we're considering this proposal", menu: "Consider an issue"},
  {time:  5.0, caption: "Consider.it helps us analyze its tradeoffs", menu: "Analyze tradeoffs"},
  {time:  8.5, caption: "Each thought becomes a Pro or Con point", menu: "Analyze tradeoffs"},
  {time:  7.0, caption: "We can learn from our peers", menu: "Learn from peers"},
  {time:  4.0, caption: "...and even build from them!", menu: "Learn from peers"},
  
  {time: 11.0, caption: "Weigh the tradeoffs on a slider", menu: "Slide overall opinion"},
  {time:  4.5, caption: "Now let's share our opinion", menu: "Slide overall opinion"},
  {time:  4.5, caption: "Behold: what people think, and why!", menu: "See what the group thinks"},
  {time:  4.0, caption: "A histogram shows the spectrum of opinions", menu: "Spectrum of opinion"},
  {time:  4.0, caption: "Points are ranked by importance to the group", menu: "Top tradeoffs"},

  {time:  8.5, caption: "Now explore patterns of thought!", menu: "Explore patterns of thought"},
  {time:  6.0, caption: "Learn the reservations of opposers", menu: "Explore patterns of thought"},
  {time: 12.5, caption: "Inspect a peer's opinion", menu: "Inspect a peer’s opinion"},
  {time:  8.0, caption: "See who resonates with the top Pro", menu: "Inspect a peer’s opinion"},
  {time:  4.0, caption: "Focus on a single point", menu: "Focus & discuss a single point"},
  {time: 11.0, caption: "...and discuss its implications", menu: "Focus & discuss a single point"},
  {time:  0.0, caption: "Those are the basics! Learn more below", menu: "Focus & discuss a single point"},
]



DEMO_AUTOPLAY_DELAY = 5000

video_width = Math.min(SAAS_PAGE_WIDTH(), window.innerWidth - 320)

hover_caption_color = primary_color()
caption_color =  "black" #primary_color() focus_blue
current_chapter_color = primary_color() #caption_color

exit_demo = -> 
  window.scrollTo(0,0)
  loc = fetch 'location'
  delete loc.query_params.play_demo
  save loc 



window.Video = ReactiveComponent
  displayName: "Video"
  render: ->

    DIV 
      id: 'demo'
      style: 
        position: 'relative'
        backgroundColor: 'white'
        minHeight: window.innerHeight
        paddingTop: 20

      @drawCaptions()

      DIV 
        style: 
          paddingTop: 10

        @drawVideo()      
        @drawChapterMenu()



      BUTTON 
        style:
          position: 'absolute'
          cursor: 'pointer'
          right: 40
          top: 40
          backgroundColor: 'transparent'
          border: 'none' 

        onClick: exit_demo
        onKeyPress: (e) -> 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            e.preventDefault()
            exit_demo()

        SVG 
          viewBox: "0 0 64 64" 
          width: 24
          height: 24
          PATH 
            d: "M62,52c0,5.5-4.5,10-10,10H12C6.5,62,2,57.5,2,52V12C2,6.5,6.5,2,12,2h40c5.5,0,10,4.5,10,10V52z" 
            fill: seattle_salmon
          PATH 
            fill: "#fff" 
            d: "M50 21.2 42.8 14 32 24.8 21.2 14 14 21.2 24.8 32 14 42.8 21.2 50 32 39.2 42.8 50 50 42.8 39.2 32z"



  drawVideo : -> 
        
    VIDEO
      preload: "auto"
      loop: true
      autoPlay: false
      ref: "video"
      controls: @props.playing
      style: 
        position: 'relative'
        width: video_width
        margin: 'auto'
        left: 160
        height: video_width * 1080/1920


      for format in ['mp4', 'webm']
        asset_path = asset("product_page/#{VIDEO_FILE}.#{format}")
        if asset_path?.length > 0
          SOURCE
            key: format
            src: asset_path
            type: "video/#{format}"

  drawCaptions: -> 
    chapter = fetch("video_chapter")

    DIV 
      style: _.extend {}, h1,
        fontWeight: 400
        whiteSpace: 'nowrap'
        paddingBottom: 5
        position: 'relative'
        zIndex: 1
        width: video_width - 1
        textAlign: 'center'
        left: 140

      DIV 
        style: 
          height: 70
          color: if @props.playing then primary_color()
  
        chapter.caption

      SVG 
        height: 10
        width: 60

        style:
          position: 'absolute'
          left: '50%'
          marginLeft: - 60 / 2
          bottom: -0

        POLYGON
          points: "0,0 30,10 60,0" 
          fill: primary_color()

        POLYGON
          points: "0,-1 30,9 60,-1" 
          fill: 'white'



  drawChapterMenu : -> 
    current_chapter = fetch("video_chapter")

    UL 
      style:
        position: 'absolute'
        top: 100
        left: 5
        listStyle: 'none'
        width: 120
        textAlign: 'right'

      for menu, idx in _.uniq (chapter.menu for chapter in chapters)
        do (menu) =>
          highlighted = menu == current_chapter.menu
          LI
            key: idx
            onMouseEnter: => 
              @local.hover_chapter = menu 
              save @local
            onMouseLeave: => 
              @local.hover_chapter = null
              save @local

            onClick: => 
              v = @refs.video.getDOMNode()

              chapter = fetch("video_chapter")
              controls = fetch('video_controls')

              chapter_time = 0
              new_chapter = null
              for c, idx in chapters
                if c.menu == menu
                  new_chapter = c
                  break
                chapter_time += c.time

              v.currentTime = chapter_time
              controls.value = chapter_time / v.duration
              chapter.caption = new_chapter?.caption
              chapter.menu = new_chapter?.menu
              save controls
              save chapter

            style: 
              color: if (highlighted || @local.hover_chapter == menu) then current_chapter_color else 'black'
              fontSize: 14
              fontWeight: if highlighted then 700 else 300
              padding: '10px 0'
              cursor: 'pointer'
            menu


  componentDidUpdate: -> @attachToVideo()
  componentDidMount: -> 
    @attachToVideo()
    @startVideo()

  startVideo : -> 
    controls = fetch('video_controls')
    controls.playing = true
    controls.value = 0

    try 
      video = @refs.video.getDOMNode()
      video.currentTime = 0      
      video.play()
    catch e 
      console.error e
      setTimeout => 
        @startVideo()
      , 500

    @local.ready = true
    @local.playing = true

    save controls
    save @local


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

        chapter_time = 0
        for c, idx in chapters
          if v.currentTime < chapter_time + c.time || idx == chapters.length - 1
            new_chapter = c
            break
          chapter_time += c.time

        controls.value = v.currentTime / v.duration

        save controls

        if chapter.caption != new_chapter?.caption
          chapter.caption = new_chapter.caption
          chapter.menu = new_chapter.menu
          save chapter
      , false

