window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->
    subdomain = fetch '/subdomain'

    DIV
      style:
        position: 'relative'

      IMG
        style: 
          width: '100%'
          display: 'block'

        src: subdomain.branding.masthead

      ProfileMenu()

      DIV 
        style: 
          padding: '20px 0'

        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            margin: 'auto'
