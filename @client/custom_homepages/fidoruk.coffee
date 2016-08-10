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
        minHeight: 70

      ProfileMenu()


      DIV
        style: 
          width: (if homepage then HOMEPAGE_WIDTH() else BODY_WIDTH() ) + 130
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
              #marginLeft: 35
              display: 'inline-block'
              fontSize: 0
              cursor: if !subdomain.external_project_url then 'default'

            IMG 
              src: subdomain.branding.logo
              style: 
                height: 80

        DIV 
          style: 
            color: if !is_light then 'white'
            marginLeft: 35
            fontSize: 32
            fontWeight: 400
            display: 'inline-block'
            verticalAlign: 'middle'
            marginTop: 5

          if homepage 
            DIV
              style: 
                paddingBottom: 10
                fontSize: 16
                color: '#444'

              "Please first put your proposal into the Fidor Community platform, and link to it in your consider.it proposal.
              This allows us to converse, update our opinions, and track progress over a longer period of time."


window.NonHomepageHeader = HomepageHeader
