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





customizations['anup2015'] = 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  list_opinions_title: "PC's ratings"

  homepage_list_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']



customizations['random2015'] = _.extend {}, 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  list_opinions_title: "PC's ratings"

  homepage_list_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']


  opinion_value: (o) -> 3 * o.stance,
  "/proposal/2638" : 
    point_labels: point_labels.strengths_limitations
    slider_pole_labels: slider_labels.yes_no
  "/proposal/2639" : 
    point_labels: point_labels.strengths_weaknesses
    slider_pole_labels: slider_labels.yes_no
    
customizations['program-committee-demo'] = 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  list_opinions_title: "PC's ratings"

  homepage_list_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']



#################
# Enviroissues

customizations.enviroissues = 
  show_crafting_page_first: true

  SiteHeader: ->
    loc = fetch 'location'
    homepage = loc.url == '/'

    DIV
      style:
        width: CONTENT_WIDTH()
        margin: '20px auto'
        position: 'relative'

      back_to_homepage_button
        display: 'inline-block'
        verticalAlign: 'top'
        marginTop: 22
        marginRight: 15
        color: '#888'


      IMG
        src: asset('enviroissues/logo.png')



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
      required: true
      input_style: 
        width: 85
      validation: (zip) ->
        return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
    }, {
      tag: 'gender.editable'
      question: 'My gender is'
      input: 'dropdown'
      options:['Male', 'Female']
      required: true
    }, {
      tag: 'age.editable'
      question: 'My age is'
      input: 'text'
      required: true
      input_style: 
        width: 50
      validation: (age) -> 
        return /^[1-9]?[0-9]{1}$|^100$/.test(age)
    }, {
      tag: 'ethnicity.editable'
      question: 'My ethnicity is'
      input: 'dropdown'
      options:['African American', 'Asian', 'Latino/Hispanic', 'White', 'Other']
      required: true
    }, {
      tag: 'education.editable'
      question: 'My formal education is'
      input: 'dropdown'
      options:['Did not graduate from high school', \
               'Graduated from high school or equivalent', \
               'Attended, but did not graduate from college', \
               'College degree', \
               'Graduate professional degree']
      required: true
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








customizations.fidoruk = 
  collapse_proposal_description_at: 300

  auth_require_pledge: true

  show_proposal_scores: false

  opinion_filters: [ 
    {
      label: 'Account holder'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_account_holder')
      icon: "<span style='color:green'>account-holder</span>"

    }, {
      label: 'Community member'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_community_member')
      icon: "<span style='color:blue'>community</span>"      
    },{
      label: 'Business member'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_business_member')
      icon: "<span style='color:orange'>business</span>"      
    }, {
      label: 'Fidor staff'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_staff')
      icon: "<span style='gray'>staff</span>"      
    },     
  ]

  SiteHeader: ->
    subdomain = fetch '/subdomain'   
    loc = fetch 'location'

    hsl = parseCssHsl(subdomain.branding.primary_color)
    is_light = hsl.l > .75

    homepage = loc.url == '/'

    DIV 
      style:
        minHeight: 70


      DIV
        style: 
          width: (if homepage then HOMEPAGE_WIDTH() else BODY_WIDTH() ) + 130
          margin: 'auto'


        back_to_homepage_button
          display: 'inline-block'
          color: if !is_light then 'white'
          verticalAlign: 'middle'
          marginTop: 5


        if subdomain.branding.logo
          A 
            href: if subdomain.external_project_url then subdomain.external_project_url
            style: 
              verticalAlign: 'middle'
              #marginLeft: 35
              display: 'inline-block'
              fontSize: 0
              cursor: if !subdomain.external_project_url then 'default'

            IMG 
              src: subdomain.branding.logo
              style: 
                height: 80

        DIV 
          style: 
            color: if !is_light then 'white'
            marginLeft: 35
            fontSize: 32
            fontWeight: 400
            display: 'inline-block'
            verticalAlign: 'middle'
            marginTop: 5

          if homepage 
            DIV
              style: 
                paddingBottom: 10
                fontSize: 16
                color: '#444'

              "Please first put your proposal into the Fidor Community platform, and link to it in your consider.it proposal.
              This allows us to converse, update our opinions, and track progress over a longer period of time."




bitcoin_filters = [ {
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


bitcoin_auth =   [
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


customizations.bitcoin = 
  show_proposer_icon: true
  collapse_proposal_description_at: 300

  auth_require_pledge: true

  slider_pole_labels: slider_labels.support_oppose

  show_proposal_scores: true

  homepage_list_order: ['Blocksize Survey', 'Proposals']   

  'list/Blocksize Survey': 
    show_crafting_page_first: false

    slider_handle: slider_handle.triangley
    discussion_enabled: false
    show_proposal_scores: false
    slider_pole_labels: 
      support: ''
      oppose: ''

    slider_regions:[{
        label: '1mb', 
        abbrev: '1mb'
      },{
        label: '2mb', 
        abbrev: '2mb'
      },{
        label: '4mb', 
        abbrev: '4mb'
      },{
        label: '8mb', 
        abbrev: '8mb'
      },{
        label: '16mb', 
        abbrev: '16mb'
      }]


  tawkspace: 'https://tawk.space/embedded-space/bitcoin'

  auth_questions : [
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


  opinion_filters: [ {
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






customizations['ynpn'] = 
  homepage_show_search_and_sort: false





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




# customizations['kulahawaiinetwork'] = 
  show_proposer_icon: true
  collapse_proposal_description_at: 300

  homepage_lists_to_always_show: ['Leadership', 'Advocacy & Public Relations', 'Building Kula Resources & Sustainability', \
                           'Cultivating Kumu', 'Relevant Assessments', 'Teacher Resources', \
                           '‘Ōlelo Hawai’i', '3C Readiness'] 

  homepage_tabs: 
    'Advocacy & Public Relations': ['Advocacy & Public Relations']
    'Building Kula Resources & Sustainability': ['Building Kula Resources & Sustainability']
    'Cultivating Kumu': ['Cultivating Kumu']
    'Relevant Assessments': ['Relevant Assessments']
    'Teacher Resources': ['Teacher Resources']
    '‘Ōlelo Hawai’i': ['‘Ōlelo Hawai’i']
    '3C Readiness': ['3C Readiness']
    'Leadership': ['Leadership']


  'list/Advocacy & Public Relations':
    list_items_title: 'Ideas'

    list_label: 'Advocacy & Public Relations'
    list_description: [
      """A space to discuss ideas about two things:
         <ul style='list-style:outside;padding-left:40px'>
           <li>Sharing information and activating kula communities to improve policies 
               related to (1) ʻŌlelo Hawaiʻi, culture, and ʻāina-based education and 
               (2) Positions on issues supported by the network</li>
           <li>Creating and sharing stories of kula and network successes to improve 
               public perceptions and gain support for Hawaiian-focused education & outcomes.</li>
         </ul>
      """
    ]

  'list/Building Kula Resources & Sustainability':
    list_items_title: 'Ideas'
    list_label: 'Building Kula Resources & Sustainability'
    list_description: "A space to discuss ideas around joining efforts across kula to enhance opportunities to increase kula resources and sustainability."


  'list/Cultivating Kumu':
    list_items_title: 'Ideas'
    list_label: 'Cultivating Kumu'
    list_description: [
      """A space to discuss ideas about two things:
         <ul style='list-style:outside;padding-left:40px'>
           <li>Attracting, training, recruiting, growing, retaining, and supporting the preparation of novice teachers, excellent kula leaders, kumu, and staff for learning contexts where ʻōlelo Hawaiʻi, culture, and ʻāina-based experiences are foundational.</li>
           <li>Growing two related communities of kumu and kula leaders who interact regularly, share and learn from one another, develop pilina with one another, and provide support ot one another.</li>
         </ul>
      """
    ]

  'list/Relevant Assessments':
    list_items_title: 'Ideas'

    list_label: 'Relevant Assessments'
    list_description: "A space to discuss ideas around the development of shared assessments that honor the many dimensions of student growth involved in learning contexts where ʻōlelo Hawaiʻi, culture, and ʻāina-based experiences are foundational. Are we willing to challenge the mainstream concep to education success?"


  'list/Teacher Resources':
    list_items_title: 'Ideas'
    list_label: 'Teacher Resources'
    list_description: "A space to discuss ideas around the creation of new (and compiling existing) ʻōlelo Hawaiʻi, culture, and ʻāina-based teaching resources to share widely in an online waihona."


  'list/‘Ōlelo Hawai’i':
    list_items_title: 'Ideas'
    list_label: '‘Ōlelo Hawai’i'
    list_description: "A space to discuss ideas around the way we use our network of Hawaiian Educational Organizationsʻ Synergy to increase the amount of Hawaiian Language speakers so that the language will again be thriving!"

  'list/3C Readiness':
    list_items_title: 'Ideas'
    list_label: '3C Readiness'
    list_description: "A space to discuss ideas around nurturing college, career, and community readiness in haumāna. How do we provide experiences for haumāna that integrate and bridge high-school, college, career, and community engagement experiences?"

  'list/Leadership':
    list_items_title: 'Ideas'
    list_label: 'Leadership'
    list_description: "A space for network leaders to gather mana’o."

  SiteHeader: HawaiiHeader
    background_image_url: asset('hawaii/KulaHawaiiNetwork.jpg')
    title: "Envision the Kula Hawai’i Network"
    subtitle: 'Please share your opinion. Click any proposal below to get started.'
    # background_color: '#78d18b'
    # logo_width: 100




# customizations.dao = _.extend {}, 
#   show_proposer_icon: true
#   collapse_proposal_description_at: 300

#   homepage_show_search_and_sort: true

#   auth_require_pledge: true

#   homepage_show_new_proposal_button: false 

#   show_crafting_page_first: false

#   homepage_default_sort_order: 'trending'

#   homepage_list_order: ['Proposed to DAO', 'Under development', 'New', 'Needs more description', 'Funded', 'Rejected', 'Archived', 'Proposals', 'Ideas', 'Meta', 'DAO 2.0 Wishlist', 'Hack', 'Hack meta']
#   homepage_lists_to_always_show: ['Proposed to DAO', 'Under development',  'Proposals', 'Meta']

#   new_proposal_tips: [
#     'Describe your idea in sufficient depth for others to evaluate it. The title is usually not enough.'
#     'Link to any contract code, external resources, or videos.'
#     'Link to any forum.daohub.org or /r/thedao where more free-form discussion about your idea is happening.'
#     'Take responsibility for improving your idea given feedback.'
#   ]

#   homepage_tabs: 
#     'Inspire Us': ['Ideas', 'Proposals']
#     'Proposal Pipeline': ['New', 'Proposed to DAO', 'Under development',  'Needs more description', 'Funded', 'Rejected', 'Archived']
#     'Meta Proposals': ['Meta', 'Hack', '*']
#     'Hack Response': ['Hack', 'Hack meta']
#   #homepage_default_tab: 'Hack Response'


#   'list/Under development':
#     list_is_archived: false

#   'list/Proposed to DAO':
#     list_one_line_desc: 'Proposals submitted to The Dao\'s smart contract'

#   'list/Needs more description':
#     list_is_archived: true
#     list_one_line_desc: 'Proposals needing more description to evaluate'

#   'list/Funded':
#     list_is_archived: true 
#     list_one_line_desc: 'Proposals already funded by The DAO'

#   'list/Rejected':
#     list_is_archived: true   
#     list_one_line_desc: 'Proposals formally rejected by The DAO'
  
#   'list/Archived':
#     list_is_archived: true 

#   'list/Done':
#     list_is_archived: true

#   'list/Proposals':
#     list_items_title: 'Ideas'

#   'list/Name the DAO':
#     list_is_archived: true

#   SiteHeader: ->
#     homepage = fetch('location').url == '/'

#     DIV
#       style:
#         position: 'relative'
#         background: "linear-gradient(-45deg, #{dao_vars.purple}, #{dao_vars.blue})"
#         paddingBottom: if !homepage then 20
#         borderBottom: "2px solid #{dao_vars.yellow}"


#       onMouseEnter: => @local.hover=true;  save(@local)
#       onMouseLeave: => @local.hover=false; save(@local)




#       STYLE null,
#         '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
#            p {margin-bottom: 1em}'''


#       DIV 
#         style: 
#           marginLeft: 70


#         back_to_homepage_button            
#           display: 'inline-block'
#           color: 'white'
#           opacity: .7
#           position: 'relative'
#           left: -60
#           top: 4
#           fontWeight: 400
#           paddingLeft: 25 # Make the clickable target bigger
#           paddingRight: 25 # Make the clickable target bigger
#           cursor: if fetch('location').url != '/' then 'pointer'

#         # Logo
#         A
#           href: if homepage then 'https://forum.daohub.org/c/theDAO' else '/'


#           IMG
#             style:
#               height: 30
#               width: 30
#               marginLeft: -44
#               marginRight: 10
#               marginTop: -10
#               verticalAlign: 'middle'

#             src: asset('ethereum/the_dao.jpg')

#           SPAN 
#             style:
#               #fontFamily: "Montserrat, 'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"
#               fontSize: 24
#               color: 'white'
#               fontWeight: 500

#             "The DAO"


#       # The top bar with the logo
#       DIV
#         style:
#           width: HOMEPAGE_WIDTH()
#           margin: 'auto'



#         if homepage

#           DIV 
#             style: 
#               #paddingBottom: 50
#               position: 'relative'

#             DIV 
#               style: 
#                 #backgroundColor: '#eee'
#                 # marginTop: 10
#                 padding: "0 8px"
#                 fontSize: 46
#                 fontWeight: 200
#                 color: 'white'
#                 marginTop: 20

              
#               'Deliberate Proposals about The DAO'            


#             DIV 
#               style: 
#                 backgroundColor: 'rgba(255,255,255,.2)'
#                 marginTop: 10
#                 marginBottom: 16
#                 padding: '4px 12px'
#                 float: 'right'
#                 fontSize: 18
#                 color: 'white'

#               SPAN 
#                 style: 
#                   opacity: .8
#                 "join meta discussion on Slack at "

#               A 
#                 href: 'https://thedao.slack.com/messages/consider_it/'
#                 target: '_blank'
#                 style: 
#                   #textDecoration: 'underline'
#                   color: dao_vars.yellow
#                   fontWeight: 600

#                 "#dao_consider_it"


#             DIV 
#               style: 
#                 clear: 'both'

#             DIV 
#               style: 
#                 float: 'right'
#                 fontSize: 12
#                 color: 'white'
#                 opacity: .9
#                 padding: '0px 10px'
#                 position: 'relative'

#               "Donate ETH to fuel "

#               A 
#                 href: 'https://dao.consider.it/donate_to_considerit?results=true'
#                 target: '_blank'
#                 style: 
#                   textDecoration: 'underline'
#                   fontWeight: 600

#                 "our work"

#               " evolving consider.it to meet The DAO’s needs."


#             DIV 
#               style: 
#                 clear: 'both'

#             DIV 
#               style: 
#                 #backgroundColor: 'rgba(255,255,255,.2)'
#                 #marginBottom: 20
#                 padding: '0px 10px'
#                 float: 'right'
#                 fontSize: 15
#                 fontWeight: 500
#                 #color: 'white'
#                 color: dao_vars.yellow
#                 #border: "1px solid #{dao_vars.yellow}"
#                 opacity: .8
#                 fontFamily: '"Courier New",Courier,"Lucida Sans Typewriter","Lucida Typewriter",monospace'
#               "0xc7e165ebdad9eeb8e5f5d94eef3e96ea9739fdb2"


#             DIV 
#               style: 
#                 clear: 'both'
#                 marginBottom: 70


#             DIV 
#               style: 
#                 position: 'relative'
#                 color: 'white'
#                 fontSize: 20

#               DIV 
#                 style: 
#                   position: 'relative'
#                   left: 60
#                 DIV 
#                   style: 
#                     width: 260
#                     position: 'relative'

#                   SPAN style: opacity: .7,
#                     'Ideas that inspire the community & contractors.'

#                   BR null

#                   A 
#                     style: 
#                       opacity: if !@local.hover_idea then .7
#                       display: 'inline-block'
#                       marginTop: 6
#                       color: dao_vars.yellow
#                       border: "1px solid #{dao_vars.yellow}"
#                       #textDecoration: 'underline'
#                       fontSize: 14
#                       fontWeight: 600
#                       #backgroundColor: "rgba(255,255,255,.2)"
#                       padding: '4px 12px'
#                       borderRadius: 8
#                     onMouseEnter: => @local.hover_idea = true; save @local
#                     onMouseLeave: => @local.hover_idea = null; save @local

#                     href: '/proposal/new?category=Proposals'

#                     t("add new")

#                   SVG 
#                     style: 
#                       position: 'absolute'
#                       top: 75
#                       left: '35%'
#                       opacity: .5

#                     width: 67 * 1.05
#                     height: 204 * 1.05
#                     viewBox: "0 0 67 204" 

#                     G                       
#                       fill: 'none'

#                       PATH
#                         strokeWidth: 1 / 1.05 
#                         stroke: 'white' 
#                         d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

#               DIV 
#                 style: 
#                   position: 'relative'
#                   left: 260
#                   marginTop: 0 #30

#                 DIV 
#                   style: 
#                     width: 260
#                     position: 'relative'

#                   SPAN style: opacity: .7,
#                     'Proposals working toward a smart contract.'
#                   BR null

#                   A 
#                     style: 
#                       opacity: if !@local.hover_new then .7
#                       display: 'inline-block'
#                       marginTop: 6
#                       color: dao_vars.yellow
#                       border: "1px solid #{dao_vars.yellow}"
#                       #textDecoration: 'underline'
#                       fontSize: 14
#                       fontWeight: 600
#                       #backgroundColor: "rgba(255,255,255,.2)"
#                       padding: '4px 12px'
#                       borderRadius: 8
#                     onMouseEnter: => @local.hover_new = true; save @local
#                     onMouseLeave: => @local.hover_new = null; save @local

#                     href: '/proposal/new?category=New'

#                     t("add new")

#                   SVG 
#                     style: 
#                       position: 'absolute'
#                       top: 75
#                       left: '35%'
#                       opacity: .5

#                     width: 67 * .63
#                     height: 204 * .63
#                     viewBox: "0 0 67 204" 

#                     G                       
#                       fill: 'none'

#                       PATH
#                         strokeWidth: 1 / .63
#                         stroke: 'white' 
#                         d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

#               DIV 
#                 style: 
#                   position: 'relative'
#                   left: 490
#                   marginTop: 0 #30

#                 DIV 
#                   style: 
#                     width: 260
#                     position: 'relative'

#                   SPAN style: opacity: .7,
#                     'Issues related to the operation of The DAO.'

#                   BR null
#                   A 
#                     style: 
#                       opacity: if !@local.hover_meta then .7
#                       display: 'inline-block'
#                       marginTop: 6
#                       color: dao_vars.yellow
#                       border: "1px solid #{dao_vars.yellow}"
#                       #textDecoration: 'underline'
#                       fontSize: 14
#                       fontWeight: 600
#                       #backgroundColor: "rgba(255,255,255,.2)"
#                       padding: '4px 12px'
#                       borderRadius: 8
#                     onMouseEnter: => @local.hover_meta = true; save @local
#                     onMouseLeave: => @local.hover_meta = null; save @local

#                     href: '/proposal/new?category=Meta'

#                     t("add new")

#                   SVG 
#                     style: 
#                       position: 'absolute'
#                       top: 75
#                       left: '35%'
#                       opacity: .5
#                     width: 67 * .21
#                     height: 204 * .21
#                     viewBox: "0 0 67 204" 

#                     G                       
#                       fill: 'none'

#                       PATH
#                         strokeWidth: 1 / .21
#                         stroke: 'white' 
#                         d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"


#               DIV 
#                 style: 
#                   position: 'absolute'
#                   left: 750
#                   marginTop: 0 #30
#                   bottom: -15

#                 DIV 
#                   style: 
#                     width: 260
#                     position: 'relative'

#                   # SPAN style: opacity: .7,
#                   #   'Issues related to the operation of The DAO.'

#                   BR null
#                   A 
#                     style: 
#                       opacity: if !@local.hover_hack then .7
#                       display: 'inline-block'
#                       marginTop: 6
#                       color: dao_vars.yellow
#                       border: "1px solid #{dao_vars.yellow}"
#                       #textDecoration: 'underline'
#                       fontSize: 14
#                       fontWeight: 600
#                       #backgroundColor: "rgba(255,255,255,.2)"
#                       padding: '4px 12px'
#                       borderRadius: 8
#                     onMouseEnter: => @local.hover_hack = true; save @local
#                     onMouseLeave: => @local.hover_hack = null; save @local

#                     href: '/proposal/new?category=Hack'

#                     t("add new")

#                   # SVG 
#                   #   style: 
#                   #     position: 'absolute'
#                   #     top: 75
#                   #     left: '35%'
#                   #     opacity: .5
#                   #   width: 67 * .21
#                   #   height: 204 * .21
#                   #   viewBox: "0 0 67 204" 

#                   #   G                       
#                   #     fill: 'none'

#                   #     PATH
#                   #       strokeWidth: 1 / .21
#                   #       stroke: 'white' 
#                   #       d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"






#             if customization('homepage_tabs')
#               HomepageTabs()






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


customizations['bitcoinfoundation'] = 
  homepage_list_order: ['Proposals', 'Trustees', 'Members']
  homepage_show_new_proposal_button: false 

  opinion_filters: [ {
      label: 'members'
      tooltip: 'Verified member of the Second Foundation.'
      pass: (user) -> passes_tags(user, 'second_foundation_member')
      icon: "<span style='color:green'>\u2713 member</span>"

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
    }
  ]

  #   auth_questions : [
  #     {
  #       tag: 'bitcoin_foundation_member.editable'
  #       question: 'I am a member of the Bitcoin Foundation'
  #       input: 'dropdown'
  #       options:['No', 'Yes']
  #       required: true
  #     }]
  auth_require_pledge: true

  # default proposal options
  show_proposer_icon: true
  list_opinions_title: "Votes"
  collapse_proposal_description_at: 300

  slider_pole_labels: slider_labels.support_oppose  

  'list/First Foundation': 
    list_one_line_desc: 'Archived proceedings of the First Foundation'        
    list_is_archived: true

  show_crafting_page_first: true



#####################
# Living Voters Guide



customizations.livingvotersguide = 

  auth_require_pledge: true

  slider_pole_labels: slider_labels.support_oppose

  'list/Advisory votes': 
    list_is_archived: true
    list_one_line_desc: "Advisory Votes are not binding."


  SiteFooter : ReactiveComponent
    displayName: 'SiteFooter'
    render: ->
      DIV 
        style: 
          position: 'relative'
          textAlign: 'center'
          zIndex: 0

        DIV style: {color: 'white', backgroundColor: '#93928E', marginTop: 48, padding: 18, maxHeight: 400},
          DIV style: {fontSize: 18, textAlign: 'left', width: 690, margin: 'auto'},
            """Unlike voter guides generated by government, newspapers or 
               advocacy organizations, Living Voters Guide is created """
            SPAN style: {fontWeight: 600}, 'by the people'
            ' and '
            SPAN style: {fontWeight: 600}, 'for the people'
            """ of Washington State. It\'s your platform to learn about candidate and ballot measures, 
                decide how to vote and express your ideas. We believe that sharing our diverse opinions 
                leads to making wiser decisions together."""
            A style: {color: 'white', textDecoration: 'underline', fontWeight: 'normal'}, href: '/about', 'Learn more'
            '.'

          DIV style: {marginTop: 20},
            FBLike()
            Tweet
              hashtags: 'lvguide'
              referer: 'https%3A%2F%2Flivingvotersguide.org%2F'
              related: 'lvguide'
              text: 'I%20flexed%20my%20civic%20muscle%20%40lvguide.'
              url: 'https%3A%2F%2Flivingvotersguide.org%2F'


        DefaultFooter()

  SiteHeader: ->
    LVG_blue = '#063D72'
    LVG_green = '#A5CE39'


    homepage = fetch('location').url == '/'

    if homepage 
      ZipcodeBox = =>
        current_user = fetch('/current_user')
        extra_text = if Modernizr.input.placeholder then '' else ' Zip Code'
        onChange = (event) =>
          if event.target.value.match(/\d\d\d\d\d/)
            current_user.tags['zip.editable'] = event.target.value
            save(current_user)

          else if event.target.value.length == 0
            current_user.tags['zip.editable'] = undefined
            @local.stay_around = true
            save(current_user)
            save(@local)

        if current_user.tags['zip.editable'] or @local.stay_around
          # Render the completed zip code box

          DIV
            style: 
              textAlign: 'center'
              padding: '13px 23px'
              fontSize: 20
              fontWeight: 400
              margin: 'auto'
              color: 'white'
            className: 'filled_zip'

            'Customized for:'
            INPUT

              style: 
                fontSize: 20
                fontWeight: 600
                border: '1px solid transparent'
                borderColor: if @local.focused || @local.hovering then '#767676' else 'transparent'
                backgroundColor: if @local.focused || @local.hovering then 'white' else 'transparent'
                width: 80
                marginLeft: 7
                color: if @local.focused || @local.hovering then 'black' else 'white'
                display: 'inline-block'
              type: 'text'
              key: 'zip_input'
              defaultValue: current_user.tags['zip.editable'] or ''
              onChange: onChange
              onFocus: => 
                @local.focused = true
                save(@local)
              onBlur: =>
                @local.focused = false
                @local.stay_around = false
                save(@local)
              onMouseEnter: => 
                @local.hovering = true
                save @local
              onMouseLeave: => 
                @local.hovering = false
                save @local

        else
          # zip code entry
          DIV 
            style: 
              backgroundColor: 'rgba(0,0,0,.1)'
              fontSize: 22
              fontWeight: 700
              width: 720
              color: 'white'
              padding: '15px 40px'
              marginLeft: (WINDOW_WIDTH() - 720) / 2
              #borderRadius: 16

            'Customize this guide for your' + extra_text
            INPUT
              type: 'text'
              key: 'zip_input'
              placeholder: 'Zip Code'
              style: {margin: '0 0 0 12px', fontSize: 22, height: 42, width: 152, padding: '4px 20px'}
              onChange: onChange

    DIV 
      style: 
        position: 'relative'

      STYLE null, 
        """[subdomain="livingvotersguide"] .endorser_group {
          width: 305px;
          display: inline-block;
          margin-bottom: 1em;
          vertical-align: top; }
          [subdomain="livingvotersguide"] .endorser_group.oppose {
            margin-left: 60px; }
          [subdomain="livingvotersguide"] .endorser_group li, [subdomain="livingvotersguide"] .endorser_group a {
            font-size: 12px; }
          [subdomain="livingvotersguide"] .endorser_group ul {
            margin-left: 0px;
            padding-left: 10px; }
          [subdomain="livingvotersguide"] .total_money_raised {
            font-weight: 600;
            float: right; }
          [subdomain="livingvotersguide"] .funders li {
            list-style: none; }
            [subdomain="livingvotersguide"] .funders li .funder_amount {
              float: right; }
          [subdomain="livingvotersguide"] .news {
            padding-left: 0; }
            [subdomain="livingvotersguide"] .news li {
              font-size: 13px;
              list-style: none;
              padding-bottom: 6px; }
          [subdomain="livingvotersguide"] .editorials ul {
            padding-left: 10px; }
            [subdomain="livingvotersguide"] .editorials ul li {
              list-style: none;
              padding-top: 6px; }"""


      DIV 
        style: 
          height: if !homepage then 150 else 455 
          backgroundImage: "url(#{asset('livingvotersguide/bg.png')})"
          backgroundPosition: 'center'
          backgroundSize: 'cover'
          backgroundColor: LVG_blue
          textAlign: if homepage then 'center'


        if !homepage 
          back_to_homepage_button            
            position: 'absolute'
            display: 'inline-block'
            top: 40
            left: 22
            color: 'white'

        # Logo
        A 
          style: 
            marginTop: if homepage then 40 else 10
            display: 'inline-block'
            marginLeft: if !homepage then 80
            marginRight: if !homepage then 30

          href: (if fetch('location').url == '/' then '/about' else '/'),
          IMG 
            src: asset('livingvotersguide/logo.svg')
            style:
              width: if homepage then 220 else 120
              height: if homepage then 220 else 120


        # Tagline
        DIV 
          style:
            display: if !homepage then 'inline-block'
            position: 'relative'
            top: if !homepage then -32
          DIV
            style:
              fontSize: if homepage then 32 else 24
              fontWeight: 700
              color: LVG_green
              margin: '12px 0 4px 0'

            SPAN null, 
              'Washington\'s Citizen Powered Voters Guide'

          DIV 
            style: 
              color: 'white'
              fontSize: if homepage then 20 else 18

            'Learn about your ballot, decide how you’ll vote, and share your opinion.'

        if homepage



          DIV
            style:
              color: 'white'
              fontSize: 20
              marginTop: 30

            DIV
              style: 
                position: 'relative'
                display: 'inline'
                marginRight: 50
                height: 46

              SPAN 
                style: 
                  paddingRight: 12
                  position: 'relative'
                  top: 4
                  verticalAlign: 'top'
                'brought to you by'
              A 
                style: 
                  verticalAlign: 'top'

                href: 'http://seattlecityclub.org'
                IMG 
                  src: asset('livingvotersguide/cityclub.svg')

            DIV 
              style: 
                position: 'relative'
                display: 'inline'
                height: 46
                #display: 'none'

              SPAN 
                style: 
                  paddingRight: 12
                  verticalAlign: 'top'
                  position: 'relative'
                  top: 4

                'fact-checks by'
              
              A 
                style: 
                  verticalAlign: 'top'
                  position: 'relative'
                  top: -6

                href: 'http://spl.org'
                IMG
                  style: 
                    height: 31

                  src: asset('livingvotersguide/spl.png')

      if homepage
        DIV 
          style: 
            backgroundColor: LVG_green

          DIV 
            style: 
              color: 'white'
              margin: 'auto'
              padding: '40px'
              width: 720


            DIV
              style: 
                fontSize: 24
                fontWeight: 600
                textAlign: 'center'

              """The Living Voters Guide has passed on..."""

            DIV 
              style: 
                fontSize: 18
              """We have made the difficult decision to discontinue the Living Voters Guide 
                 after six years of service. Thank you for your contributions through the years!"""

          DIV 
            style: 
              paddingBottom: 15

            ZipcodeBox()

      else
        DIV 
          style: 
            backgroundColor: LVG_green
            paddingTop: 5



FBShare = ReactiveComponent
  displayName: 'FBShare'

  componentDidMount: ->
    FB.XFBML.parse document

  render: -> 
    layout = 'button'
    SPAN 
      style: {display: 'inline-block', marginRight: 5, position: 'relative', top: -6}
      dangerouslySetInnerHTML: { __html: "<fb:share-button data-layout='#{layout}'></fb:share-button>"}
    

FBLike = ReactiveComponent
  displayName: 'FBLike'
  render : -> 
    page = 'http://www.facebook.com/pages/Living-Voters-Guide/157151824312366'
    IFRAME 
      style: {border: 'none', overflow: 'hidden', width: 90, height: 21}
      src: """//www.facebook.com/plugins/like.php?href=#{page}&send=false&layout=button_count&width=450&
              show_faces=false&action=like&colorscheme=light&font=lucida+grande&height=21"""
      scrolling: "no"
      frameBorder: "0"
      allowTransparency: "true"

Tweet = ReactiveComponent
  displayName: 'Tweet'

  render: ->
    url = """https://platform.twitter.com/widgets/tweet_button.1410542722.html#?_=
          1410827370943&count=none&id=twitter-widget-0&lang=en&size=m"""
    for url_param in ['hashtags', 'original_referer', 'related', 'text', 'url']
      if @props[url_param]
        url += "&#{url_param}=#{@props[url_param]}"

    IFRAME 
      src: url
      scrolling: "no"
      frameBorder: "0"
      allowTransparency: "true"
      className: "twitter-share-button twitter-tweet-button twitter-share-button twitter-count-none"
      style: {width: 57; height: 20}


customizations.mos = 

  slider_pole_labels :
    support: 'Support'
    support_sub: 'the ban'
    oppose: 'Oppose'
    oppose_sub: 'the ban'

  show_crafting_page_first: true



