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

window.

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
  fontSize: 42
  fontWeight: 800
  color: 'white'

window.h2 = _.extend {}, base_text,
  fontSize: 36
  fontWeight: 300

window.strong = _.extend {}, base_text,
  fontWeight: 600

window.a = _.extend {}, base_text,
  color: logo_red
  cursor: 'pointer'
  #textDecoration: 'underline'
  borderBottom: "1px solid #{logo_red}"

window.primary_color = -> c = fetch('colors'); c.primary_color

window.big_button = -> 
  backgroundColor: primary_color()
  boxShadow: "0 4px 0 0 black"
  fontWeight: 700
  color: 'white'
  padding: '8px 60px'
  display: 'inline-block'
  fontSize: 24
  border: 'none'
  borderRadius: 8


window.BIG_BUTTON = (text, opts) -> 
  opts.style ||= {}
  _.defaults opts.style, big_button()

  BUTTON 
    style: opts.style 
    onClick: opts.onClick
    onKeyPress: (e) -> 
      if e.which == 13 || e.which == 32 # ENTER or SPACE
        e.preventDefault()
        opts.onClick(e)

    text 


require './demo'
require './landing_page'
require './contact'
require './pricing'
require './customer_signup'
require './metrics'
require './tour'
require './testimonials'
require './header'
require './footer'

Proposals = ReactiveComponent
  displayName: 'Proposals'

  render: -> 
    users = fetch '/users'
    proposals = fetch '/proposals'
    subdomain = fetch '/subdomain'

    return SPAN null if !subdomain.name

    TagHomepage()




Page = ReactiveComponent

  displayName: "Page"
  mixins: [ AccessControlled ]

  render: ->
    loc = fetch 'location'    
    

    DIV   
      style: 
        backgroundColor: primary_color()        
        transition: 'background-color 500ms linear'
        minHeight: window.innerHeight

      if loc.query_params.play_demo
        Video
          playing: true 
      else 
        Header()

      switch loc.url 
        when '/proposals'
          Proposals()
        when '/metrics'
          Metrics()
        when '/'
          LandingPage()
        when '/tour'
          Tour()
        when '/pricing'
          Pricing()            
        when '/contact'
          Contact()
        when '/create_forum'
          CustomerSignup()
        when '/privacy_policy'
          PrivacyPolicy()
        when '/terms_of_service'
          TermsOfService()


      Footer()


Computer = ReactiveComponent
  displayName: 'Computer'

  render: -> 
    app = fetch '/application'
    doc = fetch 'document'

    title = 'Consider.it'
    if doc.title != title
      doc.title = title
      save doc

    if app.dev
      Development()
    else
      SPAN null

Colors = ReactiveComponent
  displayName: 'Colors'
  render: -> 
    loc = fetch 'location'
    colors = fetch 'colors'

    color = switch loc.url 
      when '/'
        logo_red #'#d65931' #'#B03F3A'
      when '/tour'
        '#EC3684'
      when '/pricing'
        '#6F3AB0'
      when '/contact'
        '#B03A88'
      when '/create_forum'
        '#77b03a'
        #'#414141'
      else 
        '#ddd'

    if colors.primary_color != color 
      colors.primary_color = color
      save colors 
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
    DIV null,
      BrowserLocation()
      StateDash()
      BrowserHacks()

      Page()

      Tooltip()
      Computer()
      Colors()


window.Saas = Root

require '../bootstrap_loader'
