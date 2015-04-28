

uses = [
  {
    icon: 'doc'
    strong: 'Collect feedback'
    body: """
          You have a draft plan or policy. Or an idea for a new product direction, 
          architecture, or design. Consider.it can help you gather organized 
          feedback from anyone you invite to participate. Improve your idea 
          with the insights of others, without having to sort through a long 
          email chain.
          """
  }, {
    icon: 'crossroads'
    strong: "Lead change"
    body: """
          Engage employees, membership, and stakeholders about the future. 
          Strong leaders create change and build buy-in by explaining and 
          evolving plans, not imposing them. 
          """
  }, {
    icon: 'teaching'
    strong: "Teach critical thinking"
    body: """
          Students learn how to develop and express a considered opinion while listening 
          to and engaging with others' ideas. Supports Common Core aligned exercises 
          in English and Social Studies.
          """
  }, {
    icon: 'network'
    strong: "Decentralize decision making"
    body: """
          Make decisions as a whole, without resorting to hierarchy. The will of a community, 
          and the thoughts behind that will, become visible and actionable.
          """

  },{
    icon: 'public'
    strong: "Engage the public"
    body: """
          Make decisions as a whole, without resorting to hierarchy. The will of a community, 
          and the thoughts behind that will, become visible and actionable.
          """

  }, {
    icon: 'meeting'
    strong: 'Conduct meetings'
    body: """
          Plan more effective meetings by creating agendas on Consider.it. 
          And after a meeting, don’t set up a followup if you can just use 
          Consider.it to tie up the loose ends!
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

        'What can you do better with Consider.it?'

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
    IMG 
      src: asset("saas_landing_page/#{props.icon}.svg")
      width: 200
      verticalAlign: 'top'

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

        props.body


    if !props.even
      icon
