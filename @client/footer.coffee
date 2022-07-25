require './shared'
require './customizations'

window.Footer = ReactiveComponent
  displayName: 'Footer'

  render : ->
    return SPAN null if embedded_demo()
    
    FOOTER 
      style: 
        position: 'relative'
        zIndex: 0
      (customization('SiteFooter') or DefaultFooter)()



big_button = -> 
  backgroundColor: logo_red
  # boxShadow: "0 4px 0 0 black"
  boxShadow: "0 1px 2px 0 rgb(0 0 0 / 50%)"
  fontWeight: 700
  color: 'white'
  padding: '6px 60px'
  display: 'inline-block'
  fontSize: 24
  border: 'none'
  borderRadius: 12
  borderBottom: "1px solid black"


window.DefaultFooter = ReactiveComponent
  displayName: 'Footer'
  render: ->
    subdomain = fetch '/subdomain'

    separator = SPAN 
      style: 
        padding: '0 6px'
        color: '#ccc'
      #dangerouslySetInnerHTML: { __html: "&bull;"}
      '|'

    DIV null,


      if customization('footer_bonus')?
        DIV 
          className: 'main_background'
          style: 
            paddingBottom: 36
          customization('footer_bonus')?()


      DIV 
        style:
          paddingTop: 80
          backgroundColor: selected_color
          # borderTop: "1px solid #888"
          
          padding: '65px 0 15px 0'
          position: 'relative'
          zIndex: 3
          color: 'white'

        DIV 
          key: 'back2top'
          dangerouslySetInnerHTML: __html: """
            <style>
            .custom-shape-divider-top-1651729272 {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                overflow: hidden;
                line-height: 0;
            }

            .custom-shape-divider-top-1651729272 svg {
                position: relative;
                display: block;
                width: calc(100% + 1.3px);
                height: 75px;
            }

            .custom-shape-divider-top-1651729272 .shape-fill {
                fill: #{if fetch('location').url.indexOf('/dashboard') > -1 then 'white' else main_background_color};
            }
            </style>
            <div class="custom-shape-divider-top-1651729272">
                <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none">
                    <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" class="shape-fill"></path>
                </svg>
            </div>  
          """

        DIV 
          style: 
            width: CONTENT_WIDTH()
            margin: 'auto'


          DIV 
            style: 
              textAlign: 'center'

            TechnologyByConsiderit
              size: 26
              color: 'white'
            BR null

            DIV 
              style:
                marginBottom: 18

              A 
                key: 'considerit-link'
                href: 'https://github.com/Considerit/ConsiderIt'
                style: 
                  textDecoration: 'underline'
                  fontWeight: 600
                  fontSize: 14

                target: '_blank'

                "Consider.it is Open Source"
                IMG 
                  width: 18
                  height: 18
                  src: asset('product_page/github_logo_white.png')
                  style: 
                    height: 18
                    marginLeft: 6
                    verticalAlign: 'middle'


              A 
                key: 'create-forum'
                href: 'https://consider.it'
                style: 
                  display: 'inline-block'
                  textDecoration: 'underline'
                  fontSize: 14
                  marginTop: 10
                  fontWeight: 600
                  paddingLeft: 24

                translator 
                  id: "footer.created_your_own_forum"
                  'Create your own forum'



          # more info

          DIV 
            key: 'more_info'
            style: 
              fontSize: 12
              textAlign: 'center'
              marginTop: 20

            SPAN 
              key: 'considerit-errata'
              style: 
                display: 'flex'
                alignItems: 'center'
                justifyContent: 'center'

              DIV 
                key: 'privacy & terms'
  
                SPAN 
                  key: 'copyright'
                  '© Consider.it LLC. All rights reserved. '

                TRANSLATE
                  key: 'footer policies'
                  id: 'footer.policies'
                  privacy_link: 
                    component: A 
                    args: 
                      key: 'privacy_link'
                      href: '/privacy_policy'
                      style: 
                        textDecoration: 'underline'

                  terms_link:
                    key: 'terms'
                    component: A 
                    args: 
                      key: 'terms_link'
                      href: '/terms_of_service'
                      style: 
                        textDecoration: 'underline'

                  "<privacy_link>Privacy</privacy_link> and <terms_link>Terms</terms_link>."

              DIV 
                key: 'bug reports'
                style: 
                  marginLeft: 40

                TRANSLATE
                  id: "footer.bug_reports"
                  link: 
                    component: A
                    args: 
                      key: 'mailto'
                      style: 
                        textDecoration: 'underline'                    
                      href: 'mailto:help@consider.it'

                  "Report bugs to <link>help@consider.it</link>"

              if !customization('google_translate_style') || fetch('location').url != '/'
                DIV 
                  className: 'google-translate-candidate-container'
                  style: 
                    marginLeft: 40




require './logo'
window.TechnologyByConsiderit = ReactiveComponent
  displayName: 'TechnologyByConsiderit'
  render : -> 
    size = @props.size or 20

    color = @props.color or logo_red
    DIV 
      style: 
        textAlign: 'left'
        display: 'inline-block'
        fontSize: size
      "Technology by "
      A 
        onMouseEnter: => 
          @local.hover = true
          save @local
        onMouseLeave: => 
          @local.hover = false
          save @local
        href: 'https://consider.it'
        target: '_blank'
        title: 'Consider.it\'s homepage'
        style: 
          position: 'relative'
          top: 6
          left: 3
        
        drawLogo 
          height: size + 5
          main_text_color: color
          o_text_color: color
          clip: false
          draw_line: true 
          line_color: color
          i_dot_x: if @local.hover then 252 else 142
          transition: true





