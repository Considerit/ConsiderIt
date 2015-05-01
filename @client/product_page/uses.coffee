require './svgs/public'
require './svgs/teaching'
require './svgs/crossroads'
require './svgs/network'
require './svgs/meeting'
require './svgs/doc'


p = 
  marginTop: 15

demosList = (demos, label) -> 
  P style: p,
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

uses = [
  {
    icon: 'doc'
    strong: 'Collect feedback'
    body: -> 
      """
      You have a draft proposal. Maybe it’s a plan, a policy, or an idea for
      a new product direction. Whatever it may be, Consider.it can help you 
      gather organized feedback from anyone you invite to participate. 
      Improve your proposal with the insights of others, without having to 
      sort through a long email chain. 
      """
  }, {
    icon: 'crossroads'
    strong: "Lead change"
    body: -> 
      """
      Engage employees, membership, and stakeholders about the future. 
      Strong leaders create change and build buy-in by explaining and 
      evolving plans, not imposing them. 
      """
  }, {
    icon: 'teaching'
    strong: "Teach critical thinking"
    body: -> 
        demos = [
          ["literature discussion", 'https://schools.consider.it/Gatsby_Wedding?results=true'],
          ["historical debate", 'https://schools.consider.it/Atomic_Bombs?results=true'],
          ["civics / bioethics", 'https://schools.consider.it/Genetic_Testing?results=true']
        ]
        DIV null,
          P style: p,
            """
            Students learn how to develop and express a considered opinion while listening 
            to and engaging with others' ideas. Supports Common Core aligned exercises 
            in English and Social Studies.
            """

          demosList(demos, 'Demos')


  }, {
    icon: 'network'
    strong: "Decentralize decision making"

    body: ->
      examples = [
        ["Bitcoin Foundation", 'https://bitcoin.consider.it']
      ]
      
      DIV null,
        P style: p,

          """
          Make decisions as a whole, without resorting to hierarchy. The will of a community, 
          and the thoughts behind that will, become visible and actionable with Consider.it.
          """
        demosList(examples, 'Example')

  }, {
    icon: 'public'
    strong: "Engage the public"
    body: -> 
      examples = [
        ["Living Voters Guide", 'https://livingvotersguide.org'],
        ["NASA Asteroid Initiative", 'https://ecastonline.consider.it']
      ]

      DIV null,
        P style: p,

          """
          Enable constituents to provide input on an upcoming decision. Consider.it 
          organizes this feedback into a guide to public thought that can be used 
          to refine the proposal or target common misconceptions during outreach. 
          """
        demosList(examples, 'Examples')

  }, {
    icon: 'meeting'
    strong: 'Conduct meetings'
    body: -> 
      """
      Plan more effective meetings by creating agendas on Consider.it. Thresh 
      through ideas before a meeting. After a meeting, use Consider.it to 
      close the loose ends!
      """
  }
]

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

      for u, idx in uses
        use _.extend {}, u, 
          even: idx % 2 == 0

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
