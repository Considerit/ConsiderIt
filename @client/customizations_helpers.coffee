window.passes_tags = (user, tags) -> 
  if typeof(tags) == 'string'
    tags = [tags]
  user = fetch(user)

  passes = true 
  for tag in tags 
    passes &&= user?.tags?[tag] && \
     !("#{user?.tags?[tag]}".toLowerCase() in ['no', 'false'])
  passes 

window.passes_tag_filter = (user, tag, regex) -> 
  user = fetch(user)
  user?.tags?[tag]?.match(regex) 
  

window.cluster_link = (href, anchor) ->
  anchor ||= href 
  "<a href='#{href}' target='_blank' style='font-weight: 600; text-decoration:underline'>#{anchor}</a>"




#################
# PRO/CON LABELS

window.point_labels = 

  pro_con: 
    translate: true
    pro: 'pro'
    pros: 'pros' 
    con: 'con'
    cons: 'cons'
    your_header: "Give your {arguments}" 
    other_header: "Others' {arguments}" 
    top_header: "Top {arguments}" 
    your_cons_header: null
    your_pros_header: null

  strengths_weaknesses: 
    translate: true    
    pro: 'strength'
    pros: 'strengths' 
    con: 'weakness'
    cons: 'weaknesses'
    your_header: "{arguments}" 
    other_header: "{arguments} observed" 
    top_header: "Top {arguments}" 


window.get_point_label = (id, proposal) -> 
  prop = id.split('.')?[1] or id

  if proposal
    conf = customization('point_labels', proposal)
  else 
    conf = customization('point_labels')

  val = conf[prop]

  if !val 
    ""
  else
    if conf.translate
      translator "point_labels.#{val}", val 
    else 
      translator 
        id: "point_labels.#{val}"
        key: "/translations/#{fetch('/subdomain').name}"
        val 


#####################
# SLIDER POLE LABELS

window.get_slider_label = (id, proposal) -> 
  side = id.split('.')?[1] or id

  if proposal
    conf = customization('slider_pole_labels', proposal)
  else 
    conf = customization('slider_pole_labels')

  label = conf[side]
  if !label 
    ""
  else
    if conf.translate
      translator "sliders.pole.#{label}", label 
    else 
      translator 
        id: "sliders.pole.#{label}"
        key: "/translations/#{fetch('/subdomain').name}"
        label 


fully_firmly_slightly_scale = (value, proposal) ->

  if Math.abs(value) < 0.02
    translator
      id: "sliders.feedback.neutral"
      "You are neutral"
  else 
    valence = get_slider_label (if value > 0 then 'support' else 'oppose'), proposal

    degree = Math.abs value
    strength_of_opinion = if degree > .999
                            "Fully"
                          else if degree > .5
                            "Firmly"
                          else
                            "Slightly" 
    
    translator
      id: "sliders.feedback.#{strength_of_opinion}"
      strength_of_opinion: strength_of_opinion
      valence: valence
      "You #{strength_of_opinion} {valence}"


window.slider_labels = 

  agree_disagree:
    translate: true
    support: 'Agree'
    oppose: 'Disagree'

    slider_feedback: fully_firmly_slightly_scale

  support_oppose:
    translate: true    
    support: 'Support'
    oppose: 'Oppose'

    slider_feedback: fully_firmly_slightly_scale

  priority:
    translate: true    
    support: 'High Priority'
    oppose: 'Low Priority'    

  important_unimportant:
    translate: true    
    support: 'Important'
    oppose: 'Unimportant'    

  relevance:
    support: 'Big impact!'
    oppose: 'No impact on me'    

  interested:
    support: 'Interested'
    oppose: 'Uninterested'    



  yes_no:
    support: 'Yes'
    oppose: 'No'    

  strong_weak:
    support: 'Strong'
    oppose: 'Weak'    

  promising_weak:
    support: 'Promising'
    oppose: 'Weak'    


  ready_not_ready:
    support: 'Ready'
    oppose: 'Not ready'

  plus_minus:
    support: '+'
    oppose: '–'

  effective_ineffective:
    support: 'Effective'
    oppose: 'Ineffective'




##########################
# RANDOM COMPONENTS

window.ExpandableSection = ReactiveComponent
  displayName: 'ExpandableSection'

  render: -> 
    label = @props.label
    text = @props.text 

    expanded = @local.expanded 

    symbol = if expanded then 'fa-chevron-down' else 'fa-chevron-right'

    DIV null,
        

      DIV 
        onClick: => @local.expanded = !@local.expanded; save(@local)

        style: 
          fontWeight: 600
          color: @props.text_color or 'black'
          cursor: 'pointer'
          marginTop: 12
          fontSize: 22

        SPAN 
          className: "fa #{symbol}"
          style: 
            opacity: .7
            position: 'relative'
            left: -3
            paddingRight: 6
            display: 'inline-block'
            width: 20


        SPAN 
          style: {}

          label 

      if expanded 
        text 


###########################
# HOMEPAGE HEADER TEMPLATES


# A small header with text and optionally a logo
window.ShortHeader = (opts) ->
  subdomain = fetch '/subdomain'   
  loc = fetch 'location'

  return SPAN null if !subdomain.name

  homepage = loc.url == '/'

  opts ||= {}
  _.defaults opts, (customization('forum_header') or {}),
    background: customization('background') or subdomain.branding.primary_color
    text: customization('prompt') or subdomain.branding.masthead_header_text or subdomain.app_title
    external_link: subdomain.external_project_url
    logo_src: subdomain.branding.logo
    logo_height: 50
    min_height: 70
    padding: '8px 0'
    padding_left_icon: 20

  hsl = parseCssHsl(opts.background)
  is_light = hsl.l > .75


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
              color: if !is_light && !opts.logo_src then 'white'
              fontSize: 18
              fontWeight: 600
              display: 'inline'

            , TRANSLATE("engage.navigate_back_to_homepage" , 'homepage')


      if opts.text
        H2 
          style: 
            color: if !is_light then 'white'
            marginLeft: if opts.logo_src then 35
            paddingRight: 90
            fontSize: 32
            fontWeight: 400

          opts.text


# The old image banner + optional text description below
window.LegacyImageHeader = (opts) ->
  subdomain = fetch '/subdomain'   
  loc = fetch 'location'    
  homepage = loc.url == '/'

  return SPAN null if !subdomain.name

  opts ||= {}
  _.defaults opts, 
    background_color: subdomain.branding.primary_color
    background_image_url: subdomain.branding.masthead
    text: subdomain.branding.masthead_header_text
    external_link: subdomain.external_project_url

  if !opts.background_image_url
    throw 'LegacyImageHeader can\'t be used without a branding masthead'

  hsl = parseCssHsl(opts.background_color)
  is_light = hsl.l > .75
    
  DIV null,

    IMG 
      alt: opts.background_image_alternative_text
      src: opts.background_image_url
      style: 
        width: '100%'

    if homepage && opts.external_link 
      A
        href: opts.external_link
        style: 
          display: 'block'
          position: 'absolute'
          left: 10
          top: 17
          color: if !is_light then 'white'
          fontSize: 18

        '< project homepage'

    else 
      back_to_homepage_button
        position: 'relative'
        marginLeft: 20
        display: 'inline-block'
        color: if !is_light then 'white'
        verticalAlign: 'middle'
        marginTop: 5

     
    if opts.text
      H1 style: {color: 'white', margin: 'auto', fontSize: 60, fontWeight: 700, position: 'relative', top: 50}, 
        opts.text


window.HawaiiHeader = (opts) ->

  homepage = fetch('location').url == '/'
  subdomain = fetch '/subdomain'

  background_color = opts.background_color or (if subdomain.branding.primary_color && subdomain.branding.primary_color != '' then subdomain.branding.primary_color) or '#000'
  hsl = parseCssHsl(opts.background_color or "#ffffff")
  is_light = hsl.l > .75

  opts ||= {}
  _.defaults opts, 
    background_color: background_color
    background_image_url: opts.background_image_url or subdomain.branding.masthead
    logo: subdomain.branding.logo
    logo_width: 200
    title: '<title is required>'
    subtitle: null
    title_style: {}
    subtitle_style: {}
    tab_style: {}
    homepage_button_style: {}

  _.defaults opts.title_style,
    fontSize: 47
    color: if is_light then 'black' else 'white'
    fontWeight: 300
    display: 'inline-block'

  _.defaults opts.subtitle_style,
    position: 'relative'
    fontSize: 22
    color: if is_light then 'black' else 'white'
    marginTop: 0
    opacity: .7
    textAlign: 'center'  

  _.defaults opts.homepage_button_style,
    display: 'inline-block'
    color: if is_light then 'black' else 'white'
    # opacity: .7
    position: 'absolute'
    left: -80
    fontSize: opts.title_style.fontSize
    #top: 38
    fontWeight: 400
    paddingLeft: 25 # Make the clickable target bigger
    paddingRight: 25 # Make the clickable target bigger
    cursor: if fetch('location').url != '/' then 'pointer'


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

      if homepage && customization('homepage_tabs')
        DIV 
          style: 
            position: 'relative'
            margin: '62px auto 0 auto'
            width: HOMEPAGE_WIDTH()
            

          HomepageTabs
            tab_style: opts.tab_style



window.SeattleHeader = (opts) -> 

  homepage = fetch('location').url == '/'
  subdomain = fetch '/subdomain'

  opts ||= {}
  _.defaults opts, 

    external_link: subdomain.branding.external_project_url

    background_color: '#fff'
    background_image_url: subdomain.branding.masthead

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
    color: 'black'

  external_link_style = _.defaults opts.external_link_style, 
    display: 'block'
    position: 'absolute'
    top: 22
    left: 20
    color: "#0B4D92"


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
              backgroundColor: "#F06668"
              color: 'white'
              fontSize: 28
              textAlign: 'center'
              padding: "30px 42px"

            "The comment period is now closed. Thank you for your input!"


window.PhotoBanner = (opts) -> 
  homepage = fetch('location').url == '/'

  opts ?= {}
  opts.tab_background_color ?= '#666'
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

  DIV null,

    DIV 
      style:
        backgroundImage: opts.backgroundImage 
        backgroundSize: 'cover'
        paddingTop: 140 

      DIV
        style: _.defaults {}, opts.header_style or {},
          padding: '48px 48px 48px 48px'
          width: HOMEPAGE_WIDTH()
          maxWidth: 720
          margin: 'auto'
          backgroundColor: 'rgba(0, 85, 150, .8)'
          color: 'white'
          position: 'relative'
          top: 0 

        DIV
          style: _.defaults {}, opts.header_text_style or {},
            fontSize: 56
            fontWeight: 800
            fontStyle: 'oblique'
            textAlign: 'center'
            paddingBottom: 28
          dangerouslySetInnerHTML: __html: opts.header 

        DIV null, 
          opts.supporting_text?()

      if customization('homepage_tabs')
        HomepageTabs
          tab_style: _.defaults {}, opts.tab_style or {},
            textTransform: 'uppercase'
            fontStyle: 'oblique'
            fontWeight: 600
            fontSize: 20
            padding: '10px 16px 4px'
          tab_wrapper_style: _.defaults {}, opts.tab_wrapper_style or {},
            backgroundColor: opts.tab_background_color # '#005596'
            margin: '0 6px'
          active_style: _.defaults {}, opts.tab_active_style or {},
            backgroundColor: 'white'
            color: 'black'
          active_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
            backgroundColor: opts.tab_background_color
          hovering_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
            backgroundColor: opts.tab_background_color
          wrapper_style: _.defaults {}, opts.tabs_wrapper_style or {},
            marginTop: 80
            top: 0
          list_style: opts.tabs_list_style or {}

