require './color'
require './logo'

#######################
# Customizations.coffee
#
# Tailor considerit applications by subdomain

window.customizations = {}
window._ = _


#######
# API
#
# The customization method returns the proper value of the field for this 
# subdomain, or the default value if it hasn't been defined for the subdomain.
#
# Nested customizations can be fetched with . notation, by passing e.g. 
# "auth.use_footer" or with a bracket, like "auth.use_footer['on good days']"
#
# object_or_key is optional. If passed, customization will additionally check for 
# special configs for that object (object.key) or key.


db_customization_loaded = {}


window.load_customization = (subdomain_name, obj) ->

  db_customization_loaded[subdomain_name] = obj

  try 
    new Function(obj)() # will create window.customization_obj
    customizations[subdomain_name] ||= {}
    _.extend customizations[subdomain_name], window.customization_obj
  catch error 
    console.error error


window.customization = (field, object_or_key) -> 
  
  if !!object_or_key && !object_or_key.key?
    object_or_key = fetch object_or_key

  if object_or_key && object_or_key.subdomain_id
    subdomain = fetch "/subdomain/#{object_or_key.subdomain_id}" 
  else 
    subdomain = fetch('/subdomain')

  subdomain_name = subdomain.name?.toLowerCase()
  
  if subdomain.customization_obj? && subdomain.customization_obj != db_customization_loaded[subdomain_name]
    load_customization subdomain_name, subdomain.customization_obj


  key = if object_or_key 
          if object_or_key.key then object_or_key.key else object_or_key
        else 
          null


  ########
  # The chain of customizations: 
  #  1) any object-specific configuration
  #  2) subdomain configuration
  #  3) global default configuration

  chain_of_configs = []

  if customizations[subdomain_name]?

    subdomain_config = customizations[subdomain_name]

    # object-specific config
    if key 

      if subdomain_config[key]?
        chain_of_configs.push subdomain_config[key]

      # cluster-level config for proposals
      if key.match(/\/proposal\//)
        proposal = object_or_key
        cluster_key = "list/#{proposal.cluster}"
        if subdomain_config[cluster_key]?
          chain_of_configs.push subdomain_config[cluster_key]

    # subdomain config
    chain_of_configs.push subdomain_config

  # language defaults 
  chain_of_configs.push customizations.lang_default[(subdomain.lang or 'en')]
  
  # global default config
  chain_of_configs.push customizations['default']

  value = undefined
  for config in chain_of_configs
    value = customization_value(field, config)

    break if value?

  # if !value?
  #   console.error "Could not find a value for #{field} #{if key then key else ''}"

  value


# Checks to see if this configuration is defined for a customization field
customization_value = (field, config) -> 
  val = config

  fields = field.split('.')

  for f, idx in fields

    if f.indexOf('[') > 0
      brackets = f.match(/\[(.*?)\]/g)
      f = f.substring(0, f.indexOf('['))

    if val[f]? || idx == fields.length - 1        
      val = val[f]

      if brackets?.length > 0
        for b in brackets
          f = b.substring(2,b.length - 2)
          if val? && val[f]?
            val = val[f]

          else
            return undefined

    else 
      return undefined

  val



require './browser_location' # for loadPage
require './shared'
require './footer'
require './slider'
require './header'
require './homepage'
require './customizations_helpers'





################################
# DEFAULT CUSTOMIZATIONS


customizations.default = 

  # Proposal options
  discussion_enabled: true

  homepage_show_search_and_sort: false

  list_show_new_button: true
  homepage_show_new_proposal_button: true

  show_crafting_page_first: false

  show_histogram_on_crafting: true

  show_proposal_meta_data: true 

  slider_handle: slider_handle.face
  slider_regions: null

  show_proposal_scores: true

  show_proposer_icon: false
  collapse_proposal_description_at: false

  # default cluster options
  list_is_archived: false

  # Other options
  auth_footer: false
  auth_require_pledge: false
  has_homepage: true

  homepage_list_order: []
  homepage_lists_to_always_show: []


  auth_questions: []

  SiteHeader : ShortHeader()
  SiteFooter : DefaultFooter


customizations.lang_default = 
  en: 
    homepage_show_search_and_sort: true
    point_labels : point_labels.pro_con
    slider_pole_labels : slider_labels.agree_disagree
    list_opinions_title: 'Opinions'

  spa: 
    point_labels : 
      pro: 'pro'
      pros: 'pros' 
      con: 'contra'
      cons: 'contras'
      your_header: "Ingresa tus --valences--" 
      other_header: "Otros --valences--" 
      top_header: "Top --valences--" 

    slider_pole_labels : 
      support: 'Acuerdo'
      oppose: 'Desacuerdo'

    list_opinions_title: "Opiniones"

  french: 
    point_labels : 
      pro: 'pour' 
      pros: 'pour' 
      con: 'contre' 
      cons: 'contre'
      your_header: "Donner votre --valences--" 
      other_header: "Les --valences-- des autres" 
      top_header: "Meilleures --valences--" 

    slider_pole_labels : 
      support: 'd’accord' 
      oppose: 'pas d’accord' 

    list_opinions_title: "Des avis"

  tun_ar: 
    show_proposal_meta_data: false
    slider_pole_labels: 
      support: 'أوافق'
      oppose: 'أخالف'

    list_opinions_title: 'الآراء'
    point_labels:  
      pro: 'نقطة إجابية'
      pros: 'نقاط إجابية' 
      con: 'نقطة سلبية'
      cons: 'نقاط سلبية'
      your_header: "--valences-- أبد" 
      other_header: "--valences--  أخرى" 
      top_header: "--valences--  الرئيسية" 

  ptbr: 
    point_labels : 
      pro: 'A Favor'
      pros: 'A Favor' 
      con: 'Contra'
      cons: 'Contra'
      your_header: "Teus pontos --valences--" 
      other_header: "Outros --valences--" 
      top_header: "Top --valences--" 

    slider_pole_labels : 
      support: 'Concordo'
      oppose: 'Discordo'

    list_opinions_title: "Opiniões"




##########################
# SUBDOMAIN CONFIGURATIONS


customizations.homepage = 
  homepage_default_sort_order: 'trending'



text_and_masthead = ['educacion2025', 'ynpn', 'lsfyl', 'kealaiwikuamoo', 'iwikuamoo']
masthead_only = ["kamakakoi","seattletimes","kevin","ihub","SilverLakeNC",\
                 "Relief-Demo","GS-Demo","ri","ITFeedback","Committee-Meeting","policyninja", \
                 "SocialSecurityWorks","amberoon","economist","impacthub-demo","mos","Cattaca", \
                 "Airbdsm","fun","bitcoin-ukraine","lyftoff","hcao","arlingtoncountyfair","progressive", \
                 "design","crm","safenetwork","librofm","washingtonpost","MSNBC", \
                 "PublicForum","AMA-RFS","AmySchumer","VillaGB","AwesomeHenri", \
                 "citySENS","alcala","MovilidadCDMX","deus_ex","neuwrite","bitesizebio","HowScienceIsMade","SABF", \
                 "engagedpublic","sabfteam","Tunisia","theartofco","SGU","radiolab","ThisLand", \
                 "Actuality"]


for sub in text_and_masthead
  customizations[sub.toLowerCase()] = 
    HomepageHeader: LegacyImageHeader()

for sub in masthead_only
  customizations[sub.toLowerCase()] = 
    HomepageHeader: LegacyImageHeader()








##############
# ECAST

customizations.ecastonline = 
  show_crafting_page_first: true

  auth_footer: """
    The demographic data collected from participants in this project will be used for research purposes, for 
    example, to identify the demographic and other characteristics of the people who participated in the 
    deliberation.  This information can be used in analyzing the results of this online forum.  
    No email addresses, demographic data, or personally-identifying information will be displayed to 
    other visitors to this site.  Any comments you submit will be identified only by the display name 
    you enter below.  By completing this registration, you acknowledge that your participation in this 
    project is entirely voluntary and you agree that the data provided may be used for research. If you 
    have any questions or concerns at any time, please 
    <a href='mailto:info@ecastonline.org' target='_blank' style="text-decoration:underline">Contact us</a>.
    """

  auth_questions : [
    { 
      tag: 'zip.editable'
      question: 'My zip code is'
      input: 'text'
      # required: true
      input_style: 
        width: 85
      validation: (zip) ->
        return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
    }, {
      tag: 'gender.editable'
      question: 'My gender is'
      input: 'dropdown'
      options:['Male', 'Female']
      # required: true
    }, {
      tag: 'age.editable'
      question: 'My age is'
      input: 'text'
      # required: true
      input_style: 
        width: 50
      validation: (age) -> 
        return /^[1-9]?[0-9]{1}$|^100$/.test(age)
    }, {
      tag: 'ethnicity.editable'
      question: 'My ethnicity is'
      input: 'dropdown'
      options:['African American', 'Asian', 'Latino/Hispanic', 'White', 'Other']
      # required: true
    }, {
      tag: 'education.editable'
      question: 'My formal education is'
      input: 'dropdown'
      options:['Did not graduate from high school', \
               'Graduated from high school or equivalent', \
               'Attended, but did not graduate from college', \
               'College degree', \
               'Graduate professional degree']
      # required: true
    }]

  list_opinions_title: "Citizens' opinions"


  HomepageHeader: ->
    ecast_highlight_color =  "#73B3B9"

    paragraph_style = 
      marginBottom: 20
      textShadow: '0 1px 1px rgba(255,255,255,.5)'
      fontWeight: 600

    DIV 
      style: 
        backgroundColor: 'black'
        height: 685
        overflow: 'hidden'
        width: '100%'
        position: 'relative'
        borderBottom: "5px solid #{ecast_highlight_color}"

      IMG 
        style: 
          position: 'absolute'
          width: 1300
        src: asset('ecast/bg-small.png')

      # Title of site
      DIV 
        style: 
          position: 'absolute'
          left: 50
          top: 38

        DIV 
          style: 
            fontSize: 42
            fontWeight: 600
            color: 'white'
            textShadow: '0 2px 4px rgba(0,0,0,.5)'

          A 
            href: '/'
            "Informing NASA's Asteroid Initiative"

        DIV
          style: 
            fontSize: 24
            fontWeight: 600         
            color: 'white'
            textAlign: 'center'
            marginTop: -5

          A
            href: '/'
            "A Citizen Forum"

      # Credits
      DIV 
        style:
          position: 'absolute'
          top: 61
          left: 790

        DIV 
          style: 
            fontSize: 18
            color: 'white'
          'hosted by'

        A 
          href: "http://ecastonline.org/"
          target: '_blank'
          IMG 
            style: 
              display: 'block'
              marginTop: 4
              width: 215
            src: asset('ecast/ecast-small.png')

        # DIV 
        #   style: 
        #     fontSize: 18
        #     color: 'white'
        #     marginTop: 12              
        #   'supported by'

        # A 
        #   href: "http://www.nasa.gov/"
        #   target: '_blank'

        #   IMG 
        #     style: 
        #       display: 'block'
        #       marginTop: 4
        #       width: 160

        #     src: asset('ecast/nasa.png')

      # Video callout
      DIV
        style: 
          position: 'absolute'
          left: 434
          top: 609
          color: ecast_highlight_color
          fontSize: 17
          fontWeight: 600
          width: 325

        I 
          className: 'fa fa-film'
          style: 
            position: 'absolute'
            left: -27
            top: 3
        'Learn more first! Watch this video from the public forums that ECAST hosted.'

        SPAN
          style: 
            position: 'absolute'
            top: 24
            right: -15

          I
            className: 'fa fa-angle-right'
            style: 
              paddingLeft: 10
          I
            className: 'fa fa-angle-right'
            style: 
              paddingLeft: 5
          I
            className: 'fa fa-angle-right'
            style: 
              paddingLeft: 5


      # Video
      IFRAME
        position: 'absolute'
        type: "text/html" 
        width: 370
        height: 220
        src: "//www.youtube.com/embed/6yImAjIws9A?autoplay=0"
        frameborder: 0
        style:
          top: 460
          left: 790
          zIndex: 99
          position: 'absolute'
          border: "5px solid #{ecast_highlight_color}"
          borderBottom: 'none'


      # Text in bubble
      DIV 
        style: 
          fontSize: 17
          position: 'absolute'
          top: 156
          left: 97
          width: 600

        P style: paragraph_style, 
          """In its history, the Earth has been repeatedly struck by asteroids, 
             large chunks of rock from space that can cause considerable damage 
             in a collision. Can we—or should we—try to protect Earth from 
             potentially hazardous impacts?"""

        P style: paragraph_style, 
          """Sounds like stuff just for rocket scientists. But how would you like 
             to be part of this discussion?"""

        P style: paragraph_style, 
          """Now you can! NASA is collaborating with ECAST—Expert and Citizen 
             Assessment of Science and Technology—to give citizens a say in 
             decisions about the future of space exploration."""

        P style: paragraph_style, 
          """Join the dialogue below about detecting asteroids and mitigating their 
             potential impact. The five recommendations below emerged from ECAST 
             public forums held in Phoenix and Boston last November."""

        P style: paragraph_style, 
          """Please take a few moments to review the background materials and the 
             recommendations, and tell us what you think! Your input is important 
             as we analyze the outcomes of the forums and make our final report 
             to NASA."""



















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










customizations['on-chain-conf'] = _.extend {}, 
  opinion_filters: bitcoin_filters
  auth_questions: bitcoin_auth
  show_proposer_icon: false
  collapse_proposal_description_at: 300
  show_proposal_meta_data: false 

  homepage_show_search_and_sort: true
  auth_require_pledge: true

  slider_pole_labels: slider_labels.interested

  homepage_list_order: ['Events', 'On-chain scaling', 'Other topics']

  SiteHeader: ->
    homepage = fetch('location').url == '/'

    DIV
      style:
        position: 'relative'
        backgroundColor: '#272727'
        overflow: 'hidden'
        paddingBottom: 60
        height: if !homepage then 200

      onMouseEnter: => @local.hover=true;  save(@local)
      onMouseLeave: => @local.hover=false; save(@local)

      STYLE null,
        '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
           p {margin-bottom: 1em}'''

      # The top bar with the logo
      DIV
        style:
          #width: HOMEPAGE_WIDTH()
          margin: 'auto'
          textAlign: 'center'

        DIV 
          style: 
            margin: "60px auto 160px auto"
            width: '80%'
            position: 'relative'
            zIndex: 3

          IMG
            style: 
              display: 'inline-block'
              width: '90%'
            src: asset('bitcoin/OnChainConferences3.svg')


        DIV 
          style: 
            position: 'absolute'
            left: 0
            top: 0
            height: if homepage then '64%' else '100%'
            width: '100%'
            background: if homepage then 'linear-gradient(to bottom, rgba(0,0,0,.97) 0%,rgba(0,0,0,0.65) 70%,rgba(0,0,0,0) 100%)' else 'rgba(0,0,0,.7)'
            zIndex: 2

        IMG 
          style: 
            position: 'absolute'
            zIndex: 1
            width: '160%'
            top: 0 #45
            left: '-30%'
          src: asset('bitcoin/rays.png') 


        DIV 
          style: 
            marginLeft: 50
            paddingTop: 13
            position: 'absolute'
            zIndex: 3
            top: 65
            
          back_to_homepage_button
            display: 'inline-block'
            color: 'white'
            position: 'relative'
            left: -60
            top: -10
            fontWeight: 400
            paddingLeft: 25 # Make the clickable target bigger
            paddingRight: 25 # Make the clickable target bigger
            cursor: if not homepage then 'pointer'

        if homepage 
          DIV 
            style:
              backgroundColor: 'rgba(0,0,0,.7)'
              color: 'white'
              textAlign: 'center'
              padding: '20px 0'
              width: '100%'
              position: 'relative' 
              zIndex: 3
              top: 60

            DIV 
              style: 
                fontWeight: 600
                fontSize: 20

              'Visit '

              A 
                style: 
                  textDecoration: 'underline'
                href: 'http://onchainscaling.com/'

                'onchainscaling.com'
              ' to see the recorded presentations from the first conference.'

            DIV 
              style:
                fontSize: 18

              'Express your preferences below for future event presentations. '



customizations.bitcoinclassic = _.extend {}, 
  opinion_filters: bitcoin_filters
  auth_questions: bitcoin_auth
  show_proposer_icon: false
  collapse_proposal_description_at: 300

  homepage_show_search_and_sort: true

  auth_require_pledge: true

  'list/Scrapped proposals': 
    list_is_archived: true

  'list/Closed pull requests': 
    list_is_archived: true


  SiteHeader: ->
    homepage = fetch('location').url == '/'

    DIV
      style:
        position: 'relative'
        backgroundColor: 'white'
        paddingBottom: 20
        # height: 63
        # borderBottom: '1px solid #ddd'
        # boxShadow: '0 1px 2px rgba(0,0,0,.1)'

      onMouseEnter: => @local.hover=true;  save(@local)
      onMouseLeave: => @local.hover=false; save(@local)

      STYLE null,
        '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
           p {margin-bottom: 1em}'''

      # The top bar with the logo
      DIV
        style:
          width: HOMEPAGE_WIDTH()
          margin: 'auto'

        DIV 
          style: 
            marginLeft: -70
            paddingTop: 30


          back_to_homepage_button              
            display: 'inline-block'
            color: '#eee'
            position: 'relative'
            left: -60
            top: -10
            fontWeight: 400
            paddingLeft: 25 # Make the clickable target bigger
            paddingRight: 25 # Make the clickable target bigger
            cursor: if not homepage then 'pointer'

          # Logo
          A
            href: if homepage then 'https://bitcoinclassic.com' else '/'


            IMG
              style:
                height: 51
                marginLeft: -50

              src: asset('bitcoin/bitcoinclassiclogo.png')

          BR null
          if homepage 

            SPAN
              style: 
                marginLeft: 69
                position: 'relative'
                marginTop: 5
                marginBottom: 10
                top: -4
                #backgroundColor: '#F69332'
                padding: '3px 6px'
                fontSize: 20
                fontStyle: 'italic'
                fontWeight: 700
                color: '#bbb'

              "Propose and deliberate ideas for Bitcoin Classic. Not yet for binding votes."


        if homepage
          DIV null, 
            DIV 
              style: 
                marginTop: 10
                padding: 8
                fontSize: 18

              "Classic is using consider.it to sample community opinion to better understand what users really 
               think about bitcoin and want to see it become. The governance model that Classic eventually 
               adopts may include opinions collected from this site, but Classic has not committed itself 
               to making decisions based only on the preferences expressed here or elsewhere."
              " "
              "Please vet proposals on "
              A 
                href: "https://www.reddit.com/r/Bitcoin_Classic/"
                target: '_blank'
                style: 
                  borderBottom: "1px solid #bbb"
                  #textDecoration: 'underline'

                "Reddit"
              " or "
              A 
                href: "http://invite.bitcoinclassic.com/"
                target: '_blank'
                style: 
                  borderBottom: "1px solid #bbb"
                  #textDecoration: 'underline'

                "Slack"
              " first. "

              "Other "               
              A 
                href: 'https://www.reddit.com/r/Bitcoin_Classic/comments/40u3ws/considerit_voting_guide/'
                target: '_blank'
                style: 
                  borderBottom: "1px solid #bbb"
                  #textDecoration: 'underline'

                "guidelines"
              "."
            DIV 
              style: 
                #backgroundColor: '#eee'
                marginTop: 10
                padding: 8
                fontSize: 18

              "Some users have abused open registration. Filtering opinions to verified users has been enabled by default."
              " "

            DIV 
              style: 
                backgroundColor: '#eee'
                marginTop: 10
                padding: 8
                fontSize: 18

              "Interested in running a node that mirrors consider.it data to provide an audit trail? "

              A 
                href: 'https://www.reddit.com/r/Bitcoin_Classic/comments/435gi1/distributed_publicly_auditable_data_for/'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                "Learn more"
















