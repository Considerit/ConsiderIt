require './shared'

window.Footer = ReactiveComponent
  displayName: 'Footer'

  render : ->
    DIV 
      style: 
        position: 'relative'
        zIndex: 0
      customization('Footer')()


window.DefaultFooter = ReactiveComponent
  displayName: 'Footer'
  render: ->
    subdomain = fetch '/subdomain'
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

        DIV 
          style: 
            color: logo_red
            cursor: 'pointer'
            borderRadius: '50%'
            display: 'inline-block'
            padding: 10
            textAlign: 'center'
            fontSize: 18
          title: 'Back to top'
          onClick: -> scrollTo 0, 0

          'Back to top'
          I className: 'fa fa-angle-up', style: paddingLeft: 5

        BR null
        TechnologyByConsiderit()

        DIV 
          style: 
            marginTop: 7
            maxHeight: if browser.is_mobile then 30

          'Bug to report? Want to use this technology yourself? '
          A 
            style: 
              textDecoration: 'underline'
            href: "mailto:admin@consider.it"

            'Email us'
          ' at admin@consider.it'


require './logo'
window.TechnologyByConsiderit = ReactiveComponent
  displayName: 'TechnologyByConsiderit'
  render : -> 
    DIV 
      style: 
        textAlign: 'left'
        display: 'inline-block'
        fontSize: 20
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
        style: 
          position: 'relative'
          top: 6
          left: 3
        
        drawLogo 25, logo_red, logo_red, false, true, logo_red, (if @local.hover then 142 else null), true





