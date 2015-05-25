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
        margin: 'auto'
        marginLeft: if lefty then 20 + BODY_WIDTH / 2
        width: BODY_WIDTH
        zIndex: 0

      # A href: "#{subdomain.external_project_url}", target: '_blank', style: {display: 'inline-block', margin: 'auto'},
      #   if subdomain.branding.logo
      #     IMG src: "#{subdomain.branding.logo}", style: {width: 300}

      DIV style: {marginTop: 30},
        TechnologyByConsiderit()
        DIV style: {marginTop: 5},
          'Bug to report? Want to use this technology in your organization? '
          A style: {textDecoration: 'none', textDecoration: 'underline'}, href: "mailto:admin@consider.it", 'Email us'

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




