window.Footer = -> 

  nav = [
    # {
    #   label: 'I want a forum for…'
    #   links: [
    #     {
    #       label: 'Public Involvement'
    #       link: ''
    #     }, 
    #     {
    #       label: 'Strategic Planning'
    #       link: ''
    #     }, 
    #     {
    #       label: 'Decentralized Organizing'
    #       link: ''
    #     }, 
    #     {
    #       label: 'Something Else'
    #       link: ''
    #     }
    #   ]
    # }, 
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

  loc = fetch 'location'

  w = SAAS_PAGE_WIDTH()
  mobile = w < 700

  section_div = (section) -> 
    DIV null,
      H3 
        style: 
          fontSize: 16
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
                color: primary_color()
                textDecoration: 'underline'
                fontSize: 14

              link.label

  FOOTER
    id: 'footer'


    DIV 
      style: 
        paddingTop: 140
        backgroundColor: 'white'


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
          
          if loc.url != '/create_forum' && !mobile         
            A 
              href: 'https://galacticfederation.consider.it'
              target: '_blank'
              style: big_button()
              'Try Consider.it'

          if loc.url != '/create_forum'
            A 
              href: '/create_forum'
              style: _.extend {}, big_button(), 
                backgroundColor: '#717171'
                marginLeft: 40

              'Start a Free Forum'



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
      'Privacy'
    ' and '
    A
      href: '/terms_of_service'
      style: 
        textDecoration: 'underline'
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