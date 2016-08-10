window.HomepageHeader = ReactiveComponent 
  displayName: 'HomepageHeader'

  render: ->
    homepage = fetch('location').url == '/'

    DIV
      style:
        position: 'relative'
        backgroundColor: '#272727'
        overflow: 'hidden'
        paddingBottom: 60
        height: if !homepage then 200
        # height: 63
        # borderBottom: '1px solid #ddd'
        # boxShadow: '0 1px 2px rgba(0,0,0,.1)'

      onMouseEnter: => @local.hover=true;  save(@local)
      onMouseLeave: => @local.hover=false; save(@local)

      STYLE null,
        '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
           p {margin-bottom: 1em}'''

      # The top bar with the logo
      DIV
        style:
          #width: HOMEPAGE_WIDTH()
          margin: 'auto'
          textAlign: 'center'

        DIV 
          style: 
            margin: "60px auto 160px auto"
            width: '80%'
            position: 'relative'
            zIndex: 3

          # IMG
          #   style: 
          #     position: 'absolute'
          #     left: '23%'
          #     top: '-16%'
          #     width: '7%'
          #   src: asset('bitcoin/blockchainLogo.png')

          IMG
            style: 
              display: 'inline-block'
              width: '90%'
            src: asset('bitcoin/OnChainConferences3.svg')


        DIV 
          style: 
            position: 'absolute'
            left: 0
            top: 0
            height: if homepage then '64%' else '100%'
            width: '100%'
            background: if homepage then 'linear-gradient(to bottom, rgba(0,0,0,.97) 0%,rgba(0,0,0,0.65) 70%,rgba(0,0,0,0) 100%)' else 'rgba(0,0,0,.7)'
            zIndex: 2

        IMG 
          style: 
            position: 'absolute'
            zIndex: 1
            width: '160%'
            top: 0 #45
            left: '-30%'
          src: asset('bitcoin/rays.png') 


        DIV 
          style: 
            marginLeft: 50
            paddingTop: 13
            position: 'absolute'
            zIndex: 3
            top: 65
            
          back_to_homepage_button
            display: 'inline-block'
            visibility: if homepage then 'hidden'
            color: 'white'
            position: 'relative'
            left: -60
            top: -10
            fontSize: 43
            fontWeight: 400
            paddingLeft: 25 # Make the clickable target bigger
            paddingRight: 25 # Make the clickable target bigger
            cursor: if not homepage then 'pointer'

        if homepage 
          DIV 
            style:
              backgroundColor: 'rgba(0,0,0,.7)'
              color: 'white'
              textAlign: 'center'
              padding: '20px 0'
              width: '100%'
              position: 'relative' 
              zIndex: 3
              top: 60

            DIV 
              style: 
                fontWeight: 600
                fontSize: 20

              'Visit '

              A 
                style: 
                  textDecoration: 'underline'
                href: 'http://onchainscaling.com/'

                'onchainscaling.com'
              ' to see the recorded presentations from the first conference.'

            DIV 
              style:
                fontSize: 18

              'Express your preferences below for future event presentations. '



        # DIV 
        #   style:
        #     fontSize: 24
        #     fontStyle: 'italic'
        #     fontWeight: 600
        #     display: 'inline-block'
        #     margin: 'auto'
        #   DIV 
        #     style: 
        #       color: '#A9556D'
        #     'You identify topics you want to learn more about.'
        #   DIV 
        #     style: 
        #       color: '#B1BC83'
        #     'We organize events that match speakers with topics.'

          # if homepage 


      ProfileMenu()


window.NonHomepageHeader = window.HomepageHeader
