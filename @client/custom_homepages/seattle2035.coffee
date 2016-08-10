seattle2035_cream = "#FCFBE6"
seattle2035_pink = '#F06668'
seattle2035_dark = '#5C1517'

window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->

    header_style = 
      color: seattle2035_pink
      fontSize: 44
      #fontWeight: 600
      marginTop: 10

    section_style = 
      marginBottom: 20
      color: seattle2035_dark

    paragraph_heading_style = 
      display: 'block'
      #fontWeight: 600
      fontSize: 28
      color: seattle2035_pink

    paragraph_style = 
      fontSize: 18

    DIV
      style:
        position: 'relative'

      A 
        href: 'http://2035.seattle.gov/'
        target: '_blank'
        style: 
          display: 'block'
          position: 'absolute'
          top: 22
          left: 20
          color: seattle2035_pink

        I 
          className: 'fa fa-chevron-left'
          style: 
            display: 'inline-block'
            marginRight: 5

        '2035.seattle.gov'


      IMG
        style: 
          width: '100%'
          display: 'block'
          paddingTop: 50

        src: asset('seattle2035/banner.png')

      ProfileMenu()

      DIV 
        style: 
          borderTop: "5px solid #{seattle2035_pink}"
          padding: '20px 0'
          #marginTop: 50

        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            margin: 'auto'


          DIV 
            style: header_style

            'Let’s talk about how Seattle is changing'

          DIV 
            style: section_style

            # SPAN 
            #   style: paragraph_heading_style

            #   'Seattle is one of the fastest growing cities in America.'
            
            SPAN 
              style: paragraph_style
                
              """
              Seattle is one of the fastest growing cities in America, expecting to add 
              120,000 people and 115,000 jobs by 2035. We must plan for how 
              and where that growth occurs.
              """

          DIV 
            style: section_style


            SPAN 
              style: paragraph_heading_style
              'The Seattle 2035 draft plan addresses Seattle’s growth'
            
            SPAN 
              style: paragraph_style
              'We are pleased to present a '

              A 
                target: '_blank'
                href: 'http://2035.seattle.gov'
                style: 
                  textDecoration: 'underline'

                'Draft Plan'

              """
                 for public discussion. The Draft Plan contains hundreds of 
                policies that guide decisions about our city, including 
                Key Proposals for addressing growth and change. 
                These Key Proposals have emerged from conversations among 
                City agencies and through """
              A 
                target: '_blank'
                href: 'http://www.seattle.gov/dpd/cs/groups/pan/@pan/documents/web_informational/p2262500.pdf'
                style: 
                  textDecoration: 'underline'

                'public input' 
              '.'


          DIV 
            style: section_style

            SPAN 
              style: paragraph_heading_style
              'We need your feedback on the Key Proposals in the Draft Plan'

            SPAN 
              style: paragraph_style

              """
              We have listed below some Key Proposals in the draft.
              Do these Key Proposals make sense for Seattle over the coming twenty years? 
              Please tell us by adding your opinion below. Your input will influence 
              the Mayor’s Recommended Plan, 
              """
              A
                target: '_blank'
                href: 'http://2035.seattle.gov/about/faqs/#how-long'
                style: 
                  textDecoration: 'underline'
                'coming in 2016 '
              '!'

          DIV 
            style: 
              #fontStyle: 'italic'
              marginTop: 20
              fontSize: 18
              color: seattle2035_dark

            DIV 
              style: 
                marginBottom: 18
              "Thanks for your time,"

            A 
              href: 'http://www.seattle.gov/dpd/cityplanning/default.htm'
              target: '_blank'
              style: 
                display: 'block'
                marginBottom: 8

              IMG
                src: asset('seattle2035/DPD Logo.svg')
                style: 
                  height: 70


            DIV 
              style: _.extend {}, section_style,
                margin: 0
                marginTop: 10
                fontSize: 18

              'p.s. Email us at '
              A
                href: "mailto:2035@seattle.gov"
                style: 
                  textDecoration: 'underline'

                "2035@seattle.gov"
              """
               if you would like us to add another Key Proposal below for 
              discussion or you have a comment about another issue in the Draft Plan.
              """

            DIV 
              style: 
                marginTop: 40
                backgroundColor: seattle2035_pink
                color: 'white'
                fontSize: 28
                textAlign: 'center'
                padding: "30px 42px"

              "The comment period is now closed. Thank you for your input!"
