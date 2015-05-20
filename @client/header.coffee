require './profile_menu'


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

          IMG 
            src: subdomain.branding.logo
            style: 
              height: 46

      if subdomain.branding.masthead_header_text
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
              subdomain.branding.masthead_header_text
          else
            subdomain.branding.masthead_header_text



