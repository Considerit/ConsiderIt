monitorinstitute_red = "#BE0712"

window.NonHomepageHeader = ReactiveComponent
  displayName: 'NonHomepageHeader'

  render: ->
    section_style = 
      padding: '8px 0'
      fontSize: 16



    DIV
      style:
        position: 'relative'
        width: BODY_WIDTH()
        paddingTop: 20
        margin: '0 auto 15px auto'


      back_to_homepage_button
        fontSize: 43
        position: 'absolute'
        marginRight: 30
        left: -60
        top: 3
          
      A 
        href: 'http://monitorinstitute.com/'
        target: '_blank'
        style: 
          display: 'inline-block'

        IMG 
          src: asset("monitorinstitute/logo.jpg")

      DIV 
        style: 
          position: 'absolute'
          right: -70
          top: 0
          width: 200
        ProfileMenu()

window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->
    section_style = 
      padding: '8px 0'
      fontSize: 16

    DIV
      style:
        position: 'relative'

      DIV 
        style: 
          width: CONTENT_WIDTH()
          margin: 'auto'
          paddingTop: 20
          position: 'relative'

        A 
          href: 'http://monitorinstitute.com/'
          target: '_blank'

          IMG 
            src: asset("monitorinstitute/logo.jpg")

        ProfileMenu()


        DIV 
          style: {}

          DIV 
            style:  
              color: monitorinstitute_red
              fontSize: 34
              marginTop: 40

            "The Monitor Institute intellectual agenda"

          DIV 
            style: 
              fontStyle: 'italic'
              marginBottom: 20
            'Spring 2015'

          DIV 
            style: 
              width: CONTENT_WIDTH() * .7
              borderRight: "1px solid #ddd"
              display: 'inline-block'
              paddingRight: 25

            P 
              style: section_style


              """
              Central to the Monitor Institute brand is the idea that we pursue 
              “next practice” in social impact. We do not simply master and teach 
              well‐established best practices, but treat those as table stakes and 
              focus our attention on the learning edges for the field. Our core 
              expertise is in helping social impact leaders and organizations 
              develop the skillsets they need to achieve greater progress than 
              in the past and prepare themselves for tomorrow’s context.
              """

            P 
              style: section_style

              """
              This document is a place for us to articulate two things: """
              SPAN
                style: 
                  fontStyle: 'italic'

                "what we believe"

              """ to be “next practice” today, and what """
              SPAN
                style: 
                  fontStyle: 'italic'

                "what we want to know"

              """ about how those practices can and will develop further. The former is our 
              point of view; the latter is the whitespace that is waiting to be 
              filled in over the coming three to five years.
              """





            P 
              style: section_style
              "It is designed to be used in a variety of ways:"

            UL
              style:
                listStylePosition: 'outside'
                paddingLeft: 30

              LI
                style: section_style
                """
                It is primarily a """

                SPAN
                  style: 
                    fontWeight: 600
                  "statement of strategy and vision"
                """. It does not contain 
                every next practice in the world, nor every important question to be 
                resolved, but only the ones that we believe are both (a) the most 
                transformative in the field of social impact and (b) those that we are 
                equipped and committed to working on. It must therefore be a living document, 
                revisited and revised often enough that it always reflects our most 
                up‐to‐date perspectives.
                """

              LI 
                style: section_style
                """
                Next, it is a """

                SPAN
                  style: 
                    fontWeight: 600
                  "rubric for making choices"

                """ that will keep us aligned and focused. 
                We will know we are doing well as a next‐practice consulting team when our 
                mix of commercial and eminence work promotes the points of view described 
                under """

                SPAN
                  style: 
                    fontStyle: 'italic'

                  "what we believe"

                " and helps us answer the questions listed under "

                SPAN
                  style: 
                    fontStyle: 'italic'

                  "what we want to know"

                """. When there is a question as to whether we should pursue an 
                opportunity that arrives or choose to focus resources in a given direction, 
                we can check our judgment by asking whether it will help us do either or both 
                of those things. That is equally true for scanning, for relationship‐building 
                and sales, for eminence projects, and for commercial work.
                """

          DIV 
            style: 
              display: 'inline-block'
              width: CONTENT_WIDTH() * .25
              verticalAlign: 'top'
              marginTop: 200
              paddingLeft: 25
              color: monitorinstitute_red
              fontWeight: 600

            """This is the intro to the draft intellectual agenda. Please provide 
               feedback on each proposed intellectual agenda item below."""
