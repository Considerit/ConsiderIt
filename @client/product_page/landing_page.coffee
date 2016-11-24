require './testimonials'

window.LandingPage = ReactiveComponent
  displayName: 'LandingPage'

  render: -> 

    DIV null, 
      Heading()

      Example 
        case: cases.seattle 

      Example 
        case: cases.wsffn 

      Example
        case: cases.dao 

      # UseCases()


Heading = -> 
  compact = browser.is_mobile || SAAS_PAGE_WIDTH() < 970

  DIV 
    style: 
      position: 'relative'
      paddingBottom: 120

    DIV 
      style: 
        paddingTop: 40
        width: SAAS_PAGE_WIDTH()
        margin: 'auto'
        textAlign: 'left'


      H1
        style: 
          fontSize: if compact then 44 else 60
          fontWeight: 500
          color: '#303030'
          lineHeight: 1.1

        dangerouslySetInnerHTML: {__html: "A web forum that elevates your#{if !compact then '<br/>' else ''}community's opinions."}

      DIV 
        style: 
          fontSize: 18
          color: '#303030'
          marginTop: 28
          marginBottom: 40
          fontWeight: 500

        dangerouslySetInnerHTML: {__html: "Civil and organized discussion even when hundreds of stakeholders participate"}


      A 
        href: '/create_forum'
        style: _.extend {}, big_button(), 
          backgroundColor: seattle_salmon

        'Start your own Forum'

    if !compact 
      IMG 
        style: 
          position: 'absolute'
          right: 0
          bottom: -20
          width: '60%'
          zIndex: 10
        src: asset 'product_page/skyline.png'



Example = ReactiveComponent
  displayName: 'Example'

  render: -> 
    ex = @props.case
    compact = browser.is_mobile || SAAS_PAGE_WIDTH() < 970

    DIV 
      style: 
        position: 'relative'
        marginBottom: 80
        background: ex.background

      A name: ex.id 

      DIV 
        style: 
          width: SAAS_PAGE_WIDTH()
          margin: 'auto'
          position: 'relative'
          zIndex: 1
          paddingTop: 24

        DIV   
          style: 
            fontStyle: 'italic'
            fontSize: 22
            color: 'white'
            paddingBottom: 12
          ex.example_text

        H2 
          style: 
            fontSize: if compact then 36 else 50
            fontWeight: 800
            color: 'white'
            paddingBottom: 40
            textShadow: '0px 2px 4px rgba(0,0,0,.2)'

          ex.heading 


        DIV 
          style: css.crossbrowserify
            display: 'flex'
            flexDirection: if compact then 'column'

          DIV 
            style: 
              flex: 0
              paddingTop: 24
              
              color: 'white'

            for m in ex.metrics
              DIV 
                style: 
                  textAlign: 'center'
                  marginBottom: 36
                  display: if compact then 'inline-block'
                  paddingRight: if compact then 40


                DIV 
                  style: 
                    fontSize: 36
                    lineHeight: 1
                    fontWeight: 600

                  m.quantity

                DIV 
                  style: 
                    fontSize: 14
                    fontWeight: 500
                    whiteSpace: 'nowrap'
                  m.metric



          DIV 
            style: 
              flex: 1
              marginLeft: if !compact then 60
              width: SAAS_PAGE_WIDTH() - (if compact then 0 else 60 + 120)

            DIV 
              style: 
                marginTop: 0

              A 
                href: ex.browser_loc
                target: '_blank'

                ex.screen SAAS_PAGE_WIDTH() - (if compact then 0 else 60 + 120)



        DIV 
          style: 
            paddingTop: 36

          if @local.expanded
            DIV 
              style: 
                backgroundColor: 'white'
                boxShadow: '0 1px 2px rgba(0,0,0,.2)'
                padding: '20px 40px'

              H3
                style: 
                  fontSize: 36
                  fontWeight: 400
                  paddingBottom: 36
                ex.extra_heading

              DIV 
                style: css.crossbrowserify
                  display: 'flex'

                DIV
                  style: 
                    flex: 1
                    maxWidth: 600
                    paddingRight: 40

                  DIV 
                    className: 'embedded' 
                    dangerouslySetInnerHTML: {__html: ex.story}

                  DIV 
                    style: 
                      marginTop: 20
                      marginBottom: 60

                    "Explore at"

                    if ex.links.length == 1
                      [
                        ' '
                        A
                          href: ex.links[0]
                          target: '_blank'
                          style: 
                            textDecoration: 'underline'

                          ex.links[0]

                        if ex == cases.wsffn
                          DIV 
                            style: 
                              fontStyle: 'italic'
                            '(their board-only forum is private)'
                      ]
                    else 
                      [':'
                      UL 
                        style: 
                          listStyle: 'none'
                        for link in ex.links
                          LI 
                            style: {}

                            A
                              href: link
                              target: '_blank'
                              style: 
                                textDecoration: 'underline'
                                color: '#007BC6'
                                fontWeight: 500

                              link                    
                      ]

                  DIV 
                    style: 
                      marginTop: 20

                    A 
                      href: '/create_forum'
                      style: _.extend {}, big_button(), 
                        backgroundColor: null 
                        background: ex.background
                        padding: '8px 24px'
                        marginRight: 20     
                        fontSize: 18
                        fontWeight: 600
                        marginBottom: 8

                      'Start your own Forum'

                    A 
                      href: '/contact?form=request_demo'
                      style: _.extend {}, big_button(), 
                        backgroundColor: '#eee'
                        color: '#303030'
                        boxShadow: '0 4px 0 0 rgb(50,50,50)'
                        padding: '8px 24px'
                        fontSize: 18
                        fontWeight: 600
                        marginBottom: 8
                      'Request a demo'

                DIV 
                  style: 
                    flex: 1
                    position: 'relative'
                    top: -32

                  TestimonialGrid
                    testimonials: [ex.testimonial]
                    top: true 
                    italic: true
                    hide_full: true




      @additional_options()

  additional_options: -> 
    ex = @props.case

    click = => 
      @local.expanded = !@local.expanded; save @local
      document.activeElement.blur()

    DIV 
      width: '100%'

      BUTTON 
        style: 
          backgroundColor: 'rgba(0,0,0,.1)' 
          border: 'none'
          width: '100%'
          padding: 20
          #textDecoration: 'underline'
          fontSize: 42
          marginTop: 24
          display: 'block'
          textAlign: 'center'
          color: 'white'
          fontWeight: 700


        onClick: click
        onKeyPress: (e) -> 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            e.preventDefault()
            click()
        

        "Learn #{if @local.expanded then 'less' else 'more'}#{if ex.more_callout then ' ' + ex.more_callout else ''}"



cases = {}

cases.seattle = 
  id: 'seattle'
  background: seattle_salmon
  heading: 'City of Seattle uses Consider.it to transform public controversy into productive dialogue'
  example_text: 'Public Engagement example:'
  browser_loc: 'https://seattle2035.consider.it/Housing'

  screen: (width) ->       
    Webframe 
      browser_loc: cases.seattle.browser_loc
      width: width

      DIV 
        style: 
          width: '90%'
          margin: 'auto'
        DIV 
          style: 
            fontSize: 36
            fontWeight: 500
            margin: '30px 0 0px 0'
            textAlign: 'center'

          'Increase the diversity of housing types in lower density residential zones'

        IMG 
          src: asset 'product_page/seattle_example.png'
          style:
            width: '100%'

  metrics: [
    {
      quantity: '8,000+'
      metric: 'opinions given'
    }
    {
      quantity: '1,500+'
      metric: 'comments'
    }
    {
      quantity: '0'
      metric: 'personal attacks'
    }


  ]

  more_callout: 'about Seattle cases'

  extra_heading: 'Organized, civil public dialogue on contentious issues.'
  story: """<p>Seattle is booming. Affordable housing is vanishing.</p>
            <p>Seattle Mayor Ed Murray launched an <a href='http://hala.seattle.gov'>ambitious plan</a> to dramatically increase the supply of affordable housing.</p>
            <p>Consider.it is helping the City of Seattle engage local residents in developing the plan. Every resident has the opportunity to provide feedback on how the plan will impact them.</p>
            <p>The structure of the Consider.it forum has encouraged civil dialogue. Neighbors are learning from each other. Neighbors are participating in building a better city. The feedback City staff receive is higher quality than other online sources, and many public meetings.</p>"""
  links: ['https://hala.consider.it', 'https://seattle2035.consider.it', 'https://engageseattle.consider.it']
  testimonial: testimonials.susie



cases.wsffn = 
  id: 'wsffn'
  background: 'linear-gradient(143deg, #9BA43D 0%, #7D8928 100%)'
  heading: 'Statewide farming non-profit made strategic plan for ~15% the cost of a traditional process'
  example_text: 'Strategic Planning example:'
  browser_loc: 'https://wsffn.consider.it'

  screen: (width) ->       
    Webframe 
      browser_loc: cases.wsffn.browser_loc
      width: width
      DIV 
        style: 
          width: '90%'
          margin: 'auto'

        IMG 
          src: asset 'product_page/wsffn_example.png'
          style:
            width: '100%'

  metrics: [
    {
      quantity: '40'
      metric: 'stakeholders'
    }
    {
      quantity: '267'
      metric: 'miles apart'
    }
    {
      quantity: '1'
      metric: 'adopted plan'
    }


  ]

  more_callout: 'about this case'

  extra_heading: 'Lightweight strategic planning on a tight budget.'
  story: """
        <p>Russ Lehman had a problem. He had just been hired as the new executive director of the Washington Sustainable Food and Farming Network. Let’s be honest, the organization needs a new name. But before changing the name, he needed a new strategic plan…and to engage his members across the state.</p>
        <p>Russ worked with Consider.it to set up a Consider.it forum. He gathered feedback on the core points of the new plan. Then he set up a private Consider.it forum for the board to discuss the plan. The board refined the plan and voted to adopt it. Now they are using Consider.it to identify a new organization name.</p>
        <p><b>Total cost</b>: $1.2k for a Consider.it <a href="/pricing">Unlimited Forum</a>, plus $5k for <a href="/pricing#consulting">additional consulting</a>.</p>
        """
  links: ['https://wsffn.consider.it']
  testimonial: testimonials.russ



cases.dao = 
  id: 'dao'
  background: 'linear-gradient(141deg, #348AC7 0%, #7474BF 100%)'
  heading: 'Worldwide decentralized organization deliberated how to spend $150m'
  example_text: 'Distributed Community example:'

  browser_loc: 'https://dao.consider.it/temporary-moratorium-on-the-dao-security-issues'
  screen: (width) ->       
    Webframe 
      browser_loc: cases.dao.browser_loc
      width: width 

      DIV 
        style: 
          width: '90%'
          margin: 'auto'

        DIV 
          style: 
            fontSize: 36
            fontWeight: 500
            margin: '30px 0 20px 0'
            textAlign: 'center'

          'Temporary moratorium for security audit'

        IMG 
          src: asset 'product_page/dao_example.png'
          style:
            width: '100%'

  metrics: [
    {
      quantity: '10,000+'
      metric: 'opinions given'
    }
    {
      quantity: '1,500+'
      metric: 'participants'
    }
    {
      quantity: '400+'
      metric: 'ideas deliberated'
    }


  ]

  more_callout: 'about this case'

  extra_heading: 'Visible opinions help your community find common ground for action.'
  story: """<p>The DAO was a prominent attempt to create a decentralized cooperative organization existing entirely on the internet, setting records in raising $150m of crowd-funding from thousands of individuals.</p> 
        <p>The DAO had many challenges to overcome as an unprecedented social experiment. The community adopted Consider.it to help address one of these problems: aggregating and gauging community support about (1) what to invest in and (2) how to self-govern. Ultimately, a different challenge undermined The DAO and the experiment came to an end.</p>
        """
  links: ['https://dao.consider.it']
  testimonial: testimonials.auryn


window.Webframe = ReactiveComponent
  displayName: 'Webframe'

  render: -> 

    DIV 
      style: 
        backgroundColor: 'white'
        borderRadius: 4
        boxShadow: '0 2px 8px rgba(0,0,0,.1)'
        border: '1px solid #DADADA'
        borderTop: 'none'
        width: @props.width or 882

      # aspect: 26/882
      SVG 
        viewBox: "0 0 882 26"
        width: (@props.width or 882) - 1
        height: 26/882 * ((@props.width or 882) - 1)
        style: 
          borderRadius: '4px 4px 0 0'
          position: 'relative'
          top: -1


        dangerouslySetInnerHTML: {__html: """
          <defs>
              <linearGradient x1="50%" y1="0%" x2="50%" y2="97.915338%" id="linearGradient-1">
                  <stop stop-color="#F6F4F6" offset="0%"></stop>
                  <stop stop-color="#D5D5D5" offset="99.5416135%"></stop>
                  <stop stop-color="#B7B6B7" offset="100%"></stop>
              </linearGradient>
              <rect id="path-2" x="0" y="0" width="882" height="25" rx="0"></rect>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-3">
                  <feOffset dx="0" dy="-1" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
                  <feComposite in="shadowOffsetOuter1" in2="SourceAlpha" operator="out" result="shadowOffsetOuter1"></feComposite>
                  <feColorMatrix values="0 0 0 0 0   0 0 0 0 0   0 0 0 0 0  0 0 0 0.2 0" type="matrix" in="shadowOffsetOuter1"></feColorMatrix>
              </filter>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-4">
                  <feGaussianBlur stdDeviation="0.5" in="SourceAlpha" result="shadowBlurInner1"></feGaussianBlur>
                  <feOffset dx="0" dy="1" in="shadowBlurInner1" result="shadowOffsetInner1"></feOffset>
                  <feComposite in="shadowOffsetInner1" in2="SourceAlpha" operator="arithmetic" k2="-1" k3="1" result="shadowInnerInner1"></feComposite>
                  <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 0.5 0" type="matrix" in="shadowInnerInner1"></feColorMatrix>
              </filter>
              <rect id="path-5" x="0" y="0" width="361.581259" height="14.1025641" rx="3.5"></rect>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-6">
                  <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
                  <feColorMatrix values="0 0 0 0 0.792156863   0 0 0 0 0.788235294   0 0 0 0 0.792156863  0 0 0 1 0" type="matrix" in="shadowOffsetOuter1"></feColorMatrix>
              </filter>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-7">
                  <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetInner1"></feOffset>
                  <feComposite in="shadowOffsetInner1" in2="SourceAlpha" operator="arithmetic" k2="-1" k3="1" result="shadowInnerInner1"></feComposite>
                  <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 1 0" type="matrix" in="shadowInnerInner1"></feColorMatrix>
              </filter>
              <rect id="path-8" x="0" y="0.606608157" width="16.4648609" height="14.1025641" rx="3.5"></rect>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-9">
                  <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
                  <feColorMatrix values="0 0 0 0 0.792156863   0 0 0 0 0.788235294   0 0 0 0 0.792156863  0 0 0 1 0" type="matrix" in="shadowOffsetOuter1"></feColorMatrix>
              </filter>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-10">
                  <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetInner1"></feOffset>
                  <feComposite in="shadowOffsetInner1" in2="SourceAlpha" operator="arithmetic" k2="-1" k3="1" result="shadowInnerInner1"></feComposite>
                  <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 1 0" type="matrix" in="shadowInnerInner1"></feColorMatrix>
              </filter>
              <rect id="path-11" x="0" y="0.606608157" width="17.1105417" height="14.1025641" rx="3.5"></rect>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-12">
                  <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
                  <feColorMatrix values="0 0 0 0 0.792156863   0 0 0 0 0.788235294   0 0 0 0 0.792156863  0 0 0 1 0" type="matrix" in="shadowOffsetOuter1"></feColorMatrix>
              </filter>
              <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="filter-13">
                  <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetInner1"></feOffset>
                  <feComposite in="shadowOffsetInner1" in2="SourceAlpha" operator="arithmetic" k2="-1" k3="1" result="shadowInnerInner1"></feComposite>
                  <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 1 0" type="matrix" in="shadowInnerInner1"></feColorMatrix>
              </filter>
              <ellipse id="path-14" cx="29.7013177" cy="4.45706419" rx="3.87408492" ry="3.87196696"></ellipse>
              <mask id="mask-15" maskContentUnits="userSpaceOnUse" maskUnits="objectBoundingBox" x="0" y="0" width="7.74816984" height="7.74393392" fill="white">
                  <use xlink:href="#path-14"></use>
              </mask>
              <ellipse id="path-16" cx="16.7877013" cy="4.43125108" rx="3.87408492" ry="3.84615385"></ellipse>
              <mask id="mask-17" maskContentUnits="userSpaceOnUse" maskUnits="objectBoundingBox" x="0" y="0" width="7.74816984" height="7.69230769" fill="white">
                  <use xlink:href="#path-16"></use>
              </mask>
              <ellipse id="path-18" cx="3.87408492" cy="4.43125108" rx="3.87408492" ry="3.84615385"></ellipse>
              <mask id="mask-19" maskContentUnits="userSpaceOnUse" maskUnits="objectBoundingBox" x="0" y="0" width="7.74816984" height="7.69230769" fill="white">
                  <use xlink:href="#path-18"></use>
              </mask>
          </defs>
          <g id="landing-page" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
              <g id="Desktop-HD-Copy-34" transform="translate(-328.000000, -749.000000)">
                  <g id="Safari" transform="translate(328.000000, 750.000000)">
                      <g id="background">
                          <use fill="black" fill-opacity="1" filter="url(#filter-3)" xlink:href="#path-2"></use>
                          <use fill-opacity="0.6" fill="url(#linearGradient-1)" fill-rule="evenodd" xlink:href="#path-2"></use>
                          <use fill="black" fill-opacity="1" filter="url(#filter-4)" xlink:href="#path-2"></use>
                      </g>
                      <g id="New-Tab" transform="translate(866.503660, 8.974359)">
                          <rect id="background" fill-opacity="0.5" fill="#B6B6B6" x="0" y="0" width="15.4963397" height="16.025641"></rect>
                          <path d="M7.74816984,7.69230769 L4.51976574,7.69230769 L4.51976574,8.33763552 L7.74816984,8.33763552 L7.74816984,11.5857856 L8.39385066,11.5857856 L8.39385066,8.33763552 L11.6222548,8.33763552 L11.6222548,7.69230769 L8.39385066,7.69230769 L8.39385066,4.48717949 L7.74816984,4.48717949 L7.74816984,7.69230769 Z M0.64568082,0 L15.4963397,0 L15.4963397,0.645327827 L0.64568082,0.645327827 L0.64568082,0 Z M0,0 L0.64568082,0 L0.64568082,15.376011 L0,15.376011 L0,0 Z" id="Add" fill="#7D7D7D"></path>
                      </g>
                      <g id="Search" transform="translate(260.209370, 5.162623)">
                          <g id="background">
                              <use fill="black" fill-opacity="1" filter="url(#filter-6)" xlink:href="#path-5"></use>
                              <use fill="#FCFBFC" fill-rule="evenodd" xlink:href="#path-5"></use>
                              <use fill="black" fill-opacity="1" filter="url(#filter-7)" xlink:href="#path-5"></use>
                          </g>
                          <path d="M352.865451,3.86914807 C351.055024,4.03175239 349.636164,5.55230111 349.636164,7.40406126 C349.636164,9.36428721 351.22611,10.9533643 353.187408,10.9533643 C355.148707,10.9533643 356.738653,9.36428721 356.738653,7.40406126 C356.738653,7.29529458 356.733758,7.18767059 356.724176,7.08139735 L356.075239,7.08139735 C356.086957,7.18733884 356.092972,7.29499793 356.092972,7.40406126 C356.092972,9.00788249 354.792107,10.3080365 353.187408,10.3080365 C351.58271,10.3080365 350.281845,9.00788249 350.281845,7.40406126 C350.281845,5.90900072 351.41226,4.67781842 352.865451,4.51771221 L352.865451,5.79162418 L356.09209,4.17742213 L352.865451,2.56322008 L352.865451,3.86914807 Z" id="reload" fill="#7E7E7E"></path>
                          <text id="url" font-family="HelveticaNeue, Helvetica Neue" font-size="10" font-weight="normal" letter-spacing="-0.15384616" fill="#000000">
                              <tspan x="19.6134701" y="10.5641026">#{@props.browser_loc}</tspan>
                          </text>
                      </g>
                      <g id="Back-+-Forward" transform="translate(50.363104, 4.521597)">
                          <g id="forward" transform="translate(17.756223, 0.000000)">
                              <g id="background">
                                  <use fill="black" fill-opacity="1" filter="url(#filter-9)" xlink:href="#path-8"></use>
                                  <use fill="#FCFBFC" fill-rule="evenodd" xlink:href="#path-8"></use>
                                  <use fill="black" fill-opacity="1" filter="url(#filter-10)" xlink:href="#path-8"></use>
                              </g>
                              <g id="Icon" transform="translate(6.779649, 4.190329)" stroke="#DADADA" stroke-width="1.5" stroke-linecap="round">
                                  <path d="M0.161420205,0.161331957 L3.425862,3.42398908" id="Line"></path>
                                  <path d="M0.161420205,6.69625979 L3.425862,3.43360266" id="Line"></path>
                              </g>
                          </g>
                          <g id="back">
                              <g id="background">
                                  <use fill="black" fill-opacity="1" filter="url(#filter-12)" xlink:href="#path-11"></use>
                                  <use fill="#FCFBFC" fill-rule="evenodd" xlink:href="#path-11"></use>
                                  <use fill="black" fill-opacity="1" filter="url(#filter-13)" xlink:href="#path-11"></use>
                              </g>
                              <g id="Icon" transform="translate(7.685212, 7.690329) scale(-1, 1) translate(-7.685212, -7.690329) translate(5.685212, 4.190329)" stroke="#585858" stroke-width="1.5" stroke-linecap="round">
                                  <path d="M0.161420205,0.161331957 L3.425862,3.42398908" id="Line"></path>
                                  <path d="M0.161420205,6.69625979 L3.425862,3.43360266" id="Line"></path>
                              </g>
                          </g>
                      </g>
                      <g id="Close-+-Minimize-+-Full-Screen" transform="translate(8.393851, 7.748236)">
                          <use id="green" stroke="#19B228" mask="url(#mask-15)" fill="#14CA34" xlink:href="#path-14"></use>
                          <use id="yellow" stroke="#E3A300" mask="url(#mask-17)" fill="#FFC008" xlink:href="#path-16"></use>
                          <use id="red" stroke="#E4453A" mask="url(#mask-19)" fill="#FF5F52" xlink:href="#path-18"></use>
                      </g>
                  </g>
              </g>
          </g>
          """}

      @props.children 




# UseCases = ReactiveComponent
#   displayName: 'UseCases'

#   render: -> 

#     uses = [
#       {
#         title: 'To engage the public'
#         subtitle: 'in giving focused feedback on plans and policy'
#         example_text: 'City of Seattle'
#         img: 'seattle_logo.png'
#         example: 'https://hala.consider.it'
#         img_dim: {height: 97, width: 98}
#         link: null,
#         color: '#007BC6'
#       },
#       {
#         title: 'To align behind a new strategic plan'
#         subtitle: 'by engaging staff, board, and other stakeholders'
#         example_text: 'WSFFN'
#         img: 'wsffn_logo.png'
#         example: 'https://wsffn.consider.it'   
#         img_dim: {height: 72, width: 90}     
#         link: null
#         color: '#6C7C00'
#       },
#       {
#         title: 'To organize community ideas'
#         subtitle: 'for taking collective action'
#         example_text: 'The DAO'
#         img: 'dao_logo.png'
#         example: 'https://dao.consider.it'
#         img_dim: {height: 72, width: 72}
#         link: null
#         color: '#D1170B'
#       },
#       {
#         title: 'To do something else '
#         subtitle: 'that we weren’t expecting!'
#         example_text: ''
#         img: 'rupaul_logo.png'
#         example: 'https://rupaul.consider.it'
#         img_dim: {height: 93, width: 220}        
#         link: null
#         color: '#D600B1'
#       },

#     ]


#     DIV 
#       style: 
#         backgroundColor: 'white'


#       DIV
#         style: 
#           width: SAAS_PAGE_WIDTH()
#           margin: 'auto'

#         H2
#           style: 
#             fontSize: 28
#             fontWeight: 400
#             textAlign: 'left'
#             paddingTop: 0
#             fontWeight: 200

#           'Example uses'

#         TABLE 
#           style: 
#             width: '100%'
#             borderCollapse: 'collapse'

#           TBODY null,
#             for use, idx in uses
#               TR 
#                 style: 
#                   height: 140
#                   borderTop: if idx > 0 then '1px solid #DDD'
#                   #borderBottom: if idx == uses.length - 1 then '1px solid #CBC8C8'

#                 TD 
#                   style: 
#                     verticalAlign: 'middle'

#                   DIV 
#                     style: 
#                       fontSize: 24
#                       fontWeight: 700
#                     use.title 

#                   DIV   
#                     style: 
#                       fontSize: 18
#                     use.subtitle
#                 TD 
#                   style: 
#                     fontStyle: 'italic'
#                     textAlign: 'center'
#                     fontSize: 18
#                     verticalAlign: 'middle'
#                     padding: '0 80px'
#                   'like'

#                 TD
#                   style: 
#                     verticalAlign: 'middle'


#                   A 
#                     href: use.example
#                     target: '_blank'
#                     style: 
#                       fontSize: 18
#                       fontWeight: 700
#                       color: use.color 

#                     SPAN 
#                       style: 
#                         display: 'inline-block'
#                         width: 100
#                         textAlign: 'center'                      

#                       IMG 
#                         src: asset("product_page/#{use.img}")
#                         style: 
#                           width: use.img_dim.width
#                           height: use.img_dim.height 
#                           verticalAlign: 'middle'

#                     SPAN 
#                       style: 
#                         fontSize: 24
#                         fontWeight: 500
#                         paddingLeft: 20
#                         verticalAlign: 'middle'
#                       use.example_text

#                 TD 
#                   style: 
#                     verticalAlign: 'middle'  

#                   A 
#                     href: use.example
#                     style: 
#                       fontSize: 18
#                       fontWeight: 700
#                       textDecoration: 'underline'
#                       color: use.color 
#                     target: '_blank'

#                     'visit example'




