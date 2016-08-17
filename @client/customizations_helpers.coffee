window.passes_tags = (user, tags) -> 
  if typeof(tags) == 'string'
    tags = [tags]
  user = fetch(user)

  passes = true 
  for tag in tags 
    passes &&= user.tags[tag] && \
     !(user.tags[tag].toLowerCase() in ['no', 'false'])
  passes 

window.passes_tag_filter = (user, tag, regex) -> 
  user = fetch(user)
  passes = true 
  for tag, value of user.tags   
    passes ||= tag.match(regex) && !(value.toLowerCase() in ['no', 'false'])
  passes


window.cluster_link = (href, anchor) ->
  anchor ||= href 
  "<a href='#{href}' target='_blank' style='text-decoration:underline'>#{anchor}</a>"




#################
# PRO/CON LABELS

window.point_labels = 
  pro_con: 
    pro: 'pro'
    pros: 'pros' 
    con: 'con'
    cons: 'cons'
    your_header: "Give your --valences--" 
    other_header: "Others' --valences--" 
    top_header: "Top --valences--" 
    your_cons_header: null
    your_pros_header: null

  strengths_weaknesses: 
    pro: 'strength'
    pros: 'strengths' 
    con: 'weakness'
    cons: 'weaknesses'
    your_header: "--valences--" 
    other_header: "--valences-- observed" 
    top_header: "Foremost --valences--" 

  strengths_limitations:
    pro: 'strength'
    pros: 'strengths' 
    con: 'limitation'
    cons: 'limitations'
    your_header: "--valences-- you observed" 
    other_header: "--valences-- observed" 
    top_header: "Foremost --valences--" 


  challenge_justify:
    pro: 'justification'
    pros: 'justifications' 
    con: 'challenge'
    cons: 'challenges'
    your_header: "Give your --valences--" 
    other_header: "--valences-- identified" 
    top_header: "Top --valences--" 


  strengths_improvements: 
    pro: 'strength'
    pros: 'strengths' 
    con: 'improvement'
    cons: 'improvements'
    your_header: "--valences-- you observe" 
    your_cons_header: "Your suggested improvements"
    your_pros_header: "Strengths you observe"
    other_header: "--valences-- identified" 
    top_header: "Top --valences--" 


  support_challenge_claim: 
    pro: 'supporting claim'
    pros: 'supporting claims' 
    con: 'challenging claim'
    cons: 'challenging claims'
    your_header: "--valences-- you recognize" 
    other_header: "--valences-- identified" 
    top_header: "Top --valences--" 


  delta_pluses:
    pro: 'plus'
    pros: 'pluses' 
    con: 'delta'
    cons: 'deltas'
    your_header: "--valences-- you recognize" 
    other_header: "--valences-- identified" 
    top_header: "Top --valences--" 


#####################
# SLIDER POLE LABELS

window.slider_labels = 

  agree_disagree:
    support: 'Agree'
    oppose: 'Disagree'

    slider_feedback: (value, proposal) -> 
      if Math.abs(value) < 0.05
        "You are undecided"
      else 
        degree = Math.abs value
        strength_of_opinion = if degree > .999
                                "Fully "
                              else if degree > .5
                                "Firmly "
                              else
                                "Slightly " 

        valence = customization "slider_pole_labels." + \
                                (if value > 0 then 'support' else 'oppose'), \
                                proposal

        "You #{strength_of_opinion} #{valence}"

  support_oppose:
    support: 'Support'
    oppose: 'Oppose'

    slider_feedback: (value, proposal) -> 
      if Math.abs(value) < 0.05
        "You are undecided"
      else 
        degree = Math.abs value
        strength_of_opinion = if degree > .999
                                "Fully "
                              else if degree > .5
                                "Firmly "
                              else
                                "Slightly " 

        valence = customization "slider_pole_labels." + \
                                (if value > 0 then 'support' else 'oppose'), \
                                proposal

        "You #{strength_of_opinion} #{valence}"


  relevance:
    support: 'Big impact!'
    oppose: 'No impact on me'    

  priority:
    support: 'High Priority'
    oppose: 'Low Priority'    

  interested:
    support: 'Interested'
    oppose: 'Uninterested'    

  important_unimportant:
    support: 'Important'
    oppose: 'Unimportant'    


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
window.ShortHeader = (opts) -> -> 
  subdomain = fetch '/subdomain'   
  loc = fetch 'location'

  return SPAN null if !subdomain.name

  homepage = loc.url == '/'

  opts ||= {}
  _.defaults opts, 
    background_color: subdomain.branding.primary_color
    text: if !subdomain.branding.logo then subdomain.branding.masthead_header_text or subdomain.app_title
    external_link: subdomain.external_project_url
    logo_src: subdomain.branding.logo
    logo_height: 56

  hsl = parseCssHsl(opts.background_color)
  is_light = hsl.l > .75


  DIV 
    style:
      backgroundColor: opts.background_color

    DIV
      style: 
        width: HOMEPAGE_WIDTH() # + 130
        margin: 'auto'
        
        position: 'relative'
        padding: '8px 0'
        # display: 'flex'
        # flexDirection: 'column'
        # justifyContent: 'center'

      TABLE 
        style: 
          position: 'relative'
          left: if !homepage then -65 + 18
          minHeight: 60
        TR null,
          if !homepage
            TD 
              style: 
                paddingRight: 18
                verticalAlign: 'middle'
              back_to_homepage_button
                color: if !is_light then 'white'
                

          if opts.logo_src
            TD 
              style: 
                paddingRight: 20
                verticalAlign: 'middle'
              A 
                href: if !homepage then '/' else opts.external_link
                style: 
                  fontSize: 0
                  cursor: if !homepage && !opts.external_link then 'default'

                IMG 
                  src: opts.logo_src
                  style: 
                    height: opts.logo_height

          if opts.text
            TD 
              style: 
                color: if !is_light then 'white'
                marginLeft: if opts.logo_src then 35
                fontSize: 32
                fontWeight: 400
                # display: 'inline-block'
                verticalAlign: 'middle'
                marginTop: 5

              opts.text


# The old image banner + optional text description below
window.LegacyImageHeader = (opts) -> -> 
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
      DIV style: {color: 'white', margin: 'auto', fontSize: 60, fontWeight: 700, position: 'relative', top: 50}, 
        opts.text


window.HawaiiHeader = (opts) -> ->

  homepage = fetch('location').url == '/'
  subdomain = fetch '/subdomain'

  background_color = opts.background_color or (if subdomain.branding.primary_color && subdomain.branding.primary_color != '' then subdomain.branding.primary_color) or '#000'
  hsl = parseCssHsl(opts.background_color)
  is_light = hsl.l > .75

  opts ||= {}
  _.defaults opts, 
    background_color: background_color
    background_image_url: subdomain.branding.masthead
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
          src: opts.logo
          style: 
            width: opts.logo_width
            display: 'block'
            margin: 'auto'
            paddingTop: 20


      SPAN 
        style: opts.title_style
        opts.title 

      if homepage && opts.subtitle

        DIV
          style: opts.subtitle_style
          
          opts.subtitle         

      if homepage && customization('homepage_tabs')
        DIV 
          style: 
            position: 'relative'
            margin: '62px auto 0 auto'
            width: HOMEPAGE_WIDTH()
            

          HomepageTabs
            tab_style: opts.tab_style



window.SeattleHeader = (opts) -> -> 

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

  external_link_style = _.defaults opts.external_link_style, 
    display: 'block'
    position: 'absolute'
    top: 22
    left: 20
    color: "#0B4D92"

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

            DIV  
              style:
                paddingLeft: '70%'
                paddingTop: 10
              "– #{opts.quote.who}"

        DIV null,

          for section in opts.sections 

            DIV 
              style: 
                marginBottom: 20                


              if section.label 
                DIV
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
                  style: 
                    height: 70
              else
                opts.from 

            if opts.salutation.after 
              DIV 
                style: _.extend {}, paragraph_style,
                  margin: 0
                dangerouslySetInnerHTML: { __html: opts.salutation.after }
                


        if opts.closed 
          DIV 
            style: 
              marginTop: 40
              backgroundColor: seattle_vars.pink
              color: 'white'
              fontSize: 28
              textAlign: 'center'
              padding: "30px 42px"

            "The comment period is now closed. Thank you for your input!"





#####################
# SUBDOMAIN VARIABLES

window.seattle_vars = 
  teal: "#0FB09A"
  turquoise: '#67B5B5'
  brown: '#A77C53'
  gray: "#444"
  pink: '#F06668'
  dark: '#5C1517'

  section_description: 
    fontSize: 18
    fontWeight: 400 
    color: '#444'

window.dao_vars = 
  blue: '#348AC7'
  red: '#F83E34'
  purple: '#7474BF'
  yellow: '#F8E71C'


window.bitcoin_filters = [ {
    label: 'users'
    tooltip: 'User sent in verification image.'
    pass: (user) -> passes_tags(user, 'verified')
    icon: "<span style='color:green'>\u2713 verified</span>"

  }, {
    label: 'miners'
    tooltip: 'Controls > 1% hashrate.'
    pass: (user) -> passes_tags(user, ['bitcoin_large_miner', 'verified'])
    icon: "<span style=''>\u26CF miner</span>"      
  }, {
    label: 'developers'
    tooltip: 'Self reported in user profile.'
    pass: (user) -> passes_tags(user, ['bitcoin_developer.editable', 'verified'])
    icon: "<span style=''><img src='https://dl.dropboxusercontent.com/u/3403211/dev.png' style='width:20px' /> developer</span>"            
  },{
    label: 'businesses'
    tooltip: 'Self reported in user profile'
    pass: (user) -> passes_tags(user, ['bitcoin_business.editable', 'verified'])
    icon: (user) -> "<span style=''>operates: #{fetch(user).tags['bitcoin_business.editable']}</span>"            

  }
]

window.bitcoin_auth =   [
    {
      tag: 'bitcoin_developer.editable'
      question: 'Others consider me a bitcoin developer'
      input: 'dropdown'
      options:['No', 'Yes']
      required: false
    },{
      tag: 'bitcoin_business.editable'
      question: 'I operate these bitcoin businesses (urls)'
      input: 'text'
      required: false
    }
  ]


