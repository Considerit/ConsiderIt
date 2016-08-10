engageseattle_teal = "#67B5B5"
hala_gray = '#666'


window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->

    header_style = 
      color: engageseattle_teal
      fontSize: 44
      #fontWeight: 600
      marginTop: 10

    section_style = 
      marginBottom: 20
      color: 'black'

    paragraph_heading_style = 
      display: 'block'
      fontWeight: 400
      fontSize: 31
      color: engageseattle_teal

    paragraph_style = 
      fontSize: 18
      color: hala_gray
      paddingTop: 10
      display: 'block'

    DIV
      style:
        position: 'relative'

      # A 
      #   href: 'http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement'
      #   target: '_blank'
      #   style: 
      #     display: 'block'
      #     position: 'absolute'
      #     top: 22
      #     left: 20
      #     color: "white"

      #   I 
      #     className: 'fa fa-chevron-left'
      #     style: 
      #       display: 'inline-block'
      #       marginRight: 5

      #   'seattle.gov/#AdvancingEquitySEA'


      IMG
        style: 
          width: '100%'
          display: 'block'
          #paddingTop: 20

        src: asset('engageseattle/engageseattle_header.png')


      ProfileMenu()

      DIV 
        style: 
          borderTop: "7px solid #{engageseattle_teal}"
          padding: '20px 0'
          #marginTop: 50

        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            margin: 'auto'


          # DIV 
          #   style: header_style

          #   'Let’s talk about housing affordability and livability'

          DIV 
            style: _.extend {}, section_style, 
              color: hala_gray
            
            DIV  
              style: _.extend {}, paragraph_style, 
                #fontSize: 22
                fontStyle: 'italic'
                margin: 'auto'
                padding: "40px 40px"
                
              """
              “How we reach out to residents to bring them into the governing process reflects the City’s 
               fundamental commitment to equity and to democracy. We’re constantly looking to bring down barriers, 
               to open up more opportunities, and to reflect the face of our diverse and growing city.”
              """
              DIV  
                style: _.extend {}, paragraph_style, 
                  paddingLeft: '70%'
                "– Mayor Ed Murray"

          DIV 
            style: section_style


            SPAN 
              style: paragraph_heading_style
              """Advancing Equitable Outreach and Engagement"""
            
            SPAN 
              style: paragraph_style
              """Mayor Murray recently issued an """

              A 
                href: 'http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                'Executive Order'

              """ directing the city to approach outreach and engagement in an equitable manner. 
              This directive to all City departments is based on a strong commitment to making 
              government more accessible, equitable and transparent."""


          DIV 
            style: section_style


            SPAN 
              style: paragraph_heading_style
              """Please add your opinion below"""
      
            SPAN 
              style: paragraph_style

              """We need to hear from YOU about your experiences and what we can provide to make it easier for you to weigh in."""

            SPAN 
              style: paragraph_style
              """At the heart of this """

              A 
                href: 'http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                'Executive Order'

              " is a commitment to advance the effective deployment of equitable and inclusive community engagement strategies across all city departments. This is about making information and opportunities for participation more accessible to communities throughout the city."

            SPAN 
              style: paragraph_style
              """We need to bring more people into the conversations and create more opportunities for people to participate and be heard. We are striving toward making things easier and less exhaustive. This is about connecting communities to government and to one another."""

            SPAN 
              style: paragraph_style
              """Your input will help guide this work moving forward.  In late-September the Mayor will propose legislation to the City Council advancing equitable outreach and engagement. Your input today will help shape this effort."""



          DIV 
            style: 
              #fontStyle: 'italic'
              marginTop: 20
              fontSize: 18
              #color: seattle2035_dark
              color: hala_gray
            DIV 
              style: 
                marginBottom: 18
              "Thanks for your time,"

            A 
              href: 'http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement'
              target: '_blank'
              style: 
                display: 'block'
                marginBottom: 8

              IMG
                src: asset('engageseattle/director_logo.png')
                style: 
                  height: 70
                  opacity: .9


            # DIV 
            #   style: _.extend {}, section_style,
            #     margin: 0
            #     marginTop: 10
            #     fontSize: 18
            #     color: hala_gray

            #   'p.s. Email us at '
            #   A
            #     href: "mailto:halainfo@seattle.gov"
            #     style: 
            #       textDecoration: 'underline'

            #     "halainfo@seattle.gov"

            #   ' or visit our website at '
            #   A
            #     href: "http://seattle.gov/HALA"
            #     style: 
            #       textDecoration: 'underline'

            #     "seattle.gov/HALA"                  
            #   ' if you want to know more.'


            # DIV 
            #   style: 
            #     marginTop: 40
            #     backgroundColor: hala_magenta
            #     color: 'white'
            #     fontSize: 28
            #     textAlign: 'center'
            #     padding: "30px 42px"

            #   "The comment period is now closed. Thank you for your input!"

