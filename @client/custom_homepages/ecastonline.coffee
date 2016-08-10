ecast_highlight_color =  "#73B3B9"  #"#CB7833"

window.NonHomepageHeader = ReactiveComponent
  displayName: 'NonHomepageHeader'

  render: ->
    DIV 
      style: 
        backgroundColor: 'black'
        width: '100%'
        position: 'relative'
        borderBottom: "2px solid #{ecast_highlight_color}"
        padding: "10px 0"
        backgroundImage: "url(#{asset('ecast/bg-small.png')})"
        height: 94

      A 
        href: "http://ecastonline.org/"
        target: '_blank'
        IMG 
          style: 
            height: 75
            position: 'absolute'
            left: 50
            top: 10

          src: asset('ecast/ecast-small.png')

      A 
        style: 
          fontSize: 30
          fontWeight: 600
          color: 'white'
          textShadow: '0 2px 4px rgba(0,0,0,.5)'       
          position: 'relative'
          top: 20
          left: 250 
        href: '/'
        "Informing NASA's Asteroid Initiative"

      DIV 
        style: 
          position: 'absolute'
          right: 0
          top: 14
          width: 110
        ProfileMenu()

window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render : ->
    paragraph_style = 
      marginBottom: 20
      textShadow: '0 1px 1px rgba(255,255,255,.5)'
      fontWeight: 600

    DIV 
      style: 
        backgroundColor: 'black'
        height: 685
        overflow: 'hidden'
        width: '100%'
        position: 'relative'
        borderBottom: "5px solid #{ecast_highlight_color}"

      IMG 
        style: 
          position: 'absolute'
          width: 1300
        src: asset('ecast/bg-small.png')

      # Title of site
      DIV 
        style: 
          position: 'absolute'
          left: 50
          top: 38

        DIV 
          style: 
            fontSize: 42
            fontWeight: 600
            color: 'white'
            textShadow: '0 2px 4px rgba(0,0,0,.5)'

          A 
            href: '/'
            "Informing NASA's Asteroid Initiative"

        DIV
          style: 
            fontSize: 24
            fontWeight: 600         
            color: 'white'
            textAlign: 'center'
            marginTop: -5

          A
            href: '/'
            "A Citizen Forum"

      # Credits
      DIV 
        style:
          position: 'absolute'
          top: 61
          left: 790

        DIV 
          style: 
            fontSize: 18
            color: 'white'
          'hosted by'

        A 
          href: "http://ecastonline.org/"
          target: '_blank'
          IMG 
            style: 
              display: 'block'
              marginTop: 4
              width: 215
            src: asset('ecast/ecast-small.png')

        # DIV 
        #   style: 
        #     fontSize: 18
        #     color: 'white'
        #     marginTop: 12              
        #   'supported by'

        # A 
        #   href: "http://www.nasa.gov/"
        #   target: '_blank'

        #   IMG 
        #     style: 
        #       display: 'block'
        #       marginTop: 4
        #       width: 160

        #     src: asset('ecast/nasa.png')

      # Video callout
      DIV
        style: 
          position: 'absolute'
          left: 434
          top: 609
          color: ecast_highlight_color
          fontSize: 17
          fontWeight: 600
          width: 325

        I 
          className: 'fa fa-film'
          style: 
            position: 'absolute'
            left: -27
            top: 3
        'Learn more first! Watch this video from the public forums that ECAST hosted.'

        SPAN
          style: 
            position: 'absolute'
            top: 24
            right: -15

          I
            className: 'fa fa-angle-right'
            style: 
              paddingLeft: 10
          I
            className: 'fa fa-angle-right'
            style: 
              paddingLeft: 5
          I
            className: 'fa fa-angle-right'
            style: 
              paddingLeft: 5


      # Video
      IFRAME
        position: 'absolute'
        type: "text/html" 
        width: 370
        height: 220
        src: "//www.youtube.com/embed/6yImAjIws9A?autoplay=0"
        frameborder: 0
        style:
          top: 460
          left: 790
          zIndex: 99
          position: 'absolute'
          border: "5px solid #{ecast_highlight_color}"
          borderBottom: 'none'


      # Text in bubble
      DIV 
        style: 
          fontSize: 17
          position: 'absolute'
          top: 156
          left: 97
          width: 600

        P style: paragraph_style, 
          """In its history, the Earth has been repeatedly struck by asteroids, 
             large chunks of rock from space that can cause considerable damage 
             in a collision. Can we—or should we—try to protect Earth from 
             potentially hazardous impacts?"""

        P style: paragraph_style, 
          """Sounds like stuff just for rocket scientists. But how would you like 
             to be part of this discussion?"""

        P style: paragraph_style, 
          """Now you can! NASA is collaborating with ECAST—Expert and Citizen 
             Assessment of Science and Technology—to give citizens a say in 
             decisions about the future of space exploration."""

        P style: paragraph_style, 
          """Join the dialogue below about detecting asteroids and mitigating their 
             potential impact. The five recommendations below emerged from ECAST 
             public forums held in Phoenix and Boston last November."""

        P style: paragraph_style, 
          """Please take a few moments to review the background materials and the 
             recommendations, and tell us what you think! Your input is important 
             as we analyze the outcomes of the forums and make our final report 
             to NASA."""

      DIV 
        style: 
          position: 'absolute'
          top: 30
          right: 0
          width: 110
        ProfileMenu()

styles += """
[subdomain="ecastonline"] .simplehomepage a.proposal, [subdomain="ecast-demo"] .simplehomepage a.proposal{
  border-color: #{ecast_highlight_color} !important;
  color: #{ecast_highlight_color} !important;
}
"""
