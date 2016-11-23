window.Footer = ReactiveComponent
  displayName: 'Footer'

  render: -> 
    loc = fetch 'location'

    w = SAAS_PAGE_WIDTH()
    mobile = w < 700


    section_div = (section) -> 
      DIV null,
        H3 
          style: 
            fontSize: 18
            fontWeight: 500
            color: '#000'
            marginBottom: 10
          section.label 

        UL 
          style: 
            listStyle: 'none'

          for link in section.links
            LI 
              style:
                marginBottom: 10
                

              A 
                href: link.link
                style: 
                  color: if loc.url == '/' then seattle_salmon else primary_color()
                  textDecoration: 'underline'
                  fontSize: 16
                  fontWeight: 500

                link.label

    
    f_height = fetch('footer').height

    DIV null,

      DIV 
        style: 
          height: (f_height or 350) - 2 + 70
          backgroundColor: 'white'

      FOOTER
        ref: 'footer'
        id: 'footer'
        style: 
          paddingTop: 140
          backgroundColor: 'white'
          position: if f_height then 'absolute' else 'relative'
          bottom: 0
          left: 0
          zIndex: 1
          width: '100%'


        DIV 
          style: 
            textAlign: 'center'
            position: 'absolute'
            top: 0
            width: '100%'

          BUTTON 
            onClick: -> scrollTo 0, 0
            onKeyPress: (e) -> 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.preventDefault()
                scrollTo 0, 0

            style: 
              backgroundColor: '#eee'
              borderRadius: 16
              padding: '8px 24px'
              border: 'none'
              color: 'black'

            'back to top'


        DIV 
          style:
            paddingTop: 80
            backgroundColor: "#F4F4F4"
            borderTop: "1px solid ##{737373}"
            
            padding: '45px 0 15px 0'
            position: 'relative'
            zIndex: 3

          DIV 
            style: 
              width: w
              margin: 'auto'

            # buttons 

            DIV 
              style: 
                position: 'relative'
                margin: 'auto'
                textAlign: 'center'
                top: -70
              
              if loc.url != '/create_forum'
                A 
                  href: '/create_forum'
                  style: _.extend {}, big_button(), 
                    backgroundColor: if loc.url == '/' then seattle_salmon else primary_color()
                  'Start a Free Forum'

              if loc.url != '/create_forum' && !mobile         
                A 
                  href: 'https://galacticfederation.consider.it'
                  target: '_blank'
                  style: _.extend {}, big_button(), 
                    backgroundColor: '#717171'
                    marginLeft: 40
                  'Play Around With It'




            # nav sections
            DIV null,

              if mobile 
                  for section in nav
                    DIV 
                      style: 
                        textAlign: 'center'
                        paddingBottom: 20                

                      section_div section

              else 

                TABLE 
                  style:
                    margin: 'auto'
                    borderSpacing: '80px 0px'
                    borderCollapse: 'separate'
                  

                  TR 
                    style: {}

                    for section in nav
                      TD 
                        style: 
                          textAlign: 'right'

                        section_div section


            # more info

            DIV 
              style: 
                color: '#303030'
                fontSize: 11
                textAlign: 'center'
                marginTop: 65

              if mobile 
                [helloemail()
                DIV style: paddingBottom: 10
                address()
                DIV style: paddingBottom: 10
                copyright()]
              else 
                [copyright()
                helloemail()
                address()]
              
  componentDidMount: -> 
    f = fetch 'footer' 
    f.height = @refs.footer.getDOMNode().offsetHeight
    save f 



nav = [
  {
    label: 'What is Consider.it?'
    links: [
      {
        label: 'Feature Tour'
        link: '/tour#features'
      }, 
      {
        label: 'Video Demo'
        link: '/tour?play_demo=true'
      }, 

      # {
      #   label: 'Compare to Other Tools'
      #   link: '/tour#compare'
      # }, 
      {
        label: 'Research Findings'
        link: '/tour#research'
      },
      {
        label: 'Tech Questions'
        link: '/pricing#faq'
      }
    ]
  }, 
  {
    label: 'I want a forum for…'
    links: [
      {
        label: 'Public Involvement'
        link: '#seattle'
      }, 
      {
        label: 'Strategic Planning'
        link: '#wsffn'
      }, 
      {
        label: 'Decentralized Organizing'
        link: '#dao'
      }, 
      # {
      #   label: 'Something Else'
      #   link: ''
      # }
    ]
  }, 

  {
    label: 'What will it cost?'
    links: [
      {
        label: 'Pricing Tiers'
        link: '/pricing'
      }, 
      {
        label: 'Consulting Services'
        link: '/pricing#consulting'
      }, 
      {
        label: 'Testimonials'
        link: '/pricing#testimonials'
      }, 
      {
        label: 'Pricing Questions'
        link: '/pricing#faq'
      }
    ]
  },
  {
    label: 'Hello, friend!'
    links: [
      {
        label: 'Contact Us'
        link: '/contact'
      }, 
      {
        label: 'Consultant Partnership'
        link: '/pricing#partnership'
      }, 
      {
        label: 'Request a demo'
        link: '/contact#request_demo'
      }, 

      # {
      #   label: 'Our History'
      #   link: '/contact#history'
      # }, 
      # {
      #   label: 'Our Team'
      #   link: '/contact#team'
      # }
    ]
  }
]


copyright = -> 
  SPAN null, 
    DIV 
      style: 
        display: 'inline-block'
      '© 2016 Consider.it. All rights reserved. ' 
    A
      href: '/privacy_policy'
      style: 
        textDecoration: 'underline'
        fontSize: 11
      'Privacy'
    ' and '
    A
      href: '/terms_of_service'
      style: 
        textDecoration: 'underline'
        fontSize: 11
      'Terms'
    '.'

helloemail = -> 
  A 
    href: 'mailto:hello@consider.it'
    style: 
      margin: '0px 40px'
      textDecoration: 'underline'
      display: 'inline-block'
    'hello@consider.it'


address = -> 
  DIV 
    style: 
      display: 'inline-block'            
    '2420 NE Sandy Blvd, Suite 126 Portland, OR 97232'