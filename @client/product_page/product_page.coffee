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
  fontSize: 42
  fontWeight: 700
  textAlign: 'center'
  margin: 'auto'

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

window.primary_color = -> c = fetch('colors'); c.primary_color

window.big_button = -> 
  backgroundColor: primary_color()
  boxShadow: "0 4px 0 0 black"
  fontWeight: 700
  color: 'white'
  padding: '6px 60px'
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


require './story'
require './faq'
require './demo'
require './landing_page'
require './contact'
require './pricing'
require './metrics'
require './tour'
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




Page = ReactiveComponent

  displayName: "Page"
  mixins: [ AccessControlled ]

  render: ->
    loc = fetch 'location'    

    DIV 
      style: 
        backgroundColor: primary_color()        
        transition: 'background-color 500ms linear'
        margin: 'auto'

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
          [
            Contact()
            Story()
          ]

      Footer()


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

Colors = ReactiveComponent
  displayName: 'Colors'
  render: -> 
    loc = fetch 'location'
    colors = fetch 'colors'

    switch loc.url 
      when '/'
        colors.primary_color = logo_red
      when '/tour'
        colors.primary_color = '#EC3684'
      when '/pricing'
        colors.primary_color = '#6F3AB0'
      when '/contact'
        colors.primary_color = '#B03A88'

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
