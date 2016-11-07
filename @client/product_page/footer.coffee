window.Footer = -> 

  nav = [
    {
      label: 'I want a forum for…'
      links: [
        {
          label: 'Public Involvement'
          link: ''
        }, 
        {
          label: 'Strategic Planning'
          link: ''
        }, 
        {
          label: 'Decentralized Organizing'
          link: ''
        }, 
        {
          label: 'Something Else'
          link: ''
        }
      ]
    }, 
    {
      label: 'What is Consider.it?'
      links: [
        {
          label: 'Video Demo'
          link: '/tour'
        }, 
        {
          label: 'Feature Tour'
          link: '/tour#features'
        }, 
        {
          label: 'Compare to other tools'
          link: '/tour#compare'
        }, 
        {
          label: 'Research findings'
          link: '/tour#research'
        },
        {
          label: 'Common questions'
          link: '/tour#faq'
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
          link: '/pricing#consulting'
        }, 
        {
          label: 'Common questions'
          link: '/pricing#faq'
        }
      ]
    },
    {
      label: 'Hello, friend!'
      links: [
        {
          label: 'Contact us'
          link: '/contact'
        }, 
        {
          label: 'Our history'
          link: '/contact#history'
        }, 
        {
          label: 'Our team'
          link: '/contact#team'
        }
      ]
    }




  ]

  FOOTER
    id: 'footer'
    style:
      paddingTop: 80
      backgroundColor: "#F4F4F4"
      borderTop: "1px solid ##{737373}"
      
      padding: '45px 0 15px 0'
      position: 'relative'
      zIndex: 3


    DIV 
      style: 
        width: SAAS_PAGE_WIDTH
        margin: 'auto'

      # buttons 

      DIV 
        style: 
          position: 'relative'
          margin: 'auto'
          textAlign: 'center'
          top: -70

        A 
          href: 'https://galacticfederation.consider.it'
          target: '_blank'
          style: big_button()
          'Try Consider.it'

        BIG_BUTTON 'Start a Free Forum', 
          style: 
            backgroundColor: '#717171'
            marginLeft: 40


      # nav sections
      DIV null,
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

      # more info

      DIV 
        style: 
          color: '#303030'
          fontSize: 11
          textAlign: 'center'
          marginTop: 65

        SPAN null, 

          DIV 
            style: 
              display: 'inline-block'
            '© 2016 Consider.it. All rights reserved.' #Privacy and Terms.

          A 
            href: 'mailto:hello@consider.it'
            style: 
              marginLeft: 40
              textDecoration: 'underline'
              display: 'inline-block'
            'hello@consider.it'

          DIV 
            style: 
              marginLeft: 40
              display: 'inline-block'            
            '2420 NE Sandy Blvd, Suite 126 Portland, OR 97232'