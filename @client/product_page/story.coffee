require '../element_viewport_positioning'


window.Story = ReactiveComponent
  displayName: 'Story'

  render: -> 

    DIV 
      id: 'story'
      style: _.extend {}, base_text,
        width: SAAS_PAGE_WIDTH
        margin: '80px auto 20px auto'


      if @local.show_story
        [H1
          style: _.extend {}, h1, 
            marginBottom: 30

          "Our story"

        @truth() ]

      DIV 
        style: _.extend {}, h2, 
          width: TEXT_WIDTH
          backgroundColor: '#f6f7f9'
          textAlign: 'center'
          cursor: 'pointer'
          padding: '5px 0'
          margin: '40px auto 0 auto'
        onClick: =>
          @local.show_story = !@local.show_story
          save @local

          if @local.show_story
            $(@getDOMNode()).moveToTop(100, true)

        SPAN
          style: 
            borderBottom: '1px solid black'

          if @local.show_story
            "Hide our story"
          else
            "Still want more? Read our story"



    # DIV 
    #   id: 'story'
    #   style: _.extend {}, base_text,
    #     width: SAAS_PAGE_WIDTH
    #     margin: '60px auto 20px auto'
      

    #   H1
    #     style: _.extend {}, h1, 
    #       marginBottom: 30

    #     "Our story"

    #     if @local.picked_poison == 'fantasy'

    #       ', as Fantasy'

    #     else if @local.picked_poison == 'fact'
    #       ', just the Facts'

    #     if @local.picked_poison?
    #       BR null
    #       DIV
    #         style: 
    #           fontSize: 14

    #         "switch to "                  

    #         A
    #           style: 
    #             textDecoration: 'underline'
    #             color: logo_red

    #           onClick: => 
    #             @local.picked_poison = if @local.picked_poison == 'fact' then 'fantasy' else 'fact'
    #             save @local
    #           if @local.picked_poison == 'fact' then 'fantasy' else 'facts'




    #   if @local.picked_poison == 'fact'
    #     @truth()

    #   else if @local.picked_poison == 'fantasy'
    #     @fiction()

    #   else 
    #     DIV 
    #       style: _.extend {}, h2,
    #         textAlign: 'center'

    #       "Do you prefer "
    #       A
    #         style: 
    #           fontFamily: '"Courier New",Courier,"Lucida Sans Typewriter","Lucida Typewriter",monospace'
    #           textDecoration: 'underline'
    #           color: logo_red
    #         onClick: => 
    #           @local.picked_poison = 'fact'
    #           save @local

    #         "Fact"

    #       " or "

    #       A
    #         style: 
    #           fontFamily: 'Papyrus,fantasy'
    #           textDecoration: 'underline'
    #           color: logo_red
    #         onClick: => 
    #           @local.picked_poison = 'fantasy'
    #           save @local

    #         "Fantasy"
    #       "?"          

  fiction : -> 

    DIV null,

      DIV 
        style: _.extend {}, base_text,
          textAlign: 'center'
      

        "Coming soon: a fictional founding myth starring Benjamin Franklin."

  truth : ->
    caption_text =
      fontSize: 14
      fontWeight: 400   
      lineHeight: 1.4
      paddingTop: 5

    story_link = _.extend {}, a, small_text,
      textDecoration: 'none'
      borderBottom: "1px solid #{logo_red}"

    section_style = 
      marginBottom: 20
      paddingTop: 10

    DIV null,

      DIV
        style: section_style

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .6 - 40
            marginRight: 40
            verticalAlign: 'top'

          P 
            style: 
              paddingBottom: 15

            """
            The idea for Consider.it was born on a cloudy Seattle morning 
            while Travis sat on the ground outside of a """
            A 
              href: 'https://www.google.com/maps/place/Montlake+Bicycle+Shop/@47.639382,-122.302025,3a,75y,284.92h,78.85t/data=!3m4!1e1!3m2!1sqE4cgPSn9t_eCx1xr5HsEQ!2e0!4m2!3m1!1s0x549014c486e2f9c1:0x7b96d3f907c7f742'
              style: story_link
              'bike shop'

            """
            . He was feeling 
            down after spending a few dark hours reading hundreds of comments 
            on news articles about the Affordable Care Act. So much talking past 
            one another. Such wasted effort. 
            """

          P 
            style: 
              paddingBottom: 15

            """
            Humanity's ability to listen and learn is ever so fragile, easily broken 
            by poor habits and flawed tools. The problem is not limited to online 
            comment boards. Email threads involving close colleagues and even face 
            to face conversations with loved ones can easily degenerate. Travis 
            knew he was no exception to the problem; but that day, at least, Travis 
            was happy to turn his frustration into a blueprint for improvement.
            """

        DIV 
          style: 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .4
            marginTop: 10

          IMG
            style: 
              width: 400
              display: 'block'
              margin: 'auto'
            src: asset('product_page/child.png') 

          DIV
            style: caption_text

            """
            The Web is only 2.0 years old.  
            It's social. It's getting good at speaking. But it’s not yet very 
            good at listening.
            """



      DIV
        style: section_style

        DIV 
          style: 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .4
            marginTop: 10

          
          IFRAME
            width: 400
            height: 243
            src: "https://www.youtube.com/embed/jl1AsVM_8hk?modestbranding=1&showinfo=0&theme=dark&fs=1" 
            frameborder: "0" 
            allowfullscreen: true

          DIV
            style: caption_text

            'Travis\' Phd defense, from December 2011. Here is the full '
            A 
              style: _.extend {}, story_link, caption_text
              href: 'https://dl.dropboxusercontent.com/u/3403211/papers/dissertation.pdf'
              "dissertation"
            ' for those of you with great '
            SPAN 
              style: 
                textDecoration: 'line-through'
              'foolishness'
            ' fortitude.'           

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .6 - 40
            verticalAlign: 'top'
            marginLeft: 40


          """
          Travis was in a privileged position to spend time thinking about these 
          issues. He was pursuing a PhD in Computer Science at the University of 
          Washington, doing research grounded in the belief that we can 
          improve our capacity for collective action. He was supported by a generous 
          """
          A
            href: "http://www.nsf.gov/awardsearch/showAward?AWD_ID=0966929"
            style: story_link
            "National Science Foundation grant"
          ' he had written with his advisor '
          A
            style: story_link
            href: 'http://www.cs.washington.edu/people/faculty/borning'
            'Alan Borning'
          ' and political communication expert '
          A
            style: story_link
            href: 'http://www.com.washington.edu/bennett/'
            'Lance Bennett'

          '. Previously he had spent a couple of years researching how contributors to the 
          world\'s greatest deliberative project, Wikipedia, '
          A
            style: story_link
            href: 'http://dub.washington.edu/djangosite/media/papers/tmpZ77p1r.pdf'
            'collaborate together'
          ' and '
          A
            style: story_link
            href: 'http://www.aaai.org/Papers/ICWSM/2008/ICWSM08-011.pdf'
            'mediate'
          ' ' 
          A
            style: story_link
            href: 'https://www.cs.ubc.ca/~bestchai/papers/group07.pdf'
            'conflict'

          '. Travis was ready to channel this knowledge into invention.'



      DIV
        style: section_style

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .45 - 40
            marginRight: 40
            verticalAlign: 'top'

            

          P 
            style: 
              paddingBottom: 15

            """
            Travis found a kindred spirit in fellow graduate student Michael Toomim. 
            Michael's incisive and persistent feedback helped Travis transform his 
            abstract knowledge and ideas into concrete designs. They started collaborating 
            with each other on their respective projects. Bits and pieces of ideas 
            that Michael and Travis had kicked around before had suddenly coalesced in 
            that moment when Consider.it was born outside the bike shop. 
            """


        DIV 
          style: 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .55
            marginTop: 10
            position: 'relative'
            height: 380

          
          DIV 
            style: 
              width: 350

            IMG
              style: 
                width: 350
                display: 'block'
              src: asset('product_page/consult.png') 

            DIV
              style: caption_text

              'Late night collaboration!'

          DIV 
            style: 
              position: 'absolute'
              zIndex: 1
              width: 208
              top: 160
              left: 315

            IMG 
              src: asset('product_page/mike_talk.png')
              style: 
                width: 208

            DIV
              style: caption_text

              'Mike making a profound point that has been lost to time.'


      DIV 
        style: section_style

        DIV 
          style: 
            display: 'inline-block'
            verticalAlign: 'middle'
            width: SAAS_PAGE_WIDTH * .4
            marginTop: 10

          IMG 
            src: asset('product_page/sifp.jpg')
            width: 400


          DIV
            style: caption_text

            'Travis delivers the '
            A
              style: _.extend {}, story_link, caption_text
              href: 'https://www.youtube.com/watch?v=RIUD4Ty2ZAE'
              'winning talk'
            """ 
             at Social Innovation Fast Pitch. This excellent experience was an
            awkward transitionary point in our history: straddling academia and the 
            private sector, while representing our non-profit partner in a pitch 
            competition.
            """

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .6 - 40
            verticalAlign: 'top'
            marginLeft: 40

          P 
            style: 
              paddingBottom: 15

            'Consider.it debuted in 2010 as the engine behind the '
            A
              style: story_link
              href:'https://livingvotersguide.org'
              "Living Voters Guide"          
            
            ', in partnership with the civic non-profit '
            A 
              style: story_link
              href: 'http://seattlecityclub.org'

              'Seattle CityClub' 

            """
            . This election season dialogue creates a space for citizens to express 
            their opinions about difficult ballot initiatives and to hear and learn from 
            the opinions of their peers. The research team demonstrated 
            that the technology encouraged voters to listen to both sides, 
            recognize points by people with whom they disagree and change their opinion 
            based on something they read. The voters guide has now weathered five election cycles, with 
            """

            A
              style: story_link
              href: "http://blogs.seattletimes.com/monica-guzman/2012/10/27/seattle-library-fact-check-experiment-risky-but-valuable/"
              'on-demand fact-checking' 

            ' delivered by Seattle Public Librarians since 2012.'

          P 
            style: 
              paddingBottom: 15
            """
            Travis recognized that the technology had broad applicability 
            beyond civic engagement, and he generalized the technology.
            """


      DIV
        style: section_style

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .6 - 40
            marginRight: 40
            verticalAlign: 'top'

          P 
            style: 
              paddingBottom: 15

            """
            As Travis and Michael approached the end of their PhD programs, they 
            decided to leave academia. It had become 
            clear to Travis and Mike that academia's emphasis on prototyping, papers, 
            and peer review limited how far and in what manner ideas could be 
            brought into the world. Instead, they would create their own 
            company/laboratory that supported the form of inquiry they felt would 
            maximize their contributions. We call this organization The 
            Invisible College.
            """          

        DIV 
          style: 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .4
            verticalAlign: 'top'
            position: 'relative'



          IFRAME 
            src: "https://player.vimeo.com/video/12116723?portrait=0&byline=0&title=0" 
            width: 300
            height: 225 
            style: 
              display: 'block'


          DIV
            style: caption_text

            A 
              style: _.extend {}, story_link, caption_text
              href: 'http://engage.cs.washington.edu/reflect/'
              'Reflect'

            """
             is Consider.it’s sister project. Reflect promotes 
            active listening in comment forums. We deployed it in Slashdot 
            and Wikimedia’s strategic planning process. The project is inactive 
            currently, though it is still dear to our hearts. 
            """
            A
              style: _.extend {}, story_link, caption_text
              href: 'http://dub.washington.edu/djangosite/media/papers/tmptxCAiy.pdf'
              'Learn more'
            '.'

      DIV 
        style: section_style

        DIV 
          style: 
            display: 'inline-block'
            verticalAlign: 'middle'
            width: SAAS_PAGE_WIDTH * .4
            marginTop: 10

          IMG 
            src: asset('product_page/truth.png')
            width: 400


          DIV
            style: caption_text

            'Kevin standing up for Truth and Justice.'

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .6 - 40
            verticalAlign: 'top'
            marginLeft: 40

          P 
            style: 
              paddingBottom: 15

            """
            While wrapping up their academic pursuits, Mike and Travis 
            met Kevin Miniter. Kevin had just arrived in Seattle, eager for his next 
            adventure after running the campaign for the """
            A
              style: story_link
              href:'http://www.washingtonpost.com/wp-dyn/content/article/2011/02/02/AR2011020203272.html'
              "first openly gay presidential candidate"          

            '. The icy mornings in New Hampshire and the afternoons driving a sound 
            truck blasting reggaeton through '
            A 
              href: 'http://news.yahoo.com/blogs/ticket/ron-paul-topped-ran-fred-karger-puerto-rican-153210979.html'
              style: story_link
              'Puerto Rico' 
            """ had affirmed his love for 
            this country, but did little to cure his skepticism about its politics. 
            Kevin saw that there was a deeper problem of listening and critical 
            thinking behind our political strife. While trudging through the 
            startup world, he learned about Consider.it. He badgered Travis for 
            a meeting and asked the question that always starts an 
            adventure: "How can I help?"
            """
            

      DIV
        style: section_style

        DIV 
          style: _.extend {}, small_text, 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .6 - 40
            marginRight: 40
            verticalAlign: 'top'

          P 
            style: 
              paddingBottom: 15

            """
            And here we are now! 
            As a startup, we are exploring different markets beyond civic 
            engagement. We're using Consider.it to 
            align the opinions of employees during organizational change 
            efforts, where Consider.it's ability to surface knowledge and 
            identify sticking points across a large group of people can help
            the planning process. We're applying Consider.it to decision-making 
            and deliberation in decentralized online communities. Finally, 
            Consider.it's concentration on tradeoffs is a good fit for schools 
            teaching the new Common Core critical thinking skills."""
          P
            style: 
              paddingBottom: 15

            'Thanks for listening to our story. If you like our story 
            and believe in our vision, '
            A 
              href: 'mailto:admin@consider.it' 
              style: story_link
              'send us a message'
            '. Maybe we can collaborate! Or send us witty hate mail if you wish, we welcome adversaries.'


        DIV 
          style: 
            display: 'inline-block'
            width: SAAS_PAGE_WIDTH * .4
            verticalAlign: 'top'
            position: 'relative'

          IMG 
            src: asset('product_page/kev_mike.png')
            style: 
              width: 400
              position: 'relative'
              zIndex: 1

          DIV
            style: caption_text

            "Kevin and Mike in their natural habitat."

