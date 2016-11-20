window.LandingPage = ReactiveComponent
  displayName: 'LandingPage'

  render: -> 

    DIV null, 
      Heading()
      UseCases()


Heading = -> 
  compact = browser.is_mobile || true # SAAS_PAGE_WIDTH() < 1000

  DIV 
    style: 
      #background: "linear-gradient( to bottom, transparent, transparent #{if compact then 600 else 500}px, white #{if compact then 600 else 500}px )"
      position: 'relative'

    DIV 
      style: 
        paddingTop: 40
        width: SAAS_PAGE_WIDTH()
        margin: 'auto'
        textAlign: 'center'

      H1
        style: 
          fontSize: 50
          fontWeight: 400
          color: 'white'

        dangerouslySetInnerHTML: {__html: "A web forum#{if !compact then '<br/>' else ' '}that elevates your<br/>community's opinions."}

      DIV 
        style: 
          fontSize: 18
          color: 'white'
          marginTop: 8

        dangerouslySetInnerHTML: {__html: "Civil and organized discussion even when#{if !compact then '<br/>' else ' '}hundreds of stakeholders participate"}




      A
        'data-considerit-embed': true 
        href: "https://dao.consider.it/consider_ethereum?hide_author=true"




      # DIV 
      #   style: 
      #     background: "linear-gradient( to bottom, transparent, transparent #{if compact then 600 else 500}px, white #{if compact then 600 else 500}px )"
      #     position: 'relative'
      #   DIV 
      #     style: 
      #       color: 'white'
      #       width: SAAS_PAGE_WIDTH()
      #       margin: "auto"
      #       position: 'relative'
      #       zIndex: 0
      #       paddingTop: 24


      #     H1
      #       style: _.extend {}, h1, 
      #         lineHeight: '46px'
      #         marginTop: 40
      #         fontWeight: 500
      #         textAlign: if compact then 'center'

      #       dangerouslySetInnerHTML: {__html: "A web forum#{if !compact then '<br/>' else ' '}that elevates your<br/>community's opinions."}

      #     DIV
      #       style:
      #         margin: "28px auto 0 auto"
      #         paddingBottom: if compact then 300 else 100
      #         fontSize: 20
      #         fontWeight: 300
      #         textAlign: if compact then 'center'
      #         maxWidth: if compact then 400


      #       dangerouslySetInnerHTML: {__html: "Civil and organized discussion even when#{if !compact then '<br/>' else ' '}hundreds of stakeholders participate"}

      # DIV
      #   style: 
      #     position: 'absolute'
      #     right: if !compact then 0 else '50%' 
      #     bottom: -10
      #     marginRight: if compact then -450 / 2


      #   IMG 
      #     src: asset('product_page/wsffn_homepage.png')
      #     style: 
      #       width:  if compact then 450 else 800 * .78
      #       height: if compact then 450 * 453/800 else 453 * .78
      #       borderRadius: '4px 4px 0 0'
      #       backgroundColor: 'white'

        # Demo 
        #   width: 800 * .78
        #   height: 453 * .78


    DIV 
      style: 
        color: 'black'
        backgroundColor: 'white'
        height: '100%'
        #boxShadow: '0px -17px 27px 0px rgba(0,0,0,.14)'
        paddingTop: 10
        paddingBottom: 0
        zIndex: 1
        position: 'relative'
        minHeight: 60

      DIV 
        style: 
          width: SAAS_PAGE_WIDTH()
          margin: "auto"

        if !compact 
          DIV 
            style: 
              fontSize: 14
              float: 'right'
            A 
              href: 'https://galacticfederation.consider.it'
              target: '_blank'
              style: 
                color: primary_color()
                fontWeight: 700
                textDecoration: 'underline'
              'Try Consider.it yourself'






UseCases = ReactiveComponent
  displayName: 'UseCases'

  render: -> 

    uses = [
      {
        title: 'To engage the public'
        subtitle: 'in giving focused feedback on plans and policy'
        example_text: 'City of Seattle'
        img: 'seattle_logo.png'
        example: 'https://hala.consider.it'
        img_dim: {height: 97, width: 98}
        link: null,
        color: '#007BC6'
      },
      {
        title: 'To align behind a new strategic plan'
        subtitle: 'by engaging staff, board, and other stakeholders'
        example_text: 'WSFFN'
        img: 'wsffn_logo.png'
        example: 'https://wsffn.consider.it'   
        img_dim: {height: 72, width: 90}     
        link: null
        color: '#6C7C00'
      },
      {
        title: 'To organize community ideas'
        subtitle: 'for taking collective action'
        example_text: 'The DAO'
        img: 'dao_logo.png'
        example: 'https://dao.consider.it'
        img_dim: {height: 72, width: 72}
        link: null
        color: '#D1170B'
      },
      {
        title: 'To do something else '
        subtitle: 'that we weren’t expecting!'
        example_text: ''
        img: 'rupaul_logo.png'
        example: 'https://rupaul.consider.it'
        img_dim: {height: 93, width: 220}        
        link: null
        color: '#D600B1'
      },

    ]


    DIV 
      style: 
        backgroundColor: 'white'


      DIV
        style: 
          width: SAAS_PAGE_WIDTH()
          margin: 'auto'

        H2
          style: 
            fontSize: 28
            fontWeight: 400
            textAlign: 'left'
            paddingTop: 0
            fontWeight: 200

          'Example uses'

        TABLE 
          style: 
            width: '100%'
            borderCollapse: 'collapse'

          TBODY null,
            for use, idx in uses
              TR 
                style: 
                  height: 140
                  borderTop: if idx > 0 then '1px solid #DDD'
                  #borderBottom: if idx == uses.length - 1 then '1px solid #CBC8C8'

                TD 
                  style: 
                    verticalAlign: 'middle'

                  DIV 
                    style: 
                      fontSize: 24
                      fontWeight: 700
                    use.title 

                  DIV   
                    style: 
                      fontSize: 18
                    use.subtitle
                TD 
                  style: 
                    fontStyle: 'italic'
                    textAlign: 'center'
                    fontSize: 18
                    verticalAlign: 'middle'
                    padding: '0 80px'
                  'like'

                TD
                  style: 
                    verticalAlign: 'middle'


                  A 
                    href: use.example
                    target: '_blank'
                    style: 
                      fontSize: 18
                      fontWeight: 700
                      color: use.color 

                    SPAN 
                      style: 
                        display: 'inline-block'
                        width: 100
                        textAlign: 'center'                      

                      IMG 
                        src: asset("product_page/#{use.img}")
                        style: 
                          width: use.img_dim.width
                          height: use.img_dim.height 
                          verticalAlign: 'middle'

                    SPAN 
                      style: 
                        fontSize: 24
                        fontWeight: 500
                        paddingLeft: 20
                        verticalAlign: 'middle'
                      use.example_text

                TD 
                  style: 
                    verticalAlign: 'middle'  

                  A 
                    href: use.example
                    style: 
                      fontSize: 18
                      fontWeight: 700
                      textDecoration: 'underline'
                      color: use.color 
                    target: '_blank'

                    'visit example'




