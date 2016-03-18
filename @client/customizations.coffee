require './color'
require './logo'

#######################
# Customizations.coffee
#
# Tailor considerit applications by subdomain
#

#######
# PUBLIC API
#
# The customization method returns the proper value of the field for this 
# subdomain, or the default value if it hasn't been defined for the subdomain.
#
# Nested customizations can be fetched with . notation, by passing e.g. 
# "auth.use_footer" or with a bracket, like "auth.use_footer['on good days']"
#
# object_or_key is optional. If passed, customization will additionally check for 
# special configs for that object (object.key) or key.

window.customization = (field, object_or_key) -> 
  subdomain = fetch('/subdomain')

  subdomain_name = subdomain.name?.toLowerCase()

  value = undefined

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

    subdomain_config = fetch("customizations/#{subdomain_name}")

    # object-specific config
    if key 

      if subdomain_config[key]?
        chain_of_configs.push subdomain_config[key]

      # cluster-level config for proposals
      if key.match(/\/proposal\//)
        proposal = object_or_key
        cluster_key = "cluster/#{proposal.cluster}"
        if subdomain_config[cluster_key]?
          chain_of_configs.push subdomain_config[cluster_key]

    # subdomain config
    chain_of_configs.push subdomain_config

  # global default config
  chain_of_configs.push fetch('customizations/default')

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


###########
# Private storage
customizations = {}



require './browser_location' # for loadPage
require './shared'
require './footer'
require './profile_menu'
require './slider'
require './header'
require './homepage'
require './proposal_navigation'



#####
# common options


# pro/con labels

pro_con = 
  pro: 'pro'
  pros: 'pros' 
  con: 'con'
  cons: 'cons'
  your_header: "Give your --valences--" 
  other_header: "Others' --valences--" 
  top_header: "Top --valences--" 
  your_cons_header: null
  your_pros_header: null

strengths_weaknesses = 
  pro: 'strength'
  pros: 'strengths' 
  con: 'weakness'
  cons: 'weaknesses'
  your_header: "--valences--" 
  other_header: "--valences-- observed" 
  top_header: "Foremost --valences--" 

strengths_limitations = 
  pro: 'strength'
  pros: 'strengths' 
  con: 'limitation'
  cons: 'limitations'
  your_header: "--valences-- you observed" 
  other_header: "--valences-- observed" 
  top_header: "Foremost --valences--" 


challenge_justify = 
  pro: 'justification'
  pros: 'justifications' 
  con: 'challenge'
  cons: 'challenges'
  your_header: "Give your --valences--" 
  other_header: "--valences-- identified" 
  top_header: "Top --valences--" 


strengths_improvements = 
  pro: 'strength'
  pros: 'strengths' 
  con: 'improvement'
  cons: 'improvements'
  your_header: "--valences-- you observe" 
  your_cons_header: "Your suggested improvements"
  your_pros_header: "Strengths you observe"
  other_header: "--valences-- identified" 
  top_header: "Top --valences--" 


support_challenge_claim = 
  pro: 'supporting claim'
  pros: 'supporting claims' 
  con: 'challenging claim'
  cons: 'challenging claims'
  your_header: "--valences-- you recognize" 
  other_header: "--valences-- identified" 
  top_header: "Top --valences--" 


delta_pluses = 
  pro: 'plus'
  pros: 'pluses' 
  con: 'delta'
  cons: 'deltas'
  your_header: "--valences-- you recognize" 
  other_header: "--valences-- identified" 
  top_header: "Top --valences--" 


pros_contras = 
  pro: 'pro'
  pros: 'pros' 
  con: 'contra'
  cons: 'contras'
  your_header: "Ingresa tus --valences--" 
  other_header: "Otros --valences--" 
  top_header: "Top --valences--" 


port_pros_cons = 
  pro: 'A Favor'
  pros: 'A Favor' 
  con: 'Contra'
  cons: 'Contra'
  your_header: "Teus pontos --valences--" 
  other_header: "Outros --valences--" 
  top_header: "Top --valences--" 


# slider poles

support_oppose = 
  individual: 
    support: 'Support'
    oppose: 'Oppose'
    support_sub: ''
    oppose_sub: ''
  group: 
    support: 'Supporters'
    oppose: 'Opposers'
    support_sub: ''
    oppose_sub: ''

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

      valence = customization "slider_pole_labels.individual." + \
                              (if value > 0 then 'support' else 'oppose'), \
                              proposal

      "You #{strength_of_opinion} #{valence}"


relevance = 
  individual: 
    support: 'Big impact!'
    oppose: 'No impact on me'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'Big impact!'
    oppose: 'No impact on me'
    support_sub: ''
    oppose_sub: ''

priority = 
  individual: 
    support: 'High Priority'
    oppose: 'Low Priority'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'High Priority'
    oppose: 'Low Priority'
    support_sub: ''
    oppose_sub: ''    



interested = 
  individual: 
    support: 'Interested'
    oppose: 'Uninterested'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'Interested'
    oppose: 'Uninterested'
    support_sub: ''
    oppose_sub: ''  

important_unimportant = 
  individual: 
    support: 'Important'
    oppose: 'Unimportant'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'Important'
    oppose: 'Unimportant'
    support_sub: ''
    oppose_sub: ''


yes_no = 
  individual: 
    support: 'Yes'
    oppose: 'No'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'Yes'
    oppose: 'No'
    support_sub: ''
    oppose_sub: ''

strong_weak = 
  individual: 
    support: 'Strong'
    oppose: 'Weak'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'Strong'
    oppose: 'Weak'
    support_sub: ''
    oppose_sub: ''

promising_weak = 
  individual: 
    support: 'Promising'
    oppose: 'Weak'
    support_sub: ''
    oppose_sub: ''    
  group: 
    support: 'Promising'
    oppose: 'Weak'
    support_sub: ''
    oppose_sub: ''


ready_not_ready = 
  individual: 
    support: 'Ready'
    oppose: 'Not ready'
    support_sub: ''
    oppose_sub: ''
  group: 
    support: 'Ready'
    oppose: 'Not ready'  
    support_sub: ''
    oppose_sub: ''

agree_disagree = 
  individual: 
    support: 'Agree'
    oppose: 'Disagree'
    support_sub: ''
    oppose_sub: ''

  group: 
    support: 'Agree'
    oppose: 'Disagree'  
    support_sub: ''
    oppose_sub: ''

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

      valence = customization "slider_pole_labels.individual." + \
                              (if value > 0 then 'support' else 'oppose'), \
                              proposal

      "You #{strength_of_opinion} #{valence}"


plus_minus = 
  individual: 
    support: '+'
    oppose: '–'
    support_sub: ''
    oppose_sub: ''

  group: 
    support: '+'
    oppose: '–'
    support_sub: ''
    oppose_sub: ''

effective_ineffective = 
  individual: 
    support: 'Effective'
    oppose: 'Ineffective'
    support_sub: ''
    oppose_sub: ''

  group: 
    support: 'Effective'
    oppose: 'Ineffective'
    support_sub: ''
    oppose_sub: ''


desacuerdo_acuerdo = 
  individual: 
    support: 'Acuerdo'
    oppose: 'Desacuerdo'
    support_sub: ''
    oppose_sub: ''

  group: 
    support: 'Acuerdo'
    oppose: 'Desacuerdo'
    support_sub: ''
    oppose_sub: ''


port_agree_disagree = 
  individual: 
    support: 'Concordo'
    oppose: 'Discordo'
    support_sub: ''
    oppose_sub: ''

  group: 
    support: 'Concordo'
    oppose: 'Discordo'
    support_sub: ''
    oppose_sub: ''



# application options
conference_config = 
  slider_pole_labels :
    individual: 
      support: 'Accept'
      oppose: 'Reject'
    group: 
      support: 'Accept'
      oppose: 'Reject'

  homie_histo_title: "PC's ratings"


################################
# DEFAULT CUSTOMIZATIONS
# 
# TODO: refactor config & document

customizations.default = 
  lang: 'en'

  # Proposal options
  discussion: true

  proposal_filters: true

  show_new_proposal_button: true

  show_crafting_page_first: false

  show_histogram_on_crafting: true

  point_labels : pro_con

  show_slider_feedback: true
  slider_pole_labels : agree_disagree

  show_meta: true 
  docking_proposal_header : false

  slider_handle: slider_handle.face
  slider_ticks: false
  slider_regions: null

  show_score: true

  show_proposer_icon: false
  collapse_descriptions_at: false
  homie_histo_filter: false

  # default cluster options
  # TODO: put them in their own object
  homie_histo_title: 'Opinions'
  archived: false
  label: false
  description: false

  # Other options
  additional_auth_footer: false
  civility_pledge: false
  has_homepage: true


  auth: 
    
    user_questions: []

  Homepage : SimpleHomepage
  ProposalNavigation : DefaultProposalNavigation

  HomepageHeader : DefaultHeader
  NonHomepageHeader: ShortHeader

  Footer : DefaultFooter

  ThanksForYourOpinion: false





##########################
# SUBDOMAIN CONFIGURATIONS



rupaul_header = ReactiveComponent
  displayName: 'ImageHeader'

  render: ->
    subdomain = fetch '/subdomain'   
    loc = fetch 'location'    
    homepage = loc.url == '/'

    masthead_style = 
      textAlign: 'left'
      backgroundColor: subdomain.branding.primary_color
      height: 45

    hsl = parseCssHsl(subdomain.branding.primary_color)
    is_light = hsl.l > .75

    if subdomain.branding.masthead
      _.extend masthead_style, 
        height: 300
        backgroundPosition: 'center'
        backgroundSize: 'cover'
        backgroundImage: "url(#{subdomain.branding.masthead})"

    else 
      throw 'ImageHeader can\'t be used without a branding masthead'

    DIV null,

      DIV
        style: masthead_style 

        ProfileMenu()

        A
          href: '/'
          style: 
            position: 'relative'
            marginLeft: 20
            display: 'inline-block'
            color: if !is_light then 'white'
            fontSize: 43
            visibility: if homepage || !customization('has_homepage') then 'hidden'
            verticalAlign: 'middle'
            marginTop: 5
          '<'


      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: '40px auto'
          display: if !homepage then 'none'

        DIV 
          style: 
            fontSize: 52
            fontWeight: 300
            marginBottom: 20
            color: '#CE496E'

          "Welcome Hunties to season 8 of RuPaul's Drag Race!"

        DIV 
          style: 
            marginBottom: 12
            fontSize: 21

          """This is a space for you to serve the T, throw some shade, show some 
          love and share who you think has the Charisma, Uniqueness, Nerve and 
          Talent to be America's Next Drag Superstar! So, just between us 
          squirrel-friends, who do think will be win season 8?"""

        DIV 
          style: 
            fontSize: 21

          """You can change your votes each week. When a queen gets eliminated, we'll 
          Sashay away her from the list. Good luck! And Don't Fuck it Up!"""    

customizations['rupaulseason8'] =
  show_proposer_icon: false
  proposal_filters: false
  show_meta: false 

  point_labels: 
    pro: 'Love'
    pros: 'Love' 
    con: 'Shade'
    cons: 'Shade'
    your_header: "Throw your --valences--" 
    other_header: "Others' --valences--" 
    top_header: "Best --valences--" 
    
  slider_pole_labels: 
    individual: 
      support: 'YAAAAAAS'
      oppose: 'Hellz No!'
      support_sub: ''
      oppose_sub: ''    
    group: 
      support: 'YAAAAAAS'
      oppose: 'Hellz No!'
      support_sub: ''
      oppose_sub: ''

  HomepageHeader: rupaul_header
  NonHomepageHeader: rupaul_header





####
# CARCD 

carcd_header = ReactiveComponent
  displayName: 'Carcd_header'

  render: -> 
    loc = fetch('location')

    homepage = loc.url == '/'

    DIV 
      style: 
        position: 'relative'
        width: HOMEPAGE_WIDTH()
        margin: 'auto'
        height: if !homepage then 180

      A
        href: 'http://carcd.consider.it'
        target: '_blank'
        style:
          position: 'absolute'
          top: 20
          left: -48 #(WINDOW_WIDTH() - 391) / 2
          zIndex: 5

        IMG
          src: asset('carcd/logo2.png')
          style:
            height: 145

      DIV
        style:
          # backgroundColor: "#F0F0F0"
          height: 82
          width: '100%'
          position: 'relative'
          top: 50
          left: 0
          #border: '1px solid #7D9DB5'
          #borderLeftColor: 'transparent'
          #borderRightColor: 'transparent'

        A
          href: '/'
          style: 
            display: 'block'
            fontSize: 43
            visibility: if homepage then 'hidden'
            verticalAlign: 'top'
            left: -91
            top: 10
            color: 'black'
            position: 'relative'
          '<'

      if homepage
        DIV 
          style: 
            paddingTop: 82
            width: HOMEPAGE_WIDTH()
            paddingLeft: 70
            margin: 'auto'
            position: 'relative'

          DIV 
            style: 
              fontSize: 26
              fontWeight: 600
              # position: 'absolute'
              # top: -80
              color: '#7D9DB6'

            "We need your feedback!" 

          DIV 
            style: 
              fontSize: 20
              marginBottom: 18

            """This survey gives you a chance to influence the CARCD strategic plan and 
            our priorities for the next several years.  Please take the time to 
            respond to the questions below – elaborate, argue, tell us what you 
            really think!"""

          DIV 
            style: 
              fontSize: 20
              marginBottom: 6
            "Thank you for your time,"
            BR null
            "The CARCD team"



      # if homepage 
      #   DIV
      #     style:
      #       position: 'absolute'
      #       left: (WINDOW_WIDTH() + 8) / 2
      #       zIndex: 5
      #       top: 188
      #       paddingLeft: 12

      #     SPAN 
      #       style: 
      #         fontSize: 14
      #         fontWeight: 400
      #         color: '#7D9DB5'
      #         #fontVariant: 'small-caps'
      #         position: 'relative'
      #         top: -18
      #       'facilitated by'

      #     A 
      #       href: 'http://solidgroundconsulting.com'
      #       target: '_blank'
      #       style: 
      #         padding: '0 5px'

      #       IMG
      #         src: asset('carcd/solidground.png')
      #         style: 
      #           width: 103

      DIV 
        style: 
          position: 'absolute'
          top: 18
          right: 0
          width: 110

        ProfileMenu()




customizations['carcd'] = customizations['carcd-demo'] = 
  show_proposer_icon: true
  proposal_filters: false


  "cluster/Serving Districts" : 
    point_labels: 
      pro: 'argument for depth'
      pros: 'Arguments for Depth' 
      con: 'argument for breadth'
      cons: 'Arguments for Breadth'
      your_header: "Your --valences--" 
      other_header: "--valences--" 
      top_header: "Top --valences--" 

    slider_pole_labels: 
      individual: 
        support: 'High impact districts'
        oppose: 'All districts'
        support_sub: ''
        oppose_sub: ''    
      group: 
        support: 'High impact districts'
        oppose: 'All districts'
        support_sub: ''
        oppose_sub: ''

    description: 
      DIV 
        style: 
          #marginLeft: 65
          fontSize: 18
          fontWeight: 400
          position: 'relative'
          top: 12
          padding: 4
          fontStyle: 'italic'
          color: '#888'
        "Serve districts equally, or should it deeply focus more of its efforts on those districts with the capacity?"
    show_slider_feedback: false


  "cluster/Accreditation" : 
    point_labels: 
      pro: 'argument for rewarded'
      pros: 'Arguments for Rewarded' 
      con: 'argument for unrewarded'
      cons: 'Arguments for Unrewarded'
      your_header: "Your --valences--" 
      other_header: "--valences--" 
      top_header: "Top --valences--" 

    slider_pole_labels: 
      individual: 
        support: 'Rewarded'
        oppose: 'Unrewarded'
        support_sub: ''
        oppose_sub: ''    
      group: 
        support: 'Rewarded'
        oppose: 'Unrewarded'
        support_sub: ''
        oppose_sub: ''

    description: 
      DIV 
        style: 
          #marginLeft: 65
          fontSize: 18
          fontWeight: 500
          position: 'relative'
          top: 12
          padding: 4
          fontStyle: 'italic'
          color: '#888'
        "How much should CARCD actively push districts to embrace and meet the Vision and Standards expectations? "

    show_slider_feedback: false




  "cluster/Program Emphasis" : 
    point_labels: pro_con
    slider_pole_labels: priority
    show_slider_feedback: false

    description: 
      DIV 
        style: 
          #marginLeft: 65
          fontSize: 18
          fontWeight: 500
          position: 'relative'
          top: 12
          padding: 4
          fontStyle: 'italic'
          color: '#888'
        "Rank the priority of each of program option. Remember, to emphasize everything is to emphasize nothing."




  "cluster/Lagging Districts" : 
    point_labels: pro_con
    slider_pole_labels: agree_disagree
    show_slider_feedback: false

    description:
      DIV 
        style: 
          #marginLeft: 65
          fontSize: 18
          fontWeight: 500
          position: 'relative'
          top: 12
          padding: 4
          fontStyle: 'italic'
          color: '#888'
        "Parts of the state lack effective, sustainable districts. What should CARCD's response be?"


  "cluster/Questions" : 
    point_labels: pro_con
    slider_pole_labels: important_unimportant
    show_slider_feedback: false

  point_labels: pro_con
  slider_pole_labels: promising_weak
  show_slider_feedback: false

  HomepageHeader: carcd_header
  NonHomepageHeader: carcd_header

  #ProposalNavigation: ProposalNavigationWithMenu


customizations['consider'] = 
  #show_proposer_icon: true
  proposal_filters: false 
  opinion_filters: false 

  "cluster/Bug Reports" : 
    slider_pole_labels: relevance
    show_slider_feedback: false
    discussion: false
    description: 
      DIV 
        style: 
          #marginLeft: 65
          fontSize: 18
          fontWeight: 500
          position: 'relative'
          top: 12
          padding: 4
          fontStyle: 'italic'
          color: '#888'
        "Describe bugs you've encountered. Please include your browser and device!"

  # opinion_filters: [ {
  #     label: 'consider.it staff'
  #     tooltip: null
  #     pass: (user) -> user.key in ['/user/1701', '/user/1707', '/user/30970']
  #   }]


  "cluster/Hard Tasks" : 
    slider_pole_labels: important_unimportant
    show_slider_feedback: false
    description: 
      DIV 
        style: 
          #marginLeft: 65
          fontSize: 18
          fontWeight: 500
          position: 'relative'
          top: 12
          padding: 4
          fontStyle: 'italic'
          color: '#888'
        "What tasks should we make significantly easier?"

  HomepageHeader: ReactiveComponent
    displayName: 'HomepageHeader'

    render: -> 
      HEADER_HEIGHT = 30 
      DIV
        style:
          position: "relative"
          margin: "0 auto"
          backgroundColor: logo_red
          height: HEADER_HEIGHT
          zIndex: 1

        DIV
          style:
            width: CONTENT_WIDTH()
            margin: 'auto'

          SPAN 
            style:
              position: "relative"
              top: 4
              left: if window.innerWidth > 1055 then -23.5 else 0

            drawLogo HEADER_HEIGHT + 5, 
                    'white', 
                    (if @local.in_red then 'transparent' else logo_red), 
                    !@local.in_red,
                    false

          SPAN 
            style: 
              fontSize: 22
              position: 'relative'
              top: -5
              color: 'white'
              fontStyle: 'italic'

            'Issue Slate'


customizations['us'] = 
  show_proposer_icon: true

customizations['cimsec'] = 
  slider_pole_labels : effective_ineffective


portuguese = ['sintaj', 'delegados_sintaj']

for port in portuguese
  customizations[port] = 
    lang: 'ptbr'
    point_labels : port_pros_cons
    slider_pole_labels : port_agree_disagree
    homie_histo_title: "Opiniões"
    show_slider_feedback: false
    proposal_filters: false 

spanish = ['alcala', 'villagb', 'citysens', 'iniciativasciudadanas', \
           'movilidadcdmx', 'zonaq', 'valenciaencomu', 'aguademayo']

for spa in spanish
  customizations[spa] = 
    lang: 'spa'
    point_labels : pros_contras
    slider_pole_labels : desacuerdo_acuerdo
    homie_histo_title: "Opiniones"
    show_slider_feedback: false
    proposal_filters: false 


customizations['alcala'] = _.extend {}, customizations['alcala'],
  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      subdomain = fetch '/subdomain'

      DIV
        style:
          position: 'relative'

        IMG
          style: 
            width: '100%'
            display: 'block'

          src: subdomain.branding.masthead

        ProfileMenu()

        DIV 
          style: 
            padding: '20px 0'

          DIV 
            style: 
              width: HOMEPAGE_WIDTH()
              margin: 'auto'




###############
# Monitorinstitute

monitorinstitute_red = "#BE0712"

customizations['monitorinstitute'] = 
  point_labels : strengths_improvements
  slider_pole_labels : strong_weak
  homie_histo_title: "Opinions"
  show_slider_feedback: false

  NonHomepageHeader : ReactiveComponent
    displayName: 'NonHomepageHeader'

    render: ->
      section_style = 
        padding: '8px 0'
        fontSize: 16



      DIV
        style:
          position: 'relative'
          width: BODY_WIDTH()
          paddingTop: 20
          margin: '0 auto 15px auto'

        A
          href: '/'
          style: 
            fontSize: 43
            position: 'absolute'
            marginRight: 30
            left: -60
            top: 3

          '<'            
            
        A 
          href: 'http://monitorinstitute.com/'
          target: '_blank'
          style: 
            display: 'inline-block'

          IMG 
            src: asset("monitorinstitute/logo.jpg")

        DIV 
          style: 
            position: 'absolute'
            right: -70
            top: 0
            width: 200
          ProfileMenu()

  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      section_style = 
        padding: '8px 0'
        fontSize: 16

      DIV
        style:
          position: 'relative'

        DIV 
          style: 
            width: CONTENT_WIDTH()
            margin: 'auto'
            paddingTop: 20
            position: 'relative'

          A 
            href: 'http://monitorinstitute.com/'
            target: '_blank'

            IMG 
              src: asset("monitorinstitute/logo.jpg")

          ProfileMenu()


          DIV 
            style: {}

            DIV 
              style:  
                color: monitorinstitute_red
                fontSize: 34
                marginTop: 40

              "The Monitor Institute intellectual agenda"

            DIV 
              style: 
                fontStyle: 'italic'
                marginBottom: 20
              'Spring 2015'

            DIV 
              style: 
                width: CONTENT_WIDTH() * .7
                borderRight: "1px solid #ddd"
                display: 'inline-block'
                paddingRight: 25

              P 
                style: section_style


                """
                Central to the Monitor Institute brand is the idea that we pursue 
                “next practice” in social impact. We do not simply master and teach 
                well‐established best practices, but treat those as table stakes and 
                focus our attention on the learning edges for the field. Our core 
                expertise is in helping social impact leaders and organizations 
                develop the skillsets they need to achieve greater progress than 
                in the past and prepare themselves for tomorrow’s context.
                """

              P 
                style: section_style

                """
                This document is a place for us to articulate two things: """
                SPAN
                  style: 
                    fontStyle: 'italic'

                  "what we believe"
 
                """ to be “next practice” today, and what """
                SPAN
                  style: 
                    fontStyle: 'italic'

                  "what we want to know"

                """ about how those practices can and will develop further. The former is our 
                point of view; the latter is the whitespace that is waiting to be 
                filled in over the coming three to five years.
                """





              P 
                style: section_style
                "It is designed to be used in a variety of ways:"

              UL
                style:
                  listStylePosition: 'outside'
                  paddingLeft: 30

                LI
                  style: section_style
                  """
                  It is primarily a """

                  SPAN
                    style: 
                      fontWeight: 600
                    "statement of strategy and vision"
                  """. It does not contain 
                  every next practice in the world, nor every important question to be 
                  resolved, but only the ones that we believe are both (a) the most 
                  transformative in the field of social impact and (b) those that we are 
                  equipped and committed to working on. It must therefore be a living document, 
                  revisited and revised often enough that it always reflects our most 
                  up‐to‐date perspectives.
                  """

                LI 
                  style: section_style
                  """
                  Next, it is a """

                  SPAN
                    style: 
                      fontWeight: 600
                    "rubric for making choices"

                  """ that will keep us aligned and focused. 
                  We will know we are doing well as a next‐practice consulting team when our 
                  mix of commercial and eminence work promotes the points of view described 
                  under """

                  SPAN
                    style: 
                      fontStyle: 'italic'

                    "what we believe"

                  " and helps us answer the questions listed under "

                  SPAN
                    style: 
                      fontStyle: 'italic'

                    "what we want to know"

                  """. When there is a question as to whether we should pursue an 
                  opportunity that arrives or choose to focus resources in a given direction, 
                  we can check our judgment by asking whether it will help us do either or both 
                  of those things. That is equally true for scanning, for relationship‐building 
                  and sales, for eminence projects, and for commercial work.
                  """

            DIV 
              style: 
                display: 'inline-block'
                width: CONTENT_WIDTH() * .25
                verticalAlign: 'top'
                marginTop: 200
                paddingLeft: 25
                color: monitorinstitute_red
                fontWeight: 600

              """This is the intro to the draft intellectual agenda. Please provide 
                 feedback on each proposed intellectual agenda item below."""



################
# seattle2035

seattle2035_cream = "#FCFBE6"
seattle2035_pink = '#F06668'
seattle2035_dark = '#5C1517'

customizations['seattle2035'] = 
  point_labels : pro_con
  slider_pole_labels : agree_disagree
  homie_histo_title: "Opinions"
  show_proposer_icon: true
  civility_pledge: true

  "cluster/Overall" : 
    point_labels: strengths_weaknesses
    slider_pole_labels: yes_no
    show_slider_feedback: false


  auth: 

    user_questions : [
      { 
        tag: 'zip.editable'
        question: 'The zipcode where I live is'
        input: 'text'
        required: false
        input_style: 
          width: 85
        validation: (zip) ->
          return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
      }, {
        tag: 'age.editable'
        question: 'My age is'
        input: 'text'
        input_style: 
          width: 85        
        required: false
      }, {
        tag: 'race.editable'
        question: 'My race is'
        input: 'text'
        required: false
      }, {
        tag: 'hispanic.editable'
        question: "I'm of Hispanic origin"
        input: 'dropdown'
        options:['No', 'Yes']
        required: false
      }, {
        tag: 'gender.editable'
        question: "My gender is"
        input: 'dropdown'
        options:['Female', 'Male', 'Transgender', 'Other']
        required: false
      }, {
        tag: 'home.editable'
        question: "My home is"
        input: 'dropdown'
        options:['Rented', 'Owned by me', 'Other']
        required: false
      }]




  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->

      header_style = 
        color: seattle2035_pink
        fontSize: 44
        #fontWeight: 600
        marginTop: 10

      section_style = 
        marginBottom: 20
        color: seattle2035_dark

      paragraph_heading_style = 
        display: 'block'
        #fontWeight: 600
        fontSize: 28
        color: seattle2035_pink

      paragraph_style = 
        fontSize: 18

      DIV
        style:
          position: 'relative'

        A 
          href: 'http://2035.seattle.gov/'
          target: '_blank'
          style: 
            display: 'block'
            position: 'absolute'
            top: 22
            left: 20
            color: seattle2035_pink

          I 
            className: 'fa fa-chevron-left'
            style: 
              display: 'inline-block'
              marginRight: 5

          '2035.seattle.gov'


        IMG
          style: 
            width: '100%'
            display: 'block'
            paddingTop: 50

          src: asset('seattle2035/banner.png')

        ProfileMenu()

        DIV 
          style: 
            borderTop: "5px solid #{seattle2035_pink}"
            padding: '20px 0'
            #marginTop: 50

          DIV 
            style: 
              width: HOMEPAGE_WIDTH()
              margin: 'auto'


            DIV 
              style: header_style

              'Let’s talk about how Seattle is changing'

            DIV 
              style: section_style

              # SPAN 
              #   style: paragraph_heading_style

              #   'Seattle is one of the fastest growing cities in America.'
              
              SPAN 
                style: paragraph_style
                  
                """
                Seattle is one of the fastest growing cities in America, expecting to add 
                120,000 people and 115,000 jobs by 2035. We must plan for how 
                and where that growth occurs.
                """

            DIV 
              style: section_style


              SPAN 
                style: paragraph_heading_style
                'The Seattle 2035 draft plan addresses Seattle’s growth'
              
              SPAN 
                style: paragraph_style
                'We are pleased to present a '

                A 
                  target: '_blank'
                  href: 'http://2035.seattle.gov'
                  style: 
                    textDecoration: 'underline'

                  'Draft Plan'

                """
                   for public discussion. The Draft Plan contains hundreds of 
                  policies that guide decisions about our city, including 
                  Key Proposals for addressing growth and change. 
                  These Key Proposals have emerged from conversations among 
                  City agencies and through """
                A 
                  target: '_blank'
                  href: 'http://www.seattle.gov/dpd/cs/groups/pan/@pan/documents/web_informational/p2262500.pdf'
                  style: 
                    textDecoration: 'underline'

                  'public input' 
                '.'


            DIV 
              style: section_style

              SPAN 
                style: paragraph_heading_style
                'We need your feedback on the Key Proposals in the Draft Plan'

              SPAN 
                style: paragraph_style

                """
                We have listed below some Key Proposals in the draft.
                Do these Key Proposals make sense for Seattle over the coming twenty years? 
                Please tell us by adding your opinion below. Your input will influence 
                the Mayor’s Recommended Plan, 
                """
                A
                  target: '_blank'
                  href: 'http://2035.seattle.gov/about/faqs/#how-long'
                  style: 
                    textDecoration: 'underline'
                  'coming in 2016 '
                '!'

            DIV 
              style: 
                #fontStyle: 'italic'
                marginTop: 20
                fontSize: 18
                color: seattle2035_dark

              DIV 
                style: 
                  marginBottom: 18
                "Thanks for your time,"

              A 
                href: 'http://www.seattle.gov/dpd/cityplanning/default.htm'
                target: '_blank'
                style: 
                  display: 'block'
                  marginBottom: 8

                IMG
                  src: asset('seattle2035/DPD Logo.svg')
                  style: 
                    height: 70


              DIV 
                style: _.extend {}, section_style,
                  margin: 0
                  marginTop: 10
                  fontSize: 18

                'p.s. Email us at '
                A
                  href: "mailto:2035@seattle.gov"
                  style: 
                    textDecoration: 'underline'

                  "2035@seattle.gov"
                """
                 if you would like us to add another Key Proposal below for 
                discussion or you have a comment about another issue in the Draft Plan.
                """

              DIV 
                style: 
                  marginTop: 40
                  backgroundColor: seattle2035_pink
                  color: 'white'
                  fontSize: 28
                  textAlign: 'center'
                  padding: "30px 42px"

                "The comment period is now closed. Thank you for your input!"


###################
# Foodcorps


FoodcorpsHeader = ReactiveComponent
  displayName: 'FoodcorpsHeader'

  render: -> 
    loc = fetch('location')

    homepage = loc.url == '/'

    DIV 
      style: 
        position: 'relative'
        height: 200

      IMG
        src: asset('foodcorps/logo.png')
        style:
          height: 160
          position: 'absolute'
          top: 10
          left: (WINDOW_WIDTH() - CONTENT_WIDTH()) / 2
          zIndex: 5


      DIV
        style:
          background: "url(#{asset('foodcorps/bg.gif')}) repeat-x"
          height: 68
          width: '100%'
          position: 'relative'
          top: 116
          left: 0

      A
        href: '/'
        style: 
          display: 'inline-block'
          fontSize: 43
          visibility: if homepage then 'hidden'
          verticalAlign: 'top'
          marginTop: 52
          marginLeft: 15
          color: 'white'
          zIndex: 10
          position: 'relative'
        '<'

      DIV 
        style: 
          position: 'absolute'
          top: 18
          right: 0
          width: 110

        ProfileMenu()
      


customizations['foodcorps'] = 
  point_labels : strengths_weaknesses
  slider_pole_labels : ready_not_ready
  show_slider_feedback: false

  HomepageHeader : FoodcorpsHeader
  NonHomepageHeader: FoodcorpsHeader

################
# sosh
customizations['sosh'] = 
  point_labels : strengths_weaknesses
  slider_pole_labels : yes_no
  show_slider_feedback: false

################
# schools
customizations['schools'] = 
  homie_histo_title: "Students' opinions"
  #point_labels : challenge_justify
  slider_pole_labels : agree_disagree

#################
# allsides

customizations['allsides'] = 
  'cluster/Classroom Discussions':
    homie_histo_title: "Students' opinions"
  'cluster/Civics':
    homie_histo_title: "Citizens' opinions"

  show_crafting_page_first: true
  show_histogram_on_crafting: false
  has_homepage: false

  homepage_heading_columns : [ 
    {heading: 'Questions', details: null}, \
    {heading: null}, \
    {heading: 'Community', details: null}, \
    {heading: '', details: ''}]

#################
# humanities-los

essential_questions = 
  homie_histo_title: "Student responses"
  slider_pole_labels: agree_disagree
  point_labels: challenge_justify

monuments = 
  point_labels : strengths_weaknesses
  slider_pole_labels : ready_not_ready
  homie_histo_title: "Students' feedback"


customizations['humanities-los'] = 

  show_slider_feedback: false

  point_labels : strengths_weaknesses
  slider_pole_labels : yes_no
  homie_histo_title: "Students' feedback"

  "cluster/Essential Questions 8-2": essential_questions

  "cluster/Essential Questions 8-1": essential_questions

  "cluster/Monuments 8-2" : monuments
  "cluster/Monuments 8-1" : monuments

#################
# RANDOM2015

customizations['anup2015'] = conference_config


customizations['random2015'] = _.extend {}, conference_config,
  opinion_value: (o) -> 3 * o.stance,
  "/proposal/2638" : 
    point_labels: strengths_limitations
    slider_pole_labels: yes_no
  "/proposal/2639" : 
    point_labels: strengths_weaknesses
    slider_pole_labels: yes_no
    
customizations['program-committee-demo'] = conference_config


# compute avg & std deviation of reviews & opinions
window.paper_scores = (paper) -> 
  stats = (vals) -> 
    sum = 0
    for o in vals
      sum += o
    avg = sum / vals.length
    diffs = vals.map (o) -> (o - avg) * (o - avg)

    sum = 0
    for diff in diffs
      sum += diff

    stddev = Math.sqrt(sum)

    {
      cnt: vals.length
      avg: avg
      stddev: stddev
    }

  scores = {}
  paper = fetch(paper)

  opinions = fetch(paper).opinions
  opinion_value = customization("opinion_value", paper)

  opinion_vals = opinions.map (o) -> opinion_value(o)

  scores.pc = stats(opinion_vals)


  reviews = []
  for field in $.parseJSON(paper.description_fields)
    continue if !field.label.match /Review/
    score = field.html.match(/Overall evaluation: ((-)?\d)/)
    reviews.push parseInt(score[1])

  scores.reviews = stats(reviews)

  scores

#################
# Relief International

customizations.ri = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree

#################
# Enviroissues

customizations.enviroissues = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree


  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      loc = fetch 'location'
      homepage = loc.url == '/'

      DIV
        style:
          width: CONTENT_WIDTH()
          margin: '20px auto'
          position: 'relative'

        A
          href: '/'
          style: 
            display: 'inline-block'
            fontSize: 43
            visibility: if homepage then 'hidden'
            verticalAlign: 'top'
            marginTop: 22
            marginRight: 15
            color: '#888'
          '<'


        IMG
          src: asset('enviroissues/logo.png')

        DIV 
          style: 
            position: 'absolute'
            top: 18
            right: 0
            width: 110

          ProfileMenu()

customizations.enviroissues.NonHomepageHeader = customizations.enviroissues.HomepageHeader

##############
# ECAST

ecast_highlight_color =  "#73B3B9"  #"#CB7833"
customizations.ecastonline = customizations['ecast-demo'] = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree

  ProposalNavigation: ProposalNavigationWithMenu
  docking_proposal_header : true

  additional_auth_footer: -> 

    auth = fetch('fetch')
    if auth.ask_questions && auth.form != 'edit profile'
      return DIV 
        style:
          fontSize: 13
          color: auth_text_gray
          padding: '16px 0' 
        """
        The demographic data collected from participants in this project will be used for research purposes, for 
        example, to identify the demographic and other characteristics of the people who participated in the 
        deliberation.  This information can be used in analyzing the results of this online forum.  
        No email addresses, demographic data, or personally-identifying information will be displayed to 
        other visitors to this site.  Any comments you submit will be identified only by the display name 
        you enter below.  By completing this registration, you acknowledge that your participation in this 
        project is entirely voluntary and you agree that the data provided may be used for research. If you 
        have any questions or concerns at any time, please 
        """
        A 
          href: 'mailto:info@ecastonline.org'
          target: "_blank"
          style: 
            textDecoration: 'underline'
           "Contact Us"
        "."
    else 
      SPAN null, ''

  auth: 

    user_questions : [
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

  homie_histo_title: "Citizens' opinions"


  NonHomepageHeader : ReactiveComponent
    displayName: 'NonHomepageHeader'

    render: ->
      DIV 
        style: 
          backgroundColor: 'black'
          width: '100%'
          position: 'relative'
          borderBottom: "2px solid #{ecast_highlight_color}"
          padding: "10px 0"
          backgroundImage: "url(#{asset('ecast/bg-small.png')})"
          height: 94

        A 
          href: "http://ecastonline.org/"
          target: '_blank'
          IMG 
            style: 
              height: 75
              position: 'absolute'
              left: 50
              top: 10

            src: asset('ecast/ecast-small.png')

        A 
          style: 
            fontSize: 30
            fontWeight: 600
            color: 'white'
            textShadow: '0 2px 4px rgba(0,0,0,.5)'       
            position: 'relative'
            top: 20
            left: 250 
          href: '/'
          "Informing NASA's Asteroid Initiative"

        DIV 
          style: 
            position: 'absolute'
            right: 0
            top: 14
            width: 110
          ProfileMenu()

  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render : ->
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

        DIV 
          style: 
            position: 'absolute'
            top: 30
            right: 0
            width: 110
          ProfileMenu()

styles += """
[subdomain="ecastonline"] .simplehomepage a.proposal, [subdomain="ecast-demo"] .simplehomepage a.proposal{
  border-color: #{ecast_highlight_color} !important;
  color: #{ecast_highlight_color} !important;
}
"""


####################
# Bitcoin


passes_tags = (user, tags) -> 
  if typeof(tags) == 'string'
    tags = [tags]
  user = fetch(user)

  passes = true 
  for tag in tags 
    passes &&= user.tags[tag] && \
     !(user.tags[tag].toLowerCase() in ['no', 'false'])
  passes 




customizations.fidoruk = 
  collapse_descriptions_at: 300

  civility_pledge: true

  show_score: false

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

  HomepageHeader: ReactiveComponent
    displayName: 'ShortHeader'

    render: ->
      subdomain = fetch '/subdomain'   
      loc = fetch 'location'

      hsl = parseCssHsl(subdomain.branding.primary_color)
      is_light = hsl.l > .75

      homepage = loc.url == '/'

      DIV 
        style:
          minHeight: 70

        ProfileMenu()


        DIV
          style: 
            width: (if homepage then HOMEPAGE_WIDTH() else BODY_WIDTH() ) + 130
            margin: 'auto'


          A
            href: '/'
            style: 
              display: 'inline-block'
              color: if !is_light then 'white'
              fontSize: 43
              visibility: if homepage || !customization('has_homepage') then 'hidden'
              verticalAlign: 'middle'
              marginTop: 5
            '<'


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


customizations.fidoruk.NonHomepageHeader = customizations.fidoruk.HomepageHeader


customizations.bitcoin = 
  show_proposer_icon: true
  collapse_descriptions_at: 300

  civility_pledge: true

  slider_pole_labels: support_oppose

  show_score: true

  'cluster/Blocksize Survey': 
    show_crafting_page_first: false

    slider_handle: slider_handle.triangley
    slider_ticks: true
    discussion: false
    show_score: false
    slider_pole_labels: 
      individual: 
        support: ''
        oppose: ''
        support_sub: ''
        oppose_sub: ''
      group: 
        support: ''
        oppose: ''
        support_sub: ''
        oppose_sub: ''

      # slider_feedback: (value, proposal) -> 
      #   value += 1
      #   value /= 2

      #   val = Math.pow(2, 4 * value).toFixed(1)

      #   if val > 16
      #     "greater than 16mb"
      #   else 
      #     "#{val}mb"


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

  auth:   
    user_questions : [
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
  HomepageHeader: ReactiveComponent
    displayName: 'ShortHeader'

    render: ->
      subdomain = fetch '/subdomain'   
      loc = fetch 'location'

      hsl = parseCssHsl(subdomain.branding.primary_color)
      is_light = hsl.l > .75

      homepage = loc.url == '/'

      DIV 
        style:
          backgroundColor: subdomain.branding.primary_color
          minHeight: 70

        ProfileMenu()


        DIV
          style: 
            width: (if homepage then CONTENT_WIDTH() else BODY_WIDTH() ) + 130
            margin: 'auto'


          A
            href: '/'
            style: 
              display: 'inline-block'
              color: if !is_light then 'white'
              fontSize: 43
              visibility: if homepage || !customization('has_homepage') then 'hidden'
              verticalAlign: 'middle'
              marginTop: 5
            '<'


          if subdomain.branding.logo
            A 
              href: if subdomain.external_project_url then subdomain.external_project_url
              style: 
                verticalAlign: 'middle'
                marginLeft: 35
                display: 'inline-block'
                fontSize: 0
                cursor: if !subdomain.external_project_url then 'default'

              IMG 
                src: subdomain.branding.logo
                style: 
                  height: 56

          if subdomain.branding.masthead_header_text || (if !subdomain.branding.logo then subdomain.app_title else null)
            text = subdomain.branding.masthead_header_text || subdomain.app_title
            DIV 
              style: 
                color: if !is_light then 'white'
                marginLeft: 35
                fontSize: 32
                fontWeight: 400
                display: 'inline-block'
                verticalAlign: 'middle'
                marginTop: 5

              text

              DIV
                style: 
                  paddingBottom: 10
                  fontSize: 14
                  color: '#444'

                "Interested in running a node that mirrors consider.it data to provide an audit trail? "

                A 
                  href: 'https://www.reddit.com/r/Bitcoin_Classic/comments/435gi1/distributed_publicly_auditable_data_for/'
                  target: '_blank'
                  style: 
                    textDecoration: 'underline'

                  "Learn more"











customizations['on-chain-conf'] = _.extend {}, 
  opinion_filters: customizations.bitcoin.opinion_filters
  auth: customizations.bitcoin.auth
  show_proposer_icon: false
  collapse_descriptions_at: 300
  show_meta: false 

  proposal_filters: true
  civility_pledge: true

   

  'cluster/On-chain scaling': 
    slider_pole_labels: interested

  'cluster/Other topics': 
    slider_pole_labels: interested


  HomepageHeader: ReactiveComponent 
    displayName: 'HomepageHeader'

    render: ->
      homepage = fetch('location').url == '/'

      DIV
        style:
          position: 'relative'
          backgroundColor: '#272727'
          overflow: 'hidden'
          paddingBottom: 60
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
            #width: HOMEPAGE_WIDTH()
            margin: 'auto'
            textAlign: 'center'


          IMG
            style: 
              position: 'relative'
              top: -50
              zIndex: 3
              width: '100%'
            src: asset('bitcoin/OnChainConferences.svg')


          DIV 
            style: 
              position: 'absolute'
              left: 0
              top: 0
              height: '70%'
              width: '100%'
              background: 'linear-gradient(to bottom, rgba(0,0,0,.97) 0%,rgba(0,0,0,0.65) 85%,rgba(0,0,0,0) 100%)'
              zIndex: 2

          IMG 
            style: 
              position: 'absolute'
              zIndex: 1
              width: '160%'
              top: 45
              left: '-30%'
            src: asset('bitcoin/rays.png') 


          DIV 
            style: 
              marginLeft: -70
              paddingTop: 30
              position: 'absolute'
              zIndex: 3
            SPAN
              style:
                display: 'inline-block'
                visibility: if homepage then 'hidden'
                color: 'white'
                position: 'relative'
                left: -60
                top: -10
                fontSize: 43
                fontWeight: 400
                paddingLeft: 25 # Make the clickable target bigger
                paddingRight: 25 # Make the clickable target bigger
                cursor: if not homepage then 'pointer'
              onClick: if not homepage then => loadPage('/')

              '<'

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

                'Upcoming: May 27-29, 2-day online conference about on-chain scaling'
                
              DIV 
                style:
                  fontSize: 18

                'Express your preferences below. '



          # DIV 
          #   style:
          #     fontSize: 24
          #     fontStyle: 'italic'
          #     fontWeight: 600
          #     display: 'inline-block'
          #     margin: 'auto'
          #   DIV 
          #     style: 
          #       color: '#A9556D'
          #     'You identify topics you want to learn more about.'
          #   DIV 
          #     style: 
          #       color: '#B1BC83'
          #     'We organize events that match speakers with topics.'

            # if homepage 


        ProfileMenu()


customizations['on-chain-conf'].NonHomepageHeader = customizations['on-chain-conf'].HomepageHeader

















customizations.bitcoinclassic = _.extend {}, 
  opinion_filters: customizations.bitcoin.opinion_filters
  auth: customizations.bitcoin.auth
  show_proposer_icon: false
  collapse_descriptions_at: 300

  proposal_filters: true

  civility_pledge: true


  'cluster/Scrapped proposals': 
    archived: true

  'cluster/Closed pull requests': 
    archived: true


  HomepageHeader: ReactiveComponent 
    displayName: 'HomepageHeader'

    render: ->
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
            SPAN
              style:
                display: 'inline-block'
                visibility: if homepage then 'hidden'
                color: '#eee'
                position: 'relative'
                left: -60
                top: -10
                fontSize: 43
                fontWeight: 400
                paddingLeft: 25 # Make the clickable target bigger
                paddingRight: 25 # Make the clickable target bigger
                cursor: if not homepage then 'pointer'
              onClick: if not homepage then => loadPage('/')

              '<'

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

        ProfileMenu()


customizations.bitcoinclassic.NonHomepageHeader = customizations.bitcoinclassic.HomepageHeader


customizations['bitcoinfoundation'] = 

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

  # auth:   
  #   user_questions : [
  #     {
  #       tag: 'bitcoin_foundation_member.editable'
  #       question: 'I am a member of the Bitcoin Foundation'
  #       input: 'dropdown'
  #       options:['No', 'Yes']
  #       required: true
  #     }]
  civility_pledge: true

  # default proposal options
  show_proposer_icon: true
  homie_histo_title: "Votes"
  collapse_descriptions_at: 300

  slider_pole_labels: support_oppose  

  'cluster/First Foundation': 
    slider_pole_labels: support_oppose
    description: 
      DIV null, 
        'Archived proceedings of the First Foundation'
    archived: true

  show_crafting_page_first: true



#####################
# Living Voters Guide

ZipcodeBox = ReactiveComponent
  displayName: 'ZipcodeBox'
  render: ->
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

customizations.livingvotersguide = 

  civility_pledge: true

  slider_pole_labels: support_oppose

  #ProposalNavigation: ProposalNavigationWithMenu
  #docking_proposal_header : true

  'cluster/Advisory votes': 
    archived: true
    description: 
      DIV null,
        "Advisory Votes are not binding. They are a consequence of Initiative 960 passing in 2007"

  ThanksForYourOpinion: ReactiveComponent
    displayName: 'ThanksForYourOpinion'

    render: ->

      if @proposal.category && @proposal.designator
        tweet = """Flex your civic muscle on #{@proposal.category.substring(0,1)}-
                   #{@proposal.designator}! Learn about the issue and decide here: """
      else 
        tweet = """Learn and decide whether you will support \'#{@proposal.name}\' 
                   on your Washington ballot here:"""
      DIV 
        style: 
          position: 'fixed'
          left: 0
          bottom: 0
          width: '100%'
          backgroundColor: 'rgb(0,182,236)'
          padding: '5px 10px'
          color: 'white'
          zIndex: 999
          textAlign: 'center'
          fontWeight: 600
          fontSize: 18

        'Thanks for your opinion! Invite your friends and family: '
        SPAN style: {position: 'relative', top: 5, marginLeft: 5},
          FBShare()
          Tweet
            text: tweet
            url: "https://livingvotersguide.org/#{@proposal.slug}?results=true"


  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      LVG_blue = '#063D72'
      LVG_green = '#A5CE39'

      homepage = fetch('location').url == '/'

      DIV 
        style: 
          position: 'relative'

        DIV 
          style: 
            height: if !homepage then 150 else 455 
            backgroundImage: "url(#{asset('livingvotersguide/bg.png')})"
            backgroundPosition: 'center'
            backgroundSize: 'cover'
            backgroundColor: LVG_blue
            textAlign: if homepage then 'center'

          DIV
            style:
              position: 'absolute'
              right: 17
              top: 17
            ProfileMenu({style: {height: 69, left: 0; top: 0, position: 'relative', display: 'inline-block'}})
            SPAN style: {color: 'white'}, '   |   '
            A href:'/about', style: {color: 'white', cursor: 'pointer'},
              'About'
            
          if !homepage 
            A
              href: '/'
              style: 
                position: 'absolute'
                display: 'inline-block'
                top: 40
                left: 22
                fontSize: 43
                color: 'white'
              '<' 

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


  Footer : ReactiveComponent
    displayName: 'Footer'
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

customizations.livingvotersguide.NonHomepageHeader = customizations.livingvotersguide.HomepageHeader

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


styles += """
[subdomain="livingvotersguide"] .endorser_group {
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
    padding-top: 6px; }

"""


#####################
# Tigard
customizations.tigard = 

  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      DIV style: {textAlign: 'center'},
        STYLE null, 
          '.banner_link {color: #78d18b; font-weight: 600; text-decoration: underline;}'

        ProfileMenu()

        DIV 
          style: 
            color: '#707070'
            fontSize: 32
            padding: '20px 0'
            margin: '0px auto 0 auto'
            fontWeight: 800
            textTransform: 'uppercase'
            position: 'relative'
            width: CONTENT_WIDTH()
          'Help plan '
          A className: 'banner_link', href: 'http://riverterracetigard.com/', 'River Terrace'
          ', Tigard\'s newest neighborhood' 


#customizations.tigard.NonHomepageHeader = customizations.tigard.HomepageHeader


customizations.mos = 

  slider_pole_labels :
    individual: 
      support: 'Support'
      support_sub: 'the ban'
      oppose: 'Oppose'
      oppose_sub: 'the ban'
    group: 
      support: 'Supporters'
      support_sub: 'of the ban'      
      oppose: 'Opposers'
      oppose_sub: 'of the ban'

  show_crafting_page_first: true

customizations['ama-rfs'] = 
  show_proposer_icon: true


##########
# Fill in default values for each unspecified field for 
# each subdomain customization
for own k,v of customizations
  _.defaults customizations[k], customizations.default

  customizations[k].key = "customizations/#{k}"
  save customizations[k]
