require './shared'

window.Footer = ReactiveComponent
  displayName: 'Footer'

  render : ->
    FOOTER 
      style: 
        position: 'relative'
        zIndex: 0
      customization('SiteFooter')()


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


    DIV
      style: 
        position: 'relative'
        padding: '2.5em 0 .5em 0'
        textAlign: 'center'
        zIndex: 0
        width: CONTENT_WIDTH()
        margin: 'auto'

      # A href: "#{subdomain.external_project_url}", target: '_blank', style: {display: 'inline-block', margin: 'auto'},
      #   if subdomain.branding.logo
      #     IMG src: "#{subdomain.branding.logo}", style: {width: 300}



      DIV 
        style: 
          marginTop: 30

        BUTTON 
          style: 
            color: logo_red
            cursor: 'pointer'
            borderRadius: '50%'
            display: 'inline-block'
            padding: 10
            textAlign: 'center'
            fontSize: 18
            backgroundColor: 'transparent'
            border: 'none'
            
          title: 'Back to top'
          onClick: -> scrollTo 0, 0

          'Back to top'
          I className: 'fa fa-angle-up', style: paddingLeft: 5

        BR null
        TechnologyByConsiderit
          size: 26


        DIV 
          style: 
            marginTop: 7
            maxHeight: if browser.is_mobile then 30
            color: '999'

          SPAN 
            style: 
              display: 'inline-block'
              marginBottom: 10

            A 
              style: 
                textDecoration: 'underline'
                color: logo_red              
              href: "mailto:admin@consider.it"

              'Talk to us'
              ' at admin@consider.it'

          separator

          SPAN 
            style: 
              display: 'inline-block'
              marginBottom: 10

            A 
              style: 
                textDecoration: 'underline'
                color: logo_red

              href: "https://consider.consider.it"

              'Report bugs or share ideas'

          separator

          SPAN 
            style: 
              display: 'inline-block'
              marginBottom: 10

            A 
              style: 
                textDecoration: 'underline'
                color: logo_red
              href: "https://consider.it"

              'Create your own consider.it project'




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
        
        drawLogo @props.size + 5, logo_red, logo_red, false, true, logo_red, (if @local.hover then 142 else null), true





