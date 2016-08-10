window.HomepageHeader = ReactiveComponent 
  displayName: 'HomepageHeader'

  render: ->
    homepage = fetch('location').url == '/'

    DIV
      style:
        position: 'relative'
        backgroundColor: 'white'
        paddingBottom: 20
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
          width: HOMEPAGE_WIDTH()
          margin: 'auto'

        DIV 
          style: 
            marginLeft: -70
            paddingTop: 30


          back_to_homepage_button              
            display: 'inline-block'
            visibility: if homepage then 'hidden'
            color: '#eee'
            position: 'relative'
            left: -60
            top: -10
            fontSize: 43
            fontWeight: 400
            paddingLeft: 25 # Make the clickable target bigger
            paddingRight: 25 # Make the clickable target bigger
            cursor: if not homepage then 'pointer'

          # Logo
          A
            href: if homepage then 'https://bitcoinclassic.com' else '/'


            IMG
              style:
                height: 51
                marginLeft: -50

              src: asset('bitcoin/bitcoinclassiclogo.png')

          BR null
          if homepage 

            SPAN
              style: 
                marginLeft: 69
                position: 'relative'
                marginTop: 5
                marginBottom: 10
                top: -4
                #backgroundColor: '#F69332'
                padding: '3px 6px'
                fontSize: 20
                fontStyle: 'italic'
                fontWeight: 700
                color: '#bbb'

              "Propose and deliberate ideas for Bitcoin Classic. Not yet for binding votes."


        if homepage
          DIV null, 
            DIV 
              style: 
                marginTop: 10
                padding: 8
                fontSize: 18

              "Classic is using consider.it to sample community opinion to better understand what users really 
               think about bitcoin and want to see it become. The governance model that Classic eventually 
               adopts may include opinions collected from this site, but Classic has not committed itself 
               to making decisions based only on the preferences expressed here or elsewhere."
              " "
              "Please vet proposals on "
              A 
                href: "https://www.reddit.com/r/Bitcoin_Classic/"
                target: '_blank'
                style: 
                  borderBottom: "1px solid #bbb"
                  #textDecoration: 'underline'

                "Reddit"
              " or "
              A 
                href: "http://invite.bitcoinclassic.com/"
                target: '_blank'
                style: 
                  borderBottom: "1px solid #bbb"
                  #textDecoration: 'underline'

                "Slack"
              " first. "

              "Other "               
              A 
                href: 'https://www.reddit.com/r/Bitcoin_Classic/comments/40u3ws/considerit_voting_guide/'
                target: '_blank'
                style: 
                  borderBottom: "1px solid #bbb"
                  #textDecoration: 'underline'

                "guidelines"
              "."
            DIV 
              style: 
                #backgroundColor: '#eee'
                marginTop: 10
                padding: 8
                fontSize: 18

              "Some users have abused open registration. Filtering opinions to verified users has been enabled by default."
              " "

            DIV 
              style: 
                backgroundColor: '#eee'
                marginTop: 10
                padding: 8
                fontSize: 18

              "Interested in running a node that mirrors consider.it data to provide an audit trail? "

              A 
                href: 'https://www.reddit.com/r/Bitcoin_Classic/comments/435gi1/distributed_publicly_auditable_data_for/'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                "Learn more"

      ProfileMenu()


window.NonHomepageHeader = HomepageHeader

