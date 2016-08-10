window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: -> 
    HEADER_HEIGHT = 30 
    DIV
      style:
        position: "relative"
        margin: "0 auto"
        backgroundColor: logo_red
        height: HEADER_HEIGHT
        zIndex: 1

      DIV
        style:
          width: CONTENT_WIDTH()
          margin: 'auto'

        SPAN 
          style:
            position: "relative"
            top: 4
            left: if window.innerWidth > 1055 then -23.5 else 0

          drawLogo HEADER_HEIGHT + 5, 
                  'white', 
                  (if @local.in_red then 'transparent' else logo_red), 
                  !@local.in_red,
                  false

        SPAN 
          style: 
            fontSize: 22
            position: 'relative'
            top: -5
            color: 'white'
            fontStyle: 'italic'

          'Issue Slate'
