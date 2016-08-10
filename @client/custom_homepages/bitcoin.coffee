window.HomepageHeader = ReactiveComponent
  displayName: 'ShortHeader'

  render: ->
    subdomain = fetch '/subdomain'   
    loc = fetch 'location'

    hsl = parseCssHsl(subdomain.branding.primary_color)
    is_light = hsl.l > .75

    homepage = loc.url == '/'

    DIV 
      style:
        backgroundColor: subdomain.branding.primary_color
        minHeight: 70

      ProfileMenu()


      DIV
        style: 
          width: (if homepage then CONTENT_WIDTH() else BODY_WIDTH() ) + 130
          margin: 'auto'


        back_to_homepage_button
          display: 'inline-block'
          color: if !is_light then 'white'
          fontSize: 43
          visibility: if homepage || !customization('has_homepage') then 'hidden'
          verticalAlign: 'middle'
          marginTop: 5

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
                height: 56

        if subdomain.branding.masthead_header_text || (if !subdomain.branding.logo then subdomain.app_title else null)
          text = subdomain.branding.masthead_header_text || subdomain.app_title
          DIV 
            style: 
              color: if !is_light then 'white'
              marginLeft: 35
              fontSize: 32
              fontWeight: 400
              display: 'inline-block'
              verticalAlign: 'middle'
              marginTop: 5

            text

            DIV
              style: 
                paddingBottom: 10
                fontSize: 14
                color: '#444'

              "Interested in running a node that mirrors consider.it data to provide an audit trail? "

              A 
                href: 'https://www.reddit.com/r/Bitcoin_Classic/comments/435gi1/distributed_publicly_auditable_data_for/'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                "Learn more"
