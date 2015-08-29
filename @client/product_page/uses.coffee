use_style = 
  color: 'white'
  width: TEXT_WIDTH
  margin: 'auto'

testimonial = (name, org, img, text) -> 

  DIV 
    style:
      position: 'relative'
      marginTop: 40

    IMG 
      src: asset(img)
      style: 
        width: 50
        borderRadius: '50%'
        position: 'absolute'
        left: -70
        top: 20


    DIV 
      style: 
        marginBottom: 10
        textDecoration: 'italics'
      "#{name}, #{org}"

    DIV
      style:
        backgroundColor: 'rgba(255,255,255,.2)'
        borderRadius: 16
        padding: '10px 20px'
      text



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
        ["Bitcoin Foundation", 'https://bitcoin.consider.it']
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
        width: SAAS_PAGE_WIDTH
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
