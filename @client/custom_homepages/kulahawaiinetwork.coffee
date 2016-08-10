window.HomepageHeader = ReactiveComponent 
  displayName: 'HomepageHeader'

  render: ->
    homepage = fetch('location').url == '/'
    height = if homepage then 300 else 120

    DIV
      style:
        position: 'relative'
        paddingBottom: if !homepage then 20
        height: height

      DIV 
        style: 
          height: height
          width: '100%'
          backgroundColor: 'black'
          position: 'absolute'
          zIndex: -1
        DIV 
          style: 
            height: height
            position: 'absolute'
            width: '100%'
            left: 0
            top: 0 
            zIndex: 0
            backgroundPosition: 'center'
            backgroundSize: 'cover'
            backgroundImage: "url(#{asset('hawaii/KulaHawaiiNetwork.jpg')})"
            backgroundColor: 'black'

            opacity: .6


      STYLE null,
        '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
           p {margin-bottom: 1em}'''


      DIV 
        style: 
          margin: 'auto'
          width: HOMEPAGE_WIDTH()
          position: 'relative'
          textAlign: 'center'


        back_to_homepage_button            
          display: 'inline-block'
          visibility: if fetch('location').url == '/' then 'hidden'
          color: 'white'
          opacity: .7
          position: 'absolute'
          left: -60
          top: 38
          fontSize: 43
          fontWeight: 400
          paddingLeft: 25 # Make the clickable target bigger
          paddingRight: 25 # Make the clickable target bigger
          cursor: if fetch('location').url != '/' then 'pointer'

        # Logo
        A 
          style: 
            cursor: 'none'
          # href: if homepage then 'https://forum.daohub.org/c/theDAO' else '/'


          # IMG
          #   style:
          #     height: 30
          #     width: 30
          #     marginLeft: -44
          #     marginRight: 10
          #     marginTop: -10
          #     verticalAlign: 'middle'

          #   src: asset('ethereum/the_dao.jpg')

          SPAN 
            style:
              #fontFamily: "Montserrat, 'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"
              fontSize: 47
              color: 'white'
              fontWeight: 200
              paddingTop: 40
              display: 'inline-block'
              opacity: .9

            "Envision the Kula Hawai’i Network"


      # The top bar with the logo
      DIV
        style:
          width: HOMEPAGE_WIDTH()
          margin: 'auto'

        if homepage

          DIV 
            style: 
              #paddingBottom: 50
              position: 'relative'
              

            DIV 
              style: 
                #backgroundColor: '#eee'
                # marginTop: 10
                # padding: "0 8px"
                fontSize: 22
                #fontWeight: 200
                color: 'white'
                marginTop: 0
                opacity: .7
                textAlign: 'center'

              
              'Please share your opinion. Click any proposal below to get started.'            

      if homepage && customization('cluster_filters')
        DIV 
          style: 
            position: 'relative'
            margin: '62px auto 0 auto'
            width: HOMEPAGE_WIDTH()

          ClusterFilter()

      ProfileMenu()


window.NonHomepageHeader = window.HomepageHeader

