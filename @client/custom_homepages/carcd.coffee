carcd_header = ReactiveComponent
  displayName: 'Carcd_header'

  render: -> 
    loc = fetch('location')

    homepage = loc.url == '/'

    DIV 
      style: 
        position: 'relative'
        width: HOMEPAGE_WIDTH()
        margin: 'auto'
        height: if !homepage then 180

      A
        href: 'http://carcd.consider.it'
        target: '_blank'
        style:
          position: 'absolute'
          top: 20
          left: -48 #(WINDOW_WIDTH() - 391) / 2
          zIndex: 5

        IMG
          src: asset('carcd/logo2.png')
          style:
            height: 145

      DIV
        style:
          # backgroundColor: "#F0F0F0"
          height: 82
          width: '100%'
          position: 'relative'
          top: 50
          left: 0
          #border: '1px solid #7D9DB5'
          #borderLeftColor: 'transparent'
          #borderRightColor: 'transparent'

        back_to_homepage_button 
          display: 'block'
          fontSize: 43
          visibility: if homepage then 'hidden'
          verticalAlign: 'top'
          left: -91
          top: 10
          color: 'black'
          position: 'relative'

      if homepage
        DIV 
          style: 
            paddingTop: 82
            width: HOMEPAGE_WIDTH()
            # paddingLeft: 70
            margin: 'auto'
            position: 'relative'

          DIV 
            style: 
              fontSize: 26
              fontWeight: 600
              # position: 'absolute'
              # top: -80
              color: '#746603'

            "We need your feedback!" 

          DIV 
            style: 
              fontSize: 20
              marginBottom: 18

            """This survey gives you a chance to influence the CARCD strategic plan and 
            our priorities for the next several years.  Please take the time to 
            respond to the questions below – elaborate, argue, tell us what you 
            really think!"""

          DIV 
            style: 
              fontSize: 20
              marginBottom: 6
            "Thank you for your time,"
            BR null
            "The CARCD team"



      # if homepage 
      #   DIV
      #     style:
      #       position: 'absolute'
      #       left: (WINDOW_WIDTH() + 8) / 2
      #       zIndex: 5
      #       top: 188
      #       paddingLeft: 12

      #     SPAN 
      #       style: 
      #         fontSize: 14
      #         fontWeight: 400
      #         color: '#7D9DB5'
      #         #fontVariant: 'small-caps'
      #         position: 'relative'
      #         top: -18
      #       'facilitated by'

      #     A 
      #       href: 'http://solidgroundconsulting.com'
      #       target: '_blank'
      #       style: 
      #         padding: '0 5px'

      #       IMG
      #         src: asset('carcd/solidground.png')
      #         style: 
      #           width: 103

      DIV 
        style: 
          position: 'absolute'
          top: 18
          right: 0
          width: 110

        ProfileMenu()



window.HomepageHeader = carcd_header
window.NonHomepageHeader = carcd_header

