hala_teal = "#0FB09A"
hala_orange = '#FBAF3B'
hala_magenta = '#CB2A5C'
hala_gray = '#444'
hala_brown = '#A77C53'

window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->

    header_style = 
      color: hala_brown
      fontSize: 44
      #fontWeight: 600
      marginTop: 10

    section_style = 
      marginBottom: 20
      color: 'black'

    paragraph_heading_style = 
      display: 'block'
      fontWeight: 400
      fontSize: 28
      color: hala_brown

    paragraph_style = 
      fontSize: 18
      color: hala_gray
      paddingTop: 10
      display: 'block'

    DIV
      style:
        position: 'relative'

      A 
        href: 'http://seattle.gov/hala'
        target: '_blank'
        style: 
          display: 'block'
          position: 'absolute'
          top: 22
          left: 20
          color: "#0B4D92" #hala_magenta

        I 
          className: 'fa fa-chevron-left'
          style: 
            display: 'inline-block'
            marginRight: 5

        'seattle.gov/hala'


      IMG
        style: 
          width: '100%'
          display: 'block'
          #paddingTop: 20

        src: asset('hala/hala-header.png')


      ProfileMenu()

      DIV 
        style: 
          borderTop: "7px solid #{hala_teal}"
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
              “We are facing our worst housing affordability crisis in decades. My vision is a city where 
              people who work in Seattle can afford to live here…We all share a responsibility in making Seattle 
              affordable. Together, HALA will take us there.”
              """
              DIV  
                style: _.extend {}, paragraph_style, 
                  paddingLeft: '70%'
                "– Mayor Ed Murray"

          DIV 
            style: section_style


            SPAN 
              style: paragraph_heading_style
              """Your thoughts on the Housing Affordability and Livability Agenda (HALA) are key to securing quality, 
                 affordable housing for Seattle for many years to come."""
            
            SPAN 
              style: paragraph_style
              """HALA addresses Seattle's housing affordability crisis on many fronts. As we take proposals from idea 
                 to practice, we have been listening to the community to find out what matters to you. This online 
                 conversation reflects the diversity of ideas we've heard thus far and will continue 
                 to provide meaningful ideas on how to move forward."""


          DIV 
            style: section_style


            SPAN 
              style: paragraph_heading_style
              """Please add your opinion below"""
      
            SPAN 
              style: paragraph_style

              """
              We have listed many key recommendations below. This is an opportunity for you to shape the recommendations 
              before they are finalized. As the year progresses, we will be looking at other new programs, so check back often to weigh in on them. 
              The questions you see here are Phase 2 of this community conversation. Phase 1 questions that closed 
              recently can be found at the bottom of this page. We are also summarizing your feedback and posting it on """
              A 
                href: 'http://www.seattle.gov/hala/your-thoughts'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                'our website'

              '.'


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
              href: 'http://www.seattle.gov/dpd/cityplanning/default.htm'
              target: '_blank'
              style: 
                display: 'block'
                marginBottom: 8

              IMG
                src: asset('hala/Seattle-Logo-and-signature2.jpg')
                style: 
                  height: 70
                  opacity: .7


            DIV 
              style: _.extend {}, section_style,
                margin: 0
                marginTop: 10
                fontSize: 18
                color: hala_gray

              'p.s. Email us at '
              A
                href: "mailto:halainfo@seattle.gov"
                style: 
                  textDecoration: 'underline'

                "halainfo@seattle.gov"

              ' or visit our website at '
              A
                href: "http://seattle.gov/HALA"
                style: 
                  textDecoration: 'underline'

                "seattle.gov/HALA"                  
              ' if you want to know more.'


            # DIV 
            #   style: 
            #     marginTop: 40
            #     backgroundColor: hala_magenta
            #     color: 'white'
            #     fontSize: 28
            #     textAlign: 'center'
            #     padding: "30px 42px"

            #   "The comment period is now closed. Thank you for your input!"

