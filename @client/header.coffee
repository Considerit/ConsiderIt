require './profile_menu'
require './customizations'


window.Header = ReactiveComponent
  displayName: 'Header'

  render : ->
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    DIV 
      style: 
        position: 'relative'
        zIndex: 2
        margin: '0 auto'
        backgroundColor: 'white'

      if fetch('location').url == '/'
        customization('HomepageHeader')()
      else 
        customization('NonHomepageHeader')()

      if fetch('location').url == '/about'
        DIV null, 
          A 
            href: '/'
            style: 
              position: 'absolute'
              display: 'inline-block'
              zIndex: 999
              marginTop: 8
              marginLeft: 16
              fontWeight: 600
            I className: 'fa fa-home', style: {fontSize: 28, color: '#bbb'}
            SPAN 
              style: 
                fontSize: 15
                paddingLeft: 6
                color: '#777'
                verticalAlign: 'text-bottom'
              'Home'

      DIV 
        style: 
          backgroundColor: '#eee'
          color: '#f00'
          padding: '5px 20px'
          display: if @root.server_error then 'block' else 'none'
        'Warning: there was a server error!'




window.DefaultHeader = ReactiveComponent
  displayName: 'DefaultHeader'

  render: -> 
    subdomain = fetch '/subdomain'   

    if subdomain.branding.masthead
      ImageHeader()
    else
      ShortHeader()

###########################
# A large header with an image background
window.ImageHeader = ReactiveComponent
  displayName: 'ImageHeader'

  render: ->
    subdomain = fetch '/subdomain'   

    masthead_style = 
      textAlign: 'center'
      backgroundColor: subdomain.branding.primary_color
      height: 45

    if subdomain.branding.masthead
      _.extend masthead_style, 
        height: 300
        backgroundPosition: 'center'
        backgroundSize: 'cover'
        backgroundImage: "url(#{subdomain.branding.masthead})"
    else 
      throw 'ImageHeader can\'t be used with a branding masthead'
           
    DIV style: masthead_style,
      ProfileMenu()

      # if subdomain.branding.masthead_header_text
      #   DIV style: {color: 'white', margin: 'auto', fontSize: 60, fontWeight: 700, position: 'relative', top: 50}, 
      #     if subdomain.external_project_url
      #       A href: "#{subdomain.external_project_url}", target: '_blank',
      #         subdomain.branding.masthead_header_text
      #     else
      #       subdomain.branding.masthead_header_text


############################
# A small header with text and optionally a logo
window.ShortHeader = ReactiveComponent
  displayName: 'ShortHeader'

  render: ->
    subdomain = fetch '/subdomain'   
    loc = fetch 'location'

    masthead_style = 
      backgroundColor: subdomain.branding.primary_color
      minHeight: 50

    rgb = parseColor(subdomain.branding.primary_color)
    hsl = rgb_to_hsl(rgb)
    is_light = hsl.l > .75

    DIV style: masthead_style,
      ProfileMenu()

      A
        href: '/'
        style: 
          display: 'inline-block'
          marginLeft: 50
          color: if !is_light then 'white'
          fontSize: 43
          visibility: if loc.url == '/' then 'hidden'
          verticalAlign: 'middle'

        '<'


      if subdomain.branding.logo
        A 
          href: if subdomain.external_project_url then subdomain.external_project_url
          style: 
            verticalAlign: 'middle'
            marginLeft: 35
            display: 'inline-block'
            fontSize: 0
            cursor: if !subdomain.external_project_url then 'default'

          IMG 
            src: subdomain.branding.logo
            style: 
              height: 46

      if subdomain.branding.masthead_header_text || subdomain.app_title
        text = subdomain.branding.masthead_header_text || subdomain.app_title
        SPAN 
          style: 
            color: if !is_light then 'white'
            marginLeft: 35
            fontSize: 32
            fontWeight: 400
            display: 'inline-block'
            verticalAlign: 'middle'

          if subdomain.external_project_url && !subdomain.branding.logo
            A 
              href: "#{subdomain.external_project_url}"
              target: '_blank'
              text
          else
            text



