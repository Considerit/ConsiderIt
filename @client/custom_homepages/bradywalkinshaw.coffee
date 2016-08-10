window.HomepageHeader = ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      loc = fetch 'location'
      homepage = loc.url == '/'

      DIV
        style:
          height: if homepage then 642 else 100
          margin: '0px auto'
          position: 'relative'
          overflow: 'hidden'
          backgroundColor: if !homepage then 'white'

        back_to_homepage_button
          fontSize: 43
          visibility: if homepage then 'hidden'
          verticalAlign: 'top'
          marginTop: 22
          marginRight: 15
          color: '#888'
          position: 'absolute'
          top: 10
          left: 10

        STYLE null,
          """
          header#main_header h1 {
            width: 230px;
            height: 130px;
            display: inline-block;
            margin-top: 16px;
            margin-bottom: 16px;
            margin-right: 12px;
            line-height: 1;
            font-family: 'futura-pt', 'Futura Std', Calibri, Verdana, sans-serif;
            }

          header#main_header h1 a {
            display: block;
            width: 100%;
            height: 100%;
            background-image: url(http://bradywalkinshaw.com/wp-content/themes/walkinshaw/images/logo_walk#{if !homepage then '_int' else ''}.png);
            background-size: contain;
            background-repeat: no-repeat;
            
            text-indent: -9999em;
            overflow: hidden;
            }


            header#main_header nav {
              vertical-align: top;
              display: inline-block;
              margin-top: 21px;
              }

            header#main_header nav ul {
              margin: 0;
              padding: 0;
              list-style: none;
              text-align: left;

              }

            header#main_header nav li {
              display: inline-block;
              position: relative;
              margin: 0 1px;
              text-transform: uppercase;
              font-size: 13.4px;
              font-weight: 900;
              }

            header#main_header nav li a {
              display: block;
              color: #{if homepage then '#fff' else '#777'};
              text-decoration: none;
              padding: 14px 19px;
              overflow: hidden;
              transition: .3s ease background, .3s ease color;
              }

            #hero {
              position: absolute;
              z-index: -1;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
              background-color: #f0f0f0;
              background-image: url(http://bradywalkinshaw.com/wp-content/uploads/2016/07/hero_walkinshaw_v2_r3.jpg);
              background-position: center 70%;
              background-size: cover;
              }
          
          """


        if homepage 
          DIV 
            id: "hero" 


        HEADER 
          id: "main_header" 

          DIV 
            style: 
              textAlign: 'center'

            H1 null, 
              A 
                href: "http://bradywalkinshaw.com"
                "Brady Piñero Walkinshaw"

            NAV 
              class: "topmenu"

              DIV null, 
                UL null, 
                  LI null, 
                    A href: "http://bradywalkinshaw.com/meet_brady/",
                      'Meet Brady'
                  LI null, 
                    A href: "http://bradywalkinshaw.com/endorsements/",
                      'Endorsements'
                  LI null, 
                    A href: "http://bradywalkinshaw.com/#issues/",
                      'Issues'
                  LI null, 
                    A href: "http://bradywalkinshaw.com/news/",
                      'News'
                  LI null, 
                    A href: "http://bradywalkinshaw.com/results/",
                      'Results'
                  LI null, 
                    A href: "http://bradywalkinshaw.com/resources/",
                      'Resources'
                  LI null, 
                    A 
                      href: "http://bradywalkinshaw.com/donate/"
                      style: 
                        backgroundColor: '#db282e'
                        color: 'white'

                      'Donate'



        DIV 
          style: 
            fontSize: 24
            backgroundColor: 'rgba(0,0,0,.5)'
            position: 'absolute'
            bottom: 0
            width: '100%'
            textAlign: 'center'
            display: if !homepage then 'none'

          DIV style: textAlign: 'center',
            DIV 
              style:
                fontSize: 36
                fontWeight: 600
                #textAlign: 'right'
                color: 'white'
                #marginTop: 140
                #display: 'inline-block'
                #backgroundColor: 'rgba(0,0,0,.3)'
                padding: '0 10px 10px 0'
                # borderRadius: 26
                # border: "1px solid rgba(0,0,0,.8)"
                position: 'relative'
                top: 10

              SPAN 
                style: 
                  color: '#7eef54'

                "Engage my platform. "
              
              SPAN 
                style: 
                  color: '#ffdd21'

                "I want to hear your opinion."


          ClusterFilter
            filter_style: 
              color: 'white'
              fontSize: 22


        DIV 
          style: 
            position: 'absolute'
            top: 18
            right: 0
            width: 110

          ProfileMenu()

window.NonHomepageHeader = customizations.bradywalkinshaw.HomepageHeader
