
qs = []
TEXT_WIDTH = 730

window.FAQ = ReactiveComponent
  displayName: 'FAQ'

  render : -> 
    questions = qs
    if !@local.show_all_questions
      questions = questions.slice(0,4)

    DIV 
      id: 'faq'
      style:
        marginTop: 60


      H1
        style: _.extend {}, h1, 
          marginBottom: 30

        "Frequently Asked Questions"

      DIV 
        style: 
          postion: 'relative'

        for q in questions
          ExpandingQuestion q


      DIV 
        style: 
          width: TEXT_WIDTH
          backgroundColor: '#F7F7F7'
          textAlign: 'center'
          textDecoration: 'underline'
          cursor: 'pointer'
          padding: '5px 0'
          margin: 'auto'
        onClick: =>
          @local.show_all_questions = !@local.show_all_questions
          save @local

        if @local.show_all_questions
          "Collapse questions"
        else
          "Show more questions"


ExpandingQuestion = ReactiveComponent
  displayName: 'ExpandingQuestion'

  render : -> 
    DIV
      style:
        paddingLeft: 30
        position: "relative"
        margin: "30px auto"
        width: TEXT_WIDTH



      I
        className: "fa fa-chevron-#{if @local.active then 'down' else 'right'}"
        style: 
          fontSize: 30
          position: "absolute"
          left: -15
          top: 6
          color: logo_red
          cursor: 'pointer'

        onClick: => 
          @local.active = !@local.active
          save @local

      DIV
        style: _.extend {}, base_text, 
          fontWeight: if @local.active then 600
          cursor: 'pointer'
        onClick: => 
          @local.active = !@local.active
          save @local

        @props.question

      DIV 
        style: _.extend {}, small_text, 
          #fontWeight: 300
          display: if !@local.active then 'none'

        @props.answer()


p = 
  marginTop: 15

qs = [{
  question: 'What happens when I sign up for Consider.it?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Can I solicit responses to open ended questions like "Which policies should we revise?"'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can I moderate user content? Is it hard?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Can I create a private discussion and send out invitations?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Is it possible to set different permissions for who can, for example, post a new idea or write a new pro/con point?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Can I ask custom questions of users of my site?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can I style my Consider.it site so that it fits with my brand?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Does Consider.it work on mobile devices?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'What browsers do you support?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can we self-host Consider.it on our own servers?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can we use our own URL?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Is Consider.it open source? Can we use and modify the source code?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Consider.it is missing X feature that I need. What do can I do?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Do you support Single-Sign On (SSO)?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Do you integrate with X service?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }]




Collaborate = ReactiveComponent
  displayName: 'Collaborate'

  render: -> 

    DIV 
      id: 'collaborate'
      style:
        marginTop: 1
        backgroundColor: considerit_gray
        #color: 'white'
        padding: '30px 0'
        paddingBottom: 80
        position: 'relative'

      DIV 
        style: cssTriangle 'bottom', 'white', 133, 30,
          position: 'absolute'
          left: '50%'
          marginLeft: - 133 / 2
          top: 0

      DIV 
        style: 
          width: SAAS_PAGE_WIDTH()
          margin: 'auto'
          textAlign: 'center'           

        DIV 
          style: 
            position: 'relative'
            left: 9
            top: -4

          collaborationSVG
            height: 100
            fill_color: '#414141'


        DIV
          style: 
            textAlign: 'center'
            width: 570
            margin: 'auto'
            fontSize: 24
            marginTop: 10
            color: '#414141'

          "Have a different use in mind? Want to collaborate on a larger project? We'd love to "
          A
            href: '/contact'
            style: 
              textDecoration: "underline"
            'hear from you'
          "."

      DIV 
        style: cssTriangle 'bottom', considerit_gray, 133, 30,
          position: 'absolute'
          left: '50%'
          marginLeft: - 133 / 2
          bottom: -30      




use_style = 
  color: 'white'
  width: TEXT_WIDTH
  margin: 'auto'




demosList = (demos, label) -> 
  P 
    style:
      marginTop: 15

    "#{label}: "
    for demo, idx in demos

      [A
        href: demo[1]
        target: '_blank'
        style: 
          textDecoration: 'underline' 

        demo[0]
      if idx < demos.length - 1
        ', '
      ]

uses = [{
    icon: 'doc'
    label: 'Collect feedback'
    description: -> 
      
      demos = [
        ["Feedback on an event", 'https://event.consider.it/Morning_Gloryville?results=true'],
      ]

      examples = [
        ["Seattle Comprehensive Plan update", 'https://seattle2035.consider.it'],
      ]

      DIV 
        style: use_style
        """
        You have a plan, a policy, or an idea for a new product. 
        Or maybe you're evaluating a new program you helped implement. 
        Consider.it can help you efficiently collect the insights of 
        others, without having to sort through a long email thread or 
        responses to open-ended survey questions.
        """

        demosList(demos, 'Demo')
        demosList(examples, 'Example')


  }, {
    icon: 'review'
    label: "Make a choice"
    description: -> 
      DIV 
        style: use_style

        """
        Choosing the right vendor or product. Choosing the right office space for 
        your growing company. Choosing the right technology or person for 
        the job, or which grant applications to fund.
        """

        DIV 
          style: 
            marginTop: 8

          """      
          Consider.it helps 
          teams evaluate the options, applying their best thinking to 
          important decisions. 
          """
  }, {
    icon: 'survey'
    label: "Survey a group"
    description: -> 
      DIV 
        style: use_style

        """
        Consider.it combines attributes of surveys and focus groups. 
        Like a survey, it can tally what people believe about fixed 
        questions. Like a focus group, it can collect respondents' underlying 
        reasons and the reasons' influence across the respondents.
        """


        DIV 
          style: 
            marginTop: 8

          """Beyond surveys and focus groups, Consider.it outputs organized 
          open-ended data that is easier to visualize and code. But if 
          you require strict independence, then a traditional survey or 
          one-on-one interview is more appropriate.
          """

        # DIV 
        #   style: 
        #     marginTop: 8

        #   """
        #   Highlighted feature: Consider.it enables you to ask simple 
        #   questions of participants (like demographics) that can be used to 
        #   cross-tabulate the opinions gathered on your fixed questions.
        #   """

  }, {
    icon: 'converge'
    label: "Focus a dialogue"
    description: -> 
      examples = [
        ["Living Voters Guide", 'https://livingvotersguide.org'],
        ["Seattle Comprehensive Plan update", 'https://seattle2035.consider.it'],        
      ]

      DIV 
        style: use_style

        """
        Start a focused discussion about an interesting and/or contentious topic! 
        Consider.it provides a constructive environment for many people to 
        learn about an issue and share their opinion.
        The design minimizes personal attacks; and if they happen, our moderation 
        system puts you in a position to easily handle them.
        """
        demosList(examples, 'Examples')
  }, 
  {
    icon: 'meeting'
    label: 'Organize a meeting'
    description: -> 
      li_style =
        paddingTop: 10

      DIV 
        style: use_style

        """
        Consider.it can help make meetings more efficient:
        """
        UL 
          style: _.extend {}, small_text,
            paddingLeft: 40
            listStyle: 'outside'

          LI
            style: li_style

            SPAN 
              style: 
                fontWeight: 600

              "Before: "

            """The group can provide feedback on, or add to, 
            the agenda. The facilitator can then prepare a
            focused discussion on the unsettled areas."""

          LI
            style: li_style

            SPAN 
              style: 
                fontWeight: 600

              "During: "

            """Create visual straw polls to bring clarity 
            to a discussion. This can be especially powerful 
            for conference calls and virtual meetings."""

          LI 
            style: li_style
            SPAN 
              style: 
                fontWeight: 600

              "After: "

            """Summarize the meeting and make it available 
            for comment or wider circulation. Furthermore, groups can continue 
            unresolved conversations on Consider.it after a meeting, 
            potentially avoiding followup meetings.
            """
  }
]

applications = [{
    icon: 'crossroads'
    label: "Lead change"
    description: -> 
      examples = [
        ["SWOT analysis", 'https://swotconsultants.consider.it'],
      ]

      DIV 
        style: use_style

        """
        Engage employees, membership, and stakeholders about the future. 
        Strong leaders create change and build buy-in by explaining and 
        evolving plans, not imposing them. 
        """

        demosList(examples, 'Example')

  }, {
    icon: 'network'
    label: "Govern as a community"

    description: ->
      examples = [
        ["Bitcoin Consensus Census", 'https://bitcoin.consider.it']
      ]
      
      DIV
        style: use_style

        """
        Make decisions as a whole. The will of a community, 
        and the thoughts behind that will, become visible and actionable with Consider.it.
        """

        demosList(examples, 'Example')

  }, {
    icon: 'teaching'
    label: "Teach critical thinking"
    description: -> 
        demos = [
          ["literature discussion", 'https://schools.consider.it/Gatsby_Wedding?results=true'],
          ["historical debate", 'https://schools.consider.it/Atomic_Bombs?results=true'],
          ["civics / bioethics", 'https://schools.consider.it/Genetic_Testing?results=true']
        ]
        DIV 
          style: use_style
          """
          Consider.it makes students' thinking visible to themselves and other students. 
          Students can then reflect on the strength of their arguments, 
          engage and build on each other's ideas, and express a considered 
          opinion. Supports Common Core aligned exercises in English and Social Studies.
          """

          demosList(demos, 'Demos')

          # testimonial("Emma Peat", "Live Oak School", "product_page/emma_peat.jpg", """
          #   As an 8th grade humanities teacher, I spend a great deal of energy getting my 
          #   students to talk to each other. Each student has her/his own learning style 
          #   and comfort when it comes to sharing ideas, and I am always looking for new 
          #   ways for students to "talk." Consider.it is a flexible tool that can be 
          #   adapted in the classroom in many ways, including peer editing, looking at 
          #   issues from different perspectives, and answering big questions. It has been 
          #   an exciting addition to our classroom and I look forward to finding even 
          #   more ways of using it. """)

  }, {
    icon: 'public'
    label: "Engage citizens"
    description: -> 
      examples = [
        ["NASA Asteroid Initiative", 'https://ecastonline.consider.it'],
        ["Seattle Comprehensive Plan update", 'https://seattle2035.consider.it'],        
      ]

      DIV 
        style: use_style

        """
        Enable constituents to provide input on an upcoming decision. Consider.it 
        organizes this feedback into a guide to public thought that can be used 
        to refine the proposal or target common misconceptions during outreach. 
        """
        demosList(examples, 'Examples')

  },
]

for lst in [uses, applications]
  for use in lst
    require "./svgs/#{use.icon}"


window.Uses = -> 
  DIV
    id: 'uses'
    style:
      marginTop: 80
      backgroundColor: logo_red
      color: 'white'
      padding: '80px 0'
      position: 'relative'
      zIndex: 1

    DIV 
      style: cssTriangle 'bottom', 'white', 133, 30,
        position: 'absolute'
        left: '50%'
        marginLeft: - 133 / 2
        top: 0

    DIV 
      style: 
        width: SAAS_PAGE_WIDTH()
        margin: 'auto'

      H1 
        style: _.extend {}, h1,
          color: 'white'

        'What can Consider.it help you do better?'


      VisualTab
        tabs: uses
        stroke_color: 'white'
        stroke_width: 2        
        bg_color: logo_red
        icon_height: 110
        description_height: 286

        style: 
          width: 900
          margin: '40px auto 0 auto'

      H1 
        style: _.extend {}, h1,
          color: 'white'
          marginTop: 80

        '...which may support your efforts to:'


      VisualTab
        tabs: applications
        stroke_color: 'white'
        bg_color: logo_red
        icon_height: 110
        description_height: 220
        stroke_width: 2
        style: 
          margin: '40px auto 0 auto'
          width: 900

    DIV 
      style: cssTriangle 'bottom', logo_red, 133, 30,
        position: 'absolute'
        left: '50%'
        marginLeft: - 133 / 2
        bottom: -30


use = (props) -> 

  icon = 
    window["#{props.icon}SVG"]
      width: 200
      fill_color: 'white'
      style:
        verticalAlign: 'top'
        marginTop: 30



  DIV 
    style: 
      margin: "60px 80px 0 80px"

    if props.even 
      icon

    DIV 
      style: 
        width: 500
        display: 'inline-block'
        margin: '0 70px'
        verticalAlign: 'top'

      DIV 
        style: _.extend {}, h2,
          fontWeight: 700
          textAlign: 'left'

        props.strong

      DIV 
        style: light_base_text

        props.body()


    if !props.even
      icon


require '../element_viewport_positioning'


window.showStory = -> 
  story = fetch 'story'
  story.show_story = !story.show_story
  story.scroll_to = true
  save story
            

window.Story = ReactiveComponent
  displayName: 'Story'

  render: -> 
    story = fetch 'story'

    if story.show_story && story.scroll_to
      $(@getDOMNode()).moveToTop
        offset_buffer: 100
        scroll: true
      story.scroll_to = false
      save story

    DIV 
      id: 'about'
      style: _.extend {}, base_text,
        width: SAAS_PAGE_WIDTH()
        margin: '80px auto 20px auto'


      if story.show_story
        [H1
          style: _.extend {}, h1, 
            marginBottom: 30

          "Our story"

        @truth() ]

      DIV 
        style: _.extend {}, h2, 
          textAlign: 'center'

        SPAN
        
          onClick: showStory

          style: 
            borderBottom: '1px solid black'
            cursor: 'pointer'

          if story.show_story
            "Hide our story"
          else
            "Still want more? Read our story"



    # DIV 
    #   id: 'story'
    #   style: _.extend {}, base_text,
    #     width: SAAS_PAGE_WIDTH()
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
            width: SAAS_PAGE_WIDTH() * .6 - 40
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
            width: SAAS_PAGE_WIDTH() * .4
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
            width: SAAS_PAGE_WIDTH() * .4
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
            width: SAAS_PAGE_WIDTH() * .6 - 40
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
            width: SAAS_PAGE_WIDTH() * .45 - 40
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
            width: SAAS_PAGE_WIDTH() * .55
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
            width: SAAS_PAGE_WIDTH() * .4
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
            width: SAAS_PAGE_WIDTH() * .6 - 40
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
            width: SAAS_PAGE_WIDTH() * .6 - 40
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
            width: SAAS_PAGE_WIDTH() * .4
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
            width: SAAS_PAGE_WIDTH() * .4
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
            width: SAAS_PAGE_WIDTH() * .6 - 40
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
            width: SAAS_PAGE_WIDTH() * .6 - 40
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
            width: SAAS_PAGE_WIDTH() * .4
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


# props is:
#    tabs: [{icon, label, description}]
#    stroke_color
#    text_color
window.VisualTab = ReactiveComponent
  displayName: 'VisualTab'

  render : ->
    svg_padding = @props.svg_padding or '10px 20px'

    if !@local.selected
      @local.selected = @props.tabs[0].icon
      save @local

    bg_color = @props.bg_color or 'white'
    stroke_width = @props.stroke_width or 1

    select_tab = (tab) => 
      @local.selected = tab.icon
      save @local
    hover_tab = (tab) => 
      @local.hovering = tab.icon
      save @local

    DIV 
      style: @props.style
      UL 
        style: 
          listStyle: 'none'
          textAlign: 'center'

        for tab, idx in @props.tabs
          do (tab, idx) => 
            selected = @local.selected == tab.icon
            hovering = @local.hovering == tab.icon
            LI 
              key: idx
              style: 
                padding: svg_padding
                display: 'table-cell'
                opacity: if selected then 1.0 else if hovering then .6 else .25
                verticalAlign: 'top'
                cursor: 'pointer'
                position: 'relative'

              onMouseEnter : => hover_tab(tab)
              onMouseLeave : => @local.hovering = null; save @local
              onClick : => select_tab(tab)
              onTouchStart: => select_tab(tab)

              DIV 
                style: 
                  paddingBottom: 10
                  textAlign: 'center'

                window["#{tab.icon}SVG"]
                  height: @props.icon_height
                  fill_color: if selected || hovering then @props.stroke_color else 'black'

                if tab.label
                  DIV 
                    style: 
                      textAlign: 'center'
                      fontSize: 30
                      maxWidth: 180
                    tab.label

              if selected
                SVG 
                  height: 8
                  width: 30

                  style:
                    position: 'absolute'
                    left: '50%'
                    marginLeft: - 30 / 2
                    bottom: -stroke_width
                    zIndex: 1

                  POLYGON
                    points: "0,8 15,0 30,8" 
                    fill: @props.stroke_color

                  POLYGON
                    points: "0,#{8 + stroke_width} 15,#{stroke_width} 30,#{8 + stroke_width}" 
                    fill: bg_color






      DIV 
        style: _.extend {}, base_text, 
          minHeight: if @props.description_height then @props.description_height
          margin: '0px auto 40px auto'   
          paddingTop: 25
          borderTop: "#{stroke_width}px solid #{@props.stroke_color}"
          position: 'relative'


        for tab, idx in @props.tabs
          if @local.selected == tab.icon
            DIV 
              key: idx
              if _.isFunction(tab.description)
                tab.description()
              else 
                tab.description