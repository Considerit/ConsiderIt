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

      DIV 
        style: use_style
        """
        You have a plan, a policy, or an idea for a new product direction. 
        Or maybe you're collecting feedback on a new program your organization 
        recently implemented. Consider.it can help you gather organized feedback 
        from anyone you invite to participate. Make improvements based on the 
        insights of others, without having to sort through a long email chain or 
        free-form survey responses.
        """

        demosList(demos, 'Demo')


  }, {
    icon: 'review'
    label: "Review Options"
    description: -> 
      DIV 
        style: use_style

        """
        Choosing the right vendor or product. Choosing the right office space to 
        move your growing company. Choosing the right person or technology for 
        the job, or which grant applications to fund. Consider.it helps 
        teams evaluate the options, putting their best thinking forward on 
        important decisions. 
        """
  }, {
    icon: 'survey'
    label: "Survey a group"
    description: -> 
      DIV 
        style: use_style

        """
        Consider.it collects and organizes both quantitative and qualitative 
        data -- what people think and why. It is like a survey and a focus group combined. 
        Furthermore, you can ask simple questions of participants that can be used to 
        cross-tabulate the opinions gathered on your main questions. Note that a 
        traditional survey is more appropriate if independent responses are required.
        """
  }, {
    icon: 'dialogue'
    label: "Host a dialogue"
    description: -> 
      examples = [
        ["Living Voters Guide", 'https://livingvotersguide.org'],
      ]

      DIV 
        style: use_style

        """
        Host a dialogue about an interesting and/or contentious topic! 
        Consider.it provides a constructive environment for many people to 
        learn about an issue and share their opinion.
        The design minimizes personal attacks, and if they happen, are easily 
        handled with our moderation system. 
        """
        demosList(examples, 'Example')
  }, 
]

applications = [{
    icon: 'crossroads'
    label: "Lead change"
    description: -> 
      DIV 
        style: use_style

        """
        Engage employees, membership, and stakeholders about the future. 
        Strong leaders create change and build buy-in by explaining and 
        evolving plans, not imposing them. 
        """
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
          Consider.it makes students' thinking visible to themselves and other students, 
          in a way that enables them to reflect on the strength of their arguments, 
          engage and build on each other's ideas, and express a considered 
          opinion. Supports Common Core aligned exercises in English and Social Studies.
          """

          demosList(demos, 'Demos')


  }, {
    icon: 'public'
    label: "Engage the public"
    description: -> 
      examples = [
        ["NASA Asteroid Initiative", 'https://ecastonline.consider.it']
      ]

      DIV 
        style: use_style

        """
        Enable constituents to provide input on an upcoming decision. Consider.it 
        organizes this feedback into a guide to public thought that can be used 
        to refine the proposal or target common misconceptions during outreach. 
        """
        demosList(examples, 'Example')

  },
  # {
  #   icon: 'meeting'
  #   strong: 'Conduct meetings'
  #   body: -> 
  #     """
  #     Plan more effective meetings by creating agendas on Consider.it. Thresh 
  #     through ideas before a meeting. After a meeting, use Consider.it to 
  #     close the loose ends!
  #     """
  # }
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

      # for u, idx in uses
      #   use _.extend {}, u, 
      #     even: idx % 2 == 0

      VisualTab
        tabs: uses
        stroke_color: 'white'
        stroke_width: 2        
        bg_color: logo_red
        icon_height: 120
        description_height: 280

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
        icon_height: 120
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
