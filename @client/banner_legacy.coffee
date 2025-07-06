
window.MediaBanner = -> 
  homepage = is_a_dialogue_page()
  subdomain = bus_fetch '/subdomain'
  edit_banner = bus_fetch 'edit_banner'

  return SPAN null if !subdomain.name 

  if !homepage
    return  DIV
              style: 
                backgroundColor: 'white'

              DIV
                style:
                  margin: 'auto'
                  fontSize: 43
                  padding: '10px 20px' 

                back_to_homepage_button {fontSize: 32}, translator 'engage.back_to_homepage', 'Homepage'

  has_image_background = edit_banner.masthead_preview != '*delete*' && (edit_banner.masthead_preview || customization('banner')?.background_image_url)
  if has_image_background
    bg = edit_banner.masthead_preview or customization('banner')?.background_image_url

  convert_opacity = (value) ->
    if !value
      '00'
    else 
      parseInt(value).toString(16)
    
  DIV 
    id: 'banner'
    className: "MediaBanner"

    STYLE
      dangerouslySetInnerHTML: __html: """

        .MediaBanner {
          position: relative;
          color: var(--text_dark);
          background-color: #eee;
          padding: 0px 2px;
          border-bottom: 1px solid black;
        } .dark .MediaBanner {
          color: var(--text_light);
        }
        .MediaBanner > .upper_wrapper {
          padding-top: 28px;
          background-color: white;
        }

        .MediaBanner > .upper_wrapper .CustomizeTitle .banner_title {
          font-size: 60px;
          font-weight: 700;
          font-family: #{header_font()};
          text-align: left;
          margin-left: 36px;
          margin-bottom: 22px;
        }
        .MediaBanner > .image_wrapper {
          padding: 20px 36px;
        } 
        .MediaBanner > .image_wrapper > img {
          object-fit: cover;
          display: block;
          height: 260px;
          width: 100%;
        }
        .MediaBanner #tabs {
          margin-top: 0;
          top: 0;
          border-top: 1px solid #ccc;
          box-shadow: 0 1px 3px #00000026;
        }
        .MediaBanner #tabs > ul {
          text-align: left;
          width: 100%;
          padding-left: 20px;          
        }
        .MediaBanner #tabs > ul > li {
          background-color: transparent;
          margin: 0px 6px;          
        }          
        .MediaBanner #tabs > ul > li > h4 {
          text-transform: uppercase;
          font-family: #{customization('font')};
          font-weight: 600;
          font-size: 16px;
          padding: 16px 8px 24px;
          color: var(--text_dark);
        }
        .dark .MediaBanner #tabs > ul > li > h4 {
          color: var(--text_light);
        }

        .MediaBanner #tabs > ul > li.selected > h4, 
        .MediaBanner #tabs > ul > li:hover > h4 {
          color: var(--text_dark);
          text-decoration: underline;
        }
        .dark .MediaBanner #tabs > ul > li.selected > h4, 
        .dark .MediaBanner #tabs > ul > li:hover > h4 {
          color: var(--text_light);
        }
      """

    DIV 
      className: 'upper_wrapper'

      # CustomizeLogo() 

      CustomizeGoogleTranslate()
      CustomizeTitle()

      CustomizeBackground()

      HomepageTabs()

    if has_image_background
      DIV 
        className: 'image_wrapper'

        IMG
          src: bg


window.ImageHeader = (opts) ->
  subdomain = bus_fetch '/subdomain'   
  loc = bus_fetch 'location'    

  return SPAN null if !subdomain.name

  opts ||= {}
  _.defaults opts, 
    background_color: customization('banner')?.background_css or "var(--focus_color)"
    background_image_url: customization('banner')?.background_image_url
    text: customization('banner')?.title
    external_link: subdomain.external_project_url

  is_light = is_light_background()
    
  DIV 
    style: 
      backgroundColor: opts.background_color

    IMG 
      alt: opts.background_image_alternative_text
      src: opts.background_image_url
      style: 
        width: '100%'

    if opts.text
      H1 style: {textAlign: 'center', color: "var(--text_light)", margin: 'auto', fontSize: 60, fontWeight: 700, position: 'relative', paddingTop: 30}, 
        opts.text

    CustomizeBackground()

    HomepageTabs(opts)



# A small header with text and optionally a logo
window.ShortHeader = (opts) ->
  subdomain = bus_fetch '/subdomain'   
  loc = bus_fetch 'location'

  return SPAN null if !subdomain.name

  homepage = is_a_dialogue_page()

  opts ||= {}
  _.defaults opts, (customization('forum_header') or {}),
    text: customization('banner')?.title or subdomain.name
    external_link: subdomain.external_project_url
    logo_src: customization('banner')?.logo?.url
    logo_height: 50
    min_height: 70
    padding: '8px 0'
    padding_left_icon: 20


  opts.background = 'transparent'
  background_is_light = true

  DIV 
    style:
      background: opts.background

    DIV
      style: 
        position: 'relative'
        padding: opts.padding
        minHeight: opts.min_height
        display: 'flex'
        flexDirection: 'row'
        justifyContent: 'flex-start'
        alignItems: 'center'
        width: if homepage then HOMEPAGE_WIDTH()
        margin: if homepage then 'auto'

      DIV 
        style: 
          paddingLeft: if !homepage then opts.padding_left_icon else 0
          paddingRight: 20
          height: if opts.logo_height then opts.logo_height
          display: 'flex'
          alignItems: 'center'


        if opts.logo_src
          A 
            href: if !homepage then '/' else opts.external_link
            style: 
              fontSize: 0
              cursor: if !homepage && !opts.external_link then 'default'
              verticalAlign: 'middle'
              display: 'block'

          
            IMG 
              src: opts.logo_src
              alt: "#{subdomain.name} logo"
              style: 
                height: opts.logo_height

        if !homepage

          DIV 
            style: 
              paddingRight: 18
              position: if opts.logo_src then 'absolute'
              bottom: if opts.logo_src then -30
              left: if opts.logo_src then 7
              

            back_to_homepage_button
              color: if !background_is_light && !opts.logo_src then 'white'
              fontSize: 18
              fontWeight: 600

            , TRANSLATE("engage.navigate_back_to_homepage" , 'homepage')


      if opts.text
        H2 
          style: 
            color: if !background_is_light then 'white'
            marginLeft: if opts.logo_src then 35
            paddingRight: 90
            fontSize: 32
            fontWeight: 400

          opts.text




window.HawaiiHeader = (opts) ->

  homepage = is_a_dialogue_page()
  subdomain = bus_fetch '/subdomain'

  return SPAN null if !subdomain.name 

  background_color = opts.background_color or customization('banner')?.background_css or "var(--focus_color)"
  is_light = is_light_background(background_color)

  opts ||= {}
  _.defaults opts, 
    background_color: background_color
    background_image_url: opts.background_image_url or customization('banner')?.background_image_url
    logo: customization('banner')?.logo?.url
    logo_width: 200
    title: '<title is required>'
    subtitle: null
    title_style: {}
    subtitle_style: {}
    tab_style: {}
    homepage_button_style: {}

  _.defaults opts.title_style,
    fontSize: 47
    color: if is_light then "var(--text_dark)" else "var(--text_light)"
    fontWeight: 300
    display: 'inline-block'

  _.defaults opts.subtitle_style,
    position: 'relative'
    fontSize: 22
    color: if is_light then "var(--text_dark)" else "var(--text_light)"
    marginTop: 0
    opacity: .7
    textAlign: 'center'  

  _.defaults opts.homepage_button_style,
    display: 'inline-block'
    color: if is_light then "var(--text_dark)" else "var(--text_light)"
    # opacity: .7
    position: 'absolute'
    left: -80
    fontSize: opts.title_style.fontSize
    #top: 38
    fontWeight: 400
    paddingLeft: 25 # Make the clickable target bigger
    paddingRight: 25 # Make the clickable target bigger
    cursor: if bus_fetch('location').url != '/' then 'pointer'


  DIV
    style:
      position: 'relative'
      padding: "30px 0"
      backgroundPosition: 'center'
      backgroundSize: 'cover'
      backgroundImage: "url(#{opts.background_image_url})"
      backgroundColor: opts.background_color


    STYLE null,
      '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
         p {margin-bottom: 1em}'''

    DIV 
      style: 
        margin: 'auto'
        width: HOMEPAGE_WIDTH()
        position: 'relative'
        textAlign: if homepage then 'center'


      back_to_homepage_button opts.homepage_button_style

      if homepage && opts.logo
        IMG 
          alt: opts.logo_alternative_text
          src: opts.logo
          style: 
            width: opts.logo_width
            display: 'block'
            margin: 'auto'
            paddingTop: 20


      H1 
        style: opts.title_style
        opts.title 

      if homepage && opts.subtitle
        subtitle_is_html = opts.subtitle.indexOf('<') > -1 && opts.subtitle.indexOf('>') > -1
        DIV
          style: opts.subtitle_style
          
          dangerouslySetInnerHTML: if subtitle_is_html then {__html: opts.subtitle}

          if !subtitle_is_html
            opts.subtitle       

      if homepage
        DIV 
          style: 
            position: 'relative'
            margin: if get_tabs() then '62px auto 0 auto'
            width: HOMEPAGE_WIDTH()
            

          HomepageTabs
            tab_style: opts.tab_style
            tab_wrapper_style: _.defaults {}, opts.tab_wrapper_style or {},
              backgroundColor: opts.tab_background_color
              margin: '0 6px'
            active_style: _.defaults {}, opts.tab_active_style or {},
              backgroundColor: 'white'
              color: "var(--text_dark)"
            active_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
              backgroundColor: opts.tab_background_color
            wrapper_style: _.defaults {}, opts.tabs_wrapper_style or {},
              marginTop: 80
              top: 0
            list_style: opts.tabs_list_style or {}



window.SeattleHeader = (opts) -> 

  homepage = is_a_dialogue_page()
  subdomain = bus_fetch '/subdomain'

  return SPAN null if !subdomain.name 

  opts ||= {}
  _.defaults opts, 

    external_link: subdomain.external_project_url

    background_color: '#fff'
    background_image_url: customization('banner')?.background_image_url

    external_link_style: {}
    quote_style: {}
    paragraph_style: {}
    section_heading_style: {}


  paragraph_style = _.defaults opts.paragraph_style,
    fontSize: 18
    color: '#444'
    paddingTop: 10
    display: 'block'

  quote_style = _.defaults opts.quote_style,
    fontStyle: 'italic'
    margin: 'auto'
    padding: "40px 40px"
    fontSize: paragraph_style.fontSize
    color: paragraph_style.color 

  section_heading_style = _.defaults opts.section_heading_style,
    display: 'block'
    fontWeight: 400
    fontSize: 28
    color: "var(--text_dark)"

  external_link_style = _.defaults opts.external_link_style, 
    display: 'block'
    position: 'absolute'
    top: 22
    left: 20
    color: "var(--focus_color)"


  if !homepage
    return  DIV
              style: 
                backgroundColor: 'white'
              DIV
                style:
                  width: HOMEPAGE_WIDTH()
                  margin: 'auto'
                  fontSize: 43
                  padding: '10px 0' 

                A
                  href: '/' 

                  '< '

                  SPAN
                    style:
                      fontSize: 32
                      position: 'relative'
                      left: 5
                    'Homepage'


  DIV
    style:
      position: 'relative'

    if opts.external_link
      A 
        href: opts.external_link
        target: '_blank'
        style: opts.external_link_style

        I 
          className: 'fa fa-chevron-left'
          style: 
            display: 'inline-block'
            marginRight: 5

        opts.external_link_anchor or opts.external_link

    if opts.background_image_url
      IMG
        alt: opts.background_image_alternative_text
        style: _.defaults {}, opts.image_style,
          width: '100%'
          display: 'block'
        src: opts.background_image_url

    DIV 
      style: 
        padding: '20px 0'

      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: 'auto'

        if opts.quote 
            
          DIV  
            style: quote_style
            "“#{opts.quote.what}”"

            if opts.quote.who 
              DIV  
                style:
                  paddingLeft: '70%'
                  paddingTop: 10
                "– #{opts.quote.who}"

        DIV null,

          for section, idx in opts.sections 

            DIV 
              style: 
                marginBottom: 20                


              if section.label 
                HEADING = if idx == 0 then H1 else DIV
                HEADING
                  style: _.defaults {}, (section.label_style or {}), section_heading_style
                  section.label 

              DIV null, 
                for paragraph in (section.paragraphs or [])
                  SPAN 
                    style: paragraph_style
                    dangerouslySetInnerHTML: { __html: paragraph }

        if opts.salutation 
          DIV 
            style: _.extend {}, paragraph_style,
              marginTop: 10

            if opts.salutation.text 
              DIV 
                style: 
                  marginBottom: 18
                opts.salutation.text 

            A 
              href: if opts.external_link then opts.external_link
              target: '_blank'
              style: 
                display: 'block'
                marginBottom: 8

              if opts.salutation.image 
                IMG
                  src: opts.salutation.image 
                  alt: ''
                  style: 
                    height: 70
              else
                opts.salutation.from 

            if opts.salutation.after 
              DIV 
                style: _.extend {}, paragraph_style,
                  margin: 0
                dangerouslySetInnerHTML: { __html: opts.salutation.after }
                
        if opts.login_callout
          AuthCallout()

        if opts.closed 
          DIV 
            style: 
              marginTop: 40
              backgroundColor: considerit_red
              color: "var(--text_light)"
              fontSize: 28
              textAlign: 'center'
              padding: "30px 42px"

            "The comment period is now closed. Thank you for your input!"


      if true
        active_style = _.defaults {}, opts.tab_active_style or {},
          opacity: 1,
          borderColor: '#008080',
          backgroundColor: 'white'

        DIV
          style: 
            borderBottom: if get_tabs() then "1px solid " + active_style.borderColor

          DIV
            style:
              width: HOMEPAGE_WIDTH()
              margin: 'auto'

            HomepageTabs
              tab_style: _.defaults {}, opts.tab_style or {},
                padding: '10px 30px 0px 30px',
                color: '#008080',
                border: '1px solid',
                borderBottom: 'none',
                borderColor: 'transparent',
                fontSize: 18,
                fontWeight: 700,
                opacity: 0.3
              
              tab_wrapper_style: _.defaults {}, opts.tab_wrapper_style or {},
                backgroundColor: opts.tab_background_color
              active_style: active_style
              active_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
                backgroundColor: opts.tab_background_color
              wrapper_style: _.defaults {}, opts.tabs_wrapper_style or {}
              list_style: opts.tabs_list_style or {}

