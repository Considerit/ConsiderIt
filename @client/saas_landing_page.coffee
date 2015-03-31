require './activerest-m'
require './auth'
require './avatar'
require './browser_hacks'
require './browser_location'
require './tooltip'
require './shared'

base_text =
  fontSize: 24
  fontWeight: 200
  fontFamily: "'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"

h1 = _.extend {}, base_text,
  fontSize: 72
  fontWeight: 400

h2 = _.extend {}, base_text,
  fontSize: 48
  fontWeight: 700

h3 = _.extend {}, base_text,
  fontSize: 36
  fontWeight: 300

strong = _.extend {}, base_text,
  fontWeight: 600

bullet = (props) ->
  DIV
    style:
      paddingLeft: 30
      position: "relative"
      margin: "30px 0"

    DIV
      style:
        position: "absolute"
        left: 0

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
      SPAN null, 
        props.body

SaasHomepage = ReactiveComponent
  displayName: "SaasHomepage"
  render: ->
    DIV null, title(), Videos(), usedFor(), pricing(), contact(), story()

title = ->
  chapter = fetch("video_chapter")

  DIV
    style:
      marginTop: 50
    H1
      style: _.extend {}, h1,
        textAlign: "center"
      "Think better together" 

    H3
      style: _.extend {}, h3,
        textAlign: "center"
      
      if chapter.text 
        chapter.text 
      else 
        "Sometimes a proposal bears careful thought"
      

Videos = ReactiveComponent
  displayName: "videos"
  render: ->
    

    DIV null,         

      STYLE
        type: "text/css"
        "#homepage_video video::cue { visibility: hidden; }"

      DIV
        id: "homepage_video"
        style:
          marginTop: 40
          width: 1000

        VIDEO
          preload: "auto"
          loop: true
          autoPlay: true
          width: 1000
          ref: "video"
          
          SOURCE
            src: asset("saas_landing_page/deathstar_cam.mp4")
            type: "video/mp4"
          
          SOURCE
            src: asset("saas_landing_page/deathstar_cam.webm")
            type: "video/webm"  
        

  componentDidMount: ->

    # we use timeupdate rather than tracks / cue changes / vtt
    # because browser implementations are not complete (and often buggy)
    # and polyfills poor. 
    v = @refs.video.getDOMNode()
    v.addEventListener 'timeupdate', (ev) -> 
      chapter = fetch("video_chapter")

      text = 
        if v.currentTime < 5
          "Sometimes a proposal bears careful thought"
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
          "Points ranked by salience across whole population"
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

      if chapter.text != text
        chapter.text = text
        save chapter
    , false


usedFor = ->
  DIV
    style:
      marginTop: 20
      marginBottom: 50
  , H3(
    style: _.extend({}, h3,
      marginTop: 30
      marginBottom: 10
    )
  , "Consider.it is good for…"), bullet(
    point_style: "bullet"
    strong: "Leading change. "
    body: "Leadership can communicate with their constituents/employees/customers to get feedback on issues, or respond to common points, addressing hundreds of individuals at once. Get the ship pointed in the same direction!"
  ), bullet(
    point_style: "bullet"
    strong: "Distributing decision making. "
    body: "Make decisions as a whole, without resorting to centralization. The will of a crowd, and the thoughts behind that will, become visible."
  ), bullet(
    point_style: "bullet"
    strong: "Teaching critical thinking. "
    body: "Students learn how to develop a considered opinion while engaging with other’s ideas; teachers achieve Common Core goals."
  ), H3(
    style: _.extend({}, h3,
      marginTop: 30
      marginBottom: 10
    )
  , "Consider.it focuses dialogue to create clarity in many minds"), bullet(
    point_style: "pro"
    strong: "Produces a summary overview of group thought "
    body: "that incorporates the unique opinion of each person. Patterns can be identified across all people. Perhaps 80% of opposers have a single con point that can be addressed!"
  ), bullet(
    point_style: "pro"
    strong: "Fosters considerate interactions "
    body: "by making it easy to consider all sides, find common ground, and work through sticking points. Personal attacks and trolling don’t make sense and can easily be identified."
  ), bullet(
    point_style: "pro"
    strong: "Scales to hundreds of people "
    body: "deliberating an issue together, without becoming overwhelming or requiring strong central leadership/facilitation."
  ), bullet(
    point_style: "con"
    strong: "Limited to proposals. "
    body: "Consider.it collects opinions on a “yesable” question, such as hypotheticals, proposals, ideas, or plans of action. Open ended questions like “How should we…” aren’t supported as well."
  ), bullet(
    point_style: "con"
    strong: "Mediocre mobile quality. "
    body: "The current design poorly translates to mobile, thus we cannot claim to be mobile optimized."
  )

pricing = ->

story = ->

contact = ->
  teamMember = undefined
  teamMember = (props) ->
    DIV
      style:
        display: "inline-block"
        margin: "20px 15px"
        textAlign: "center"
    , IMG(
      src: props.src
      style:
        borderRadius: "50%"
        display: "inline-block"
        width: 125
        textAlign: "center"
    ), DIV(
      style:
        textAlign: "center"
    , props.name), A(
      style:
        textAlign: "center"
        color: focus_blue
        textDecoration: "underline"
        fontWeight: 400
    , props.email)

  DIV null, DIV(null, teamMember(
    src: asset("saas_landing_page/mike.jpg")
    name: "Michael Toomim"
    email: "toomim@consider.it"
  ), teamMember(
    src: asset("saas_landing_page/kevin.jpg")
    name: "Kevin Miniter"
    email: "kevin@consider.it"
  ), teamMember(
    src: asset("saas_landing_page/travis.jpg")
    name: "Travis Kriplean"
    email: "travis@consider.it"
  )), H2(
    style: _.extend({}, h2)
  , "Get in touch with us"), DIV(null, "We would love to get to know you!"), DIV(null, "Write us a ", A(
    href: "mailto:admin@consider.it"
    style:
      color: logo_red
      textDecoration: "underline"
  , "nice electronic letter"), ". Or we can reach out to you:", FORM(
    action: "http://chalkboard.us7.list-manage1.com/subscribe/post?u=9cc354a37a52e695df7b580bd&amp;id=d4b6766b00"
    id: "mc-embedded-subscribe-form"
    method: "post"
    name: "mc-embedded-subscribe-form"
    novalidate: "true"
    target: "_blank"
    style:
      position: "relative"
      left: 50
      display: "inline-block"
      margin: "10px 0 30px 0"
  , INPUT(
    id: "mce-EMAIL"
    name: "EMAIL"
    placeholder: "Email address"
    type: "email"
    defaultValue: ""
    style:
      fontSize: 24
  ), BUTTON(
    name: "subscribe"
    type: "submit"
    style:
      fontSize: 24
      padding: "3px 5px"
      marginLeft: 8
      display: "inline-block"
  , "Send"))), DIV(null, "We work out of Seattle, WA, Portland, OR, and the Internet.")

Header = ReactiveComponent(
  displayName: "Header"
  render: ->
    current_user = undefined
    current_user = fetch("/current_user")
    DIV
      style:
        position: "relative"
        margin: "0 auto"
        backgroundColor: logo_red
        height: 52
    , IMG(
      src: asset("saas_landing_page/considerit_logo.svg")
      style:
        position: "relative"
        top: 8
        left: 12
    )
)
Page = ReactiveComponent(
  displayName: "Page"
  mixins: [ AccessControlled ]
  render: ->
    auth = undefined
    loc = undefined
    loc = fetch("location")
    auth = fetch("auth")
    DIV null, (->
      if auth.form
        Auth()
      else unless @accessGranted()
        SPAN null
      else
        switch loc.url
          when "/"
            SaasHomepage key: "homepage"
          when "/dashboard/create_subdomain"
            CreateSubdomain key: "/page/dashboard/create_subdomain"
    ).call(this)
)
Root = ReactiveComponent(
  displayName: "Root"
  render: ->
    loc = undefined
    loc = fetch("location")
    DIV
      style: base_text
    , BrowserLocation(), Header(), DIV(
      style:
        width: 1000
        backgroundColor: "white"
        margin: "auto"
        paddingBottom: 20
    , BrowserHacks(), Page(key: "/page" + loc.url), Tooltip())
)
window.Saas = Root

require './application_loader'
