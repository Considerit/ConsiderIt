HEADER_HEIGHT = 80

window.Header = ReactiveComponent
  displayName: "Header"
  render: ->
    current_user = fetch("/current_user")

    nav_links = ['Tour', 'Pricing', 'Contact', 'Create Forum']
    

    dot_x = switch fetch('location').url
      when '/'
        288.2
      when '/tour'
        580 + 120 
      when '/pricing'
        674 + 120
      when '/contact'
        781 + 120
      when '/create_forum'
        925 + 120

    dot_size = 10

    HEADER
      style:
        position: "relative"
        margin: "0 auto 5px auto"

      DIV
        style:
          width: SAAS_PAGE_WIDTH
          margin: 'auto'
          borderBottom: '1px solid white'

        A 
          href: '/'
          style:
            display: 'inline-block'
            position: "relative"
            top: 12

          drawLogo HEADER_HEIGHT - 10,
                  'white', 'transparent'

          SVG 
            width: dot_size 
            height: dot_size 
            viewBox: "0 0 #{dot_size} #{dot_size}" 
            version: "1.1" 
            xmlns: "http://www.w3.org/2000/svg" 
            style: _.extend css.crossbrowserify({transition: 'left 500ms'}), 
              position: 'absolute'
              left: dot_x
              zIndex: 2
              bottom: 6


            G null,

              CIRCLE 
                fill: 'white'
                cx: dot_size / 2
                cy: dot_size / 2
                r: dot_size / 2
                 

          SPAN 
            style: 
              width: 15
              height: 15
              borderRadius: '50%'


        # nav menu
        DIV 
          style: 
            width: SAAS_PAGE_WIDTH
            margin: 'auto'
            position: 'relative'
            top: -37
            right: -8

          DIV 
            style: 
              position: 'absolute'
              right: 0

            for nav,idx in nav_links
              A 
                key: idx
                style: _.extend {}, base_text,
                  fontWeight: 600
                  fontSize: 18
                  color: 'white'
                  marginLeft: 25
                  cursor: 'pointer'
                  border: '1px solid transparent'
                  borderColor: if idx == nav_links.length - 1 then 'white'
                  borderRadius: '8px 8px 8px 0'
                  padding: if idx == nav_links.length - 1 then '14px 20px' else '14px 10px'
                  

                href: "/#{nav.toLowerCase().replace(' ', '_')}"
                nav

