require './shared'

window.Footer = ReactiveComponent
  displayName: 'Footer'

  render : ->
    FOOTER 
      style: 
        position: 'relative'
        zIndex: 0
      customization('SiteFooter')()



big_button = -> 
  backgroundColor: logo_red
  boxShadow: "0 4px 0 0 black"
  fontWeight: 700
  color: 'white'
  padding: '6px 60px'
  display: 'inline-block'
  fontSize: 24
  border: 'none'
  borderRadius: 12


window.DefaultFooter = ReactiveComponent
  displayName: 'Footer'
  render: ->
    subdomain = fetch '/subdomain'

    separator = SPAN 
      style: 
        padding: '0 6px'
        color: '#ccc'
      #dangerouslySetInnerHTML: { __html: "&bull;"}
      '|'

    DIV null,

      customization('footer_bonus')?()

      DIV 
        style: 
          paddingTop: 140
          backgroundColor: 'white'

      DIV 
        style:
          paddingTop: 80
          backgroundColor: "#F4F4F4"
          borderTop: "1px solid ##{737373}"
          
          padding: '45px 0 15px 0'
          position: 'relative'
          zIndex: 3

        DIV 
          style: 
            width: CONTENT_WIDTH()
            margin: 'auto'

          # buttons 

          DIV 
            style: 
              position: 'relative'
              margin: 'auto'
              textAlign: 'center'
              top: -70

            BUTTON 
              onClick: -> scrollTo 0, 0
              onKeyPress: (e) -> 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  e.preventDefault()
                  scrollTo 0, 0

              style: _.extend {}, big_button(), 
                backgroundColor: '#717171'

              'Back to top'


          DIV 
            style: 
              textAlign: 'center'

            TechnologyByConsiderit
              size: 26
            BR null
            A 
              href: 'https://consider.it'
              style: 
                display: 'inline-block'
                textDecoration: 'underline'
                fontSize: 14
                marginTop: 10
              'Create your own Consider.it forum'



          # more info

          DIV 
            style: 
              color: '#303030'
              fontSize: 11
              textAlign: 'center'
              marginTop: 20

            SPAN null, 

              DIV 
                style: 
                  display: 'inline-block'
                '© 2016 Consider.it. All rights reserved. '
                A
                  href: '/privacy_policy'
                  style: 
                    textDecoration: 'underline'
                  'Privacy'
                ' and '
                A
                  href: '/terms_of_service'
                  style: 
                    textDecoration: 'underline'
                  'Terms'
                '.'

              SPAN 
                style: 
                    marginLeft: 40
                    display: 'inline-block'

                  'Report bugs to '
  
                A 
                  style: 
                    textDecoration: 'underline'                    
                  href: 'mailto:hello@consider.it'
                  'help@consider.it'

              if !customization('google_translate_style') || fetch('location').url != '/'
                DIV 
                  style: 
                    marginLeft: 40
                    display: 'inline-block'            
                  GoogleTranslate()




require './logo'
window.TechnologyByConsiderit = ReactiveComponent
  displayName: 'TechnologyByConsiderit'
  render : -> 
    @props.size ||= 20
    DIV 
      style: 
        textAlign: 'left'
        display: 'inline-block'
        fontSize: @props.size
      "Technology by "
      A 
        onMouseEnter: => 
          @local.hover = true
          save @local
        onMouseLeave: => 
          @local.hover = false
          save @local
        href: 'http://consider.it'
        target: '_blank'
        title: 'Consider.it\'s homepage'
        style: 
          position: 'relative'
          top: 6
          left: 3
        
        drawLogo 
          height: @props.size + 5
          main_text_color: logo_red
          o_text_color: logo_red
          clip: false
          draw_line: true 
          line_color: logo_red
          i_dot_x: if @local.hover then 142 else null
          transition: true





