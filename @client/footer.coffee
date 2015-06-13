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

      # A href: "#{subdomain.external_project_url}", target: '_blank', style: {display: 'inline-block', margin: 'auto'},
      #   if subdomain.branding.logo
      #     IMG src: "#{subdomain.branding.logo}", style: {width: 300}

      DIV 
        style: 
          marginTop: 30

        TechnologyByConsiderit()

        DIV 
          style: 
            marginTop: 5

          'Bug to report? Want to use this technology yourself? '
          A 
            style: 
              textDecoration: 'underline'
            href: "mailto:admin@consider.it"

            'Email us'
          ' at admin@consider.it'

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
        href: 'http://consider.it'
        style: 
          textDecoration: 'underline'
          color: logo_red
          fontWeight: 600, 
        target: '_blank'
        'Consider.it'




