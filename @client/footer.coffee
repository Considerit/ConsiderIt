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


styles += """
  .footer_wrapper {
    padding: 65px 0 15px 0;
    background-color: #{selected_color};
    position: relative;
    z-index: 3;
    color: white;
  }

  .Footer .primary_info {
    margin-top: 18px;
    margin-bottom: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .Footer .considerit-link {
    text-decoration: underline;
    font-weight: 600;
    font-size: 14px;
  }

  .Footer .create-forum {
    text-decoration: underline;
    font-size: 14px;
    font-weight: 600;
  }

  .Footer .more-info {
    font-size: 12px;
    text-align: center;
    margin-top: 20px;

    display: flex;
    align-items: center;
    justify-content: center;    
  }

  .Footer .more-info > div {
    padding: 12px 20px;
  }

  @media #{NOT_PHONE_MEDIA} {
    .footer_wrapper {
      padding: 65px 0 15px 0;
    }

    .Footer .primary_info {
      flex-direction: row;
    }

    .Footer .create-forum {
      display: inline-block;
      padding-left: 24px;
    }

    .Footer .more-info {
      flex-direction: row;
    }

  }

  @media #{PHONE_MEDIA} {
    .footer_wrapper {
      padding: 36px 0 15px 0;
    }

    .Footer .primary_info {
      flex-direction: column;
    }
    .Footer .more-info {
      flex-direction: column;
    }
    .bug_reports {
      display: none;
    }
  }

"""


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

    footer_bonus = customization('footer_bonus')

    DIV 
      className: "Footer"

      if footer_bonus?
        DIV 
          className: 'main_background'

          if typeof footer_bonus == "function"
            footer_bonus()
          else 
            DIV 
              dangerouslySetInnerHTML: __html: footer_bonus



      DIV 
        className: 'footer_wrapper'

        DIV 
          key: 'back2top'
          dangerouslySetInnerHTML: if WINDOW_WIDTH() > 760 then __html: """
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
                fill: #{if fetch('location').url.indexOf('/dashboard') > -1 || TABLET_SIZE() then 'white' else main_background_color};
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
            # width: CONTENT_WIDTH()
            margin: 'auto'


          DIV 
            style: 
              textAlign: 'center'

            TechnologyByConsiderit
              size: if PHONE_SIZE() then 18 else 26
              color: 'white'


            BR null

            DIV 
              className: 'primary_info'

              A 
                className: 'considerit-link'
                key: 'considerit-link'
                href: 'https://github.com/Considerit/ConsiderIt'
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
                className: 'create-forum'
                key: 'create-forum'
                href: "https://#{fetch('/application').base_domain}"

                translator 
                  id: "footer.created_your_own_forum"
                  'Create your own forum'



          # more info

          DIV 
            className: 'more-info'
            key: 'more_info'

            DIV 
              key: 'privacy & terms'

              SPAN 
                key: 'copyright'
                '© Consider.it LLC. All rights reserved. '

              TRANSLATE
                id: 'footer.policies'
                privacy_link: 
                  component: A 
                  args: 
                    key: 'privacy_link'
                    href: '/docs/legal/privacy_policy'
                    style: 
                      textDecoration: 'underline'

                terms_link:
                  key: 'terms'
                  component: A 
                  args: 
                    key: 'terms_link'
                    href: '/docs/legal/terms_of_service'
                    style: 
                      textDecoration: 'underline'

                "<privacy_link>Privacy</privacy_link> and <terms_link>Terms</terms_link>."

            DIV 
              className: 'bug_reports'
              key: 'bug reports'

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

            DIV 
              className: 'region'
              key: 'region'

              translator 'server.region_hosted', "Hosted in"
              " "
              get_region_name()

          if !customization('google_translate_style') || fetch('location').url != '/'
            DIV 
              className: 'google-translate-candidate-container'




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
        href: "https://#{fetch('/application').base_domain}"
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





