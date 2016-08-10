dao_blue = '#348AC7'
dao_red = '#F83E34'
dao_purple = '#7474BF'
dao_yellow = '#F8E71C'

window.HomepageHeader = ReactiveComponent 
  displayName: 'HomepageHeader'

  render: ->
    homepage = fetch('location').url == '/'

    DIV
      style:
        position: 'relative'
        background: "linear-gradient(-45deg, #{dao_purple}, #{dao_blue})"
        paddingBottom: if !homepage then 20
        borderBottom: "2px solid #{dao_yellow}"


      onMouseEnter: => @local.hover=true;  save(@local)
      onMouseLeave: => @local.hover=false; save(@local)




      STYLE null,
        '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
           p {margin-bottom: 1em}'''


      DIV 
        style: 
          marginLeft: 70


        back_to_homepage_button            
          display: 'inline-block'
          visibility: if fetch('location').url == '/' then 'hidden'
          color: 'white'
          opacity: .7
          position: 'relative'
          left: -60
          top: 4
          fontSize: 43
          fontWeight: 400
          paddingLeft: 25 # Make the clickable target bigger
          paddingRight: 25 # Make the clickable target bigger
          cursor: if fetch('location').url != '/' then 'pointer'

        # Logo
        A
          href: if homepage then 'https://forum.daohub.org/c/theDAO' else '/'


          IMG
            style:
              height: 30
              width: 30
              marginLeft: -44
              marginRight: 10
              marginTop: -10
              verticalAlign: 'middle'

            src: asset('ethereum/the_dao.jpg')

          SPAN 
            style:
              #fontFamily: "Montserrat, 'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"
              fontSize: 24
              color: 'white'
              fontWeight: 500

            "The DAO"


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
                padding: "0 8px"
                fontSize: 46
                fontWeight: 200
                color: 'white'
                marginTop: 20

              
              'Deliberate Proposals about The DAO'            


            DIV 
              style: 
                backgroundColor: 'rgba(255,255,255,.2)'
                marginTop: 10
                marginBottom: 16
                padding: '4px 12px'
                float: 'right'
                fontSize: 18
                color: 'white'

              SPAN 
                style: 
                  opacity: .8
                "join meta discussion on Slack at "

              A 
                href: 'https://thedao.slack.com/messages/consider_it/'
                target: '_blank'
                style: 
                  #textDecoration: 'underline'
                  color: dao_yellow
                  fontWeight: 600

                "#dao_consider_it"


            DIV 
              style: 
                clear: 'both'

            DIV 
              style: 
                float: 'right'
                fontSize: 12
                color: 'white'
                opacity: .9
                padding: '0px 10px'
                position: 'relative'

              "Donate ETH to fuel "

              A 
                href: 'https://dao.consider.it/donate_to_considerit?results=true'
                target: '_blank'
                style: 
                  textDecoration: 'underline'
                  fontWeight: 600

                "our work"

              " evolving consider.it to meet The DAO’s needs."


            DIV 
              style: 
                clear: 'both'

            DIV 
              style: 
                #backgroundColor: 'rgba(255,255,255,.2)'
                #marginBottom: 20
                padding: '0px 10px'
                float: 'right'
                fontSize: 15
                fontWeight: 500
                #color: 'white'
                color: dao_yellow
                #border: "1px solid #{dao_yellow}"
                opacity: .8
                fontFamily: '"Courier New",Courier,"Lucida Sans Typewriter","Lucida Typewriter",monospace'
              "0xc7e165ebdad9eeb8e5f5d94eef3e96ea9739fdb2"


            DIV 
              style: 
                clear: 'both'
                marginBottom: 70


            DIV 
              style: 
                position: 'relative'
                color: 'white'
                fontSize: 20

              DIV 
                style: 
                  position: 'relative'
                  left: 60
                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  SPAN style: opacity: .7,
                    'Ideas that inspire the community & contractors.'

                  BR null

                  A 
                    style: 
                      opacity: if !@local.hover_idea then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_yellow
                      border: "1px solid #{dao_yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_idea = true; save @local
                    onMouseLeave: => @local.hover_idea = null; save @local

                    href: '/proposal/new?category=Proposals'

                    t("add new")

                  SVG 
                    style: 
                      position: 'absolute'
                      top: 75
                      left: '35%'
                      opacity: .5

                    width: 67 * 1.05
                    height: 204 * 1.05
                    viewBox: "0 0 67 204" 

                    G                       
                      fill: 'none'

                      PATH
                        strokeWidth: 1 / 1.05 
                        stroke: 'white' 
                        d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

              DIV 
                style: 
                  position: 'relative'
                  left: 260
                  marginTop: 0 #30

                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  SPAN style: opacity: .7,
                    'Proposals working toward a smart contract.'
                  BR null

                  A 
                    style: 
                      opacity: if !@local.hover_new then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_yellow
                      border: "1px solid #{dao_yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_new = true; save @local
                    onMouseLeave: => @local.hover_new = null; save @local

                    href: '/proposal/new?category=New'

                    t("add new")

                  SVG 
                    style: 
                      position: 'absolute'
                      top: 75
                      left: '35%'
                      opacity: .5

                    width: 67 * .63
                    height: 204 * .63
                    viewBox: "0 0 67 204" 

                    G                       
                      fill: 'none'

                      PATH
                        strokeWidth: 1 / .63
                        stroke: 'white' 
                        d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

              DIV 
                style: 
                  position: 'relative'
                  left: 490
                  marginTop: 0 #30

                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  SPAN style: opacity: .7,
                    'Issues related to the operation of The DAO.'

                  BR null
                  A 
                    style: 
                      opacity: if !@local.hover_meta then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_yellow
                      border: "1px solid #{dao_yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_meta = true; save @local
                    onMouseLeave: => @local.hover_meta = null; save @local

                    href: '/proposal/new?category=Meta'

                    t("add new")

                  SVG 
                    style: 
                      position: 'absolute'
                      top: 75
                      left: '35%'
                      opacity: .5
                    width: 67 * .21
                    height: 204 * .21
                    viewBox: "0 0 67 204" 

                    G                       
                      fill: 'none'

                      PATH
                        strokeWidth: 1 / .21
                        stroke: 'white' 
                        d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"


              DIV 
                style: 
                  position: 'absolute'
                  left: 750
                  marginTop: 0 #30
                  bottom: -15

                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  # SPAN style: opacity: .7,
                  #   'Issues related to the operation of The DAO.'

                  BR null
                  A 
                    style: 
                      opacity: if !@local.hover_hack then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_yellow
                      border: "1px solid #{dao_yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_hack = true; save @local
                    onMouseLeave: => @local.hover_hack = null; save @local

                    href: '/proposal/new?category=Hack'

                    t("add new")

                  # SVG 
                  #   style: 
                  #     position: 'absolute'
                  #     top: 75
                  #     left: '35%'
                  #     opacity: .5
                  #   width: 67 * .21
                  #   height: 204 * .21
                  #   viewBox: "0 0 67 204" 

                  #   G                       
                  #     fill: 'none'

                  #     PATH
                  #       strokeWidth: 1 / .21
                  #       stroke: 'white' 
                  #       d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"






            if customization('cluster_filters')
              ClusterFilter()




      ProfileMenu()


window.NonHomepageHeader = window.HomepageHeader
