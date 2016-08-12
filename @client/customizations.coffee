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
  
  if !!object_or_key && !object_or_key.key?
    object_or_key = fetch object_or_key


  if object_or_key && object_or_key.subdomain_id
    subdomain = fetch "/subdomain/#{object_or_key.subdomain_id}" 
  else 
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
window.customizations = {}



require './browser_location' # for loadPage
require './shared'
require './footer'
require './profile_menu'
require './slider'
require './header'
require './homepage'



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


relevance = 
  support: 'Big impact!'
  oppose: 'No impact on me'    

priority = 
  support: 'High Priority'
  oppose: 'Low Priority'    



interested = 
  support: 'Interested'
  oppose: 'Uninterested'    

important_unimportant = 
  support: 'Important'
  oppose: 'Unimportant'    


yes_no = 
  support: 'Yes'
  oppose: 'No'    

strong_weak = 
  support: 'Strong'
  oppose: 'Weak'    

promising_weak = 
  support: 'Promising'
  oppose: 'Weak'    


ready_not_ready = 
  support: 'Ready'
  oppose: 'Not ready'

agree_disagree = 
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


plus_minus = 
  support: '+'
  oppose: '–'

effective_ineffective = 
  support: 'Effective'
  oppose: 'Ineffective'


desacuerdo_acuerdo = 
  support: 'Acuerdo'
  oppose: 'Desacuerdo'

port_agree_disagree = 
  support: 'Concordo'
  oppose: 'Discordo'



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

  # Other options
  additional_auth_footer: false
  civility_pledge: false
  has_homepage: true

  cluster_order: []
  clusters_to_always_show: []


  auth: 
    user_questions: []

  Homepage : SimpleHomepage

  # HomepageHeader : DefaultHeader
  # NonHomepageHeader: ShortHeader

  Footer : DefaultFooter




##########################
# SUBDOMAIN CONFIGURATIONS




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
    support: 'YAAAAAAS'
    oppose: 'Hellz No!'





customizations['swotconsultants'] = 
  cluster_order: ['Strengths', 'Weaknesses', 'Opportunities', 'Threats']


customizations['carcd'] = customizations['carcd-demo'] = 
  show_proposer_icon: false
  proposal_filters: false

  point_labels: pro_con
  slider_pole_labels: priority
  show_slider_feedback: false

  cluster_order: ['Serving Districts', 'Program Emphasis', 'Lagging Districts', 'Accreditation', \
                  'Questions', "CARCD's role in Emerging Resources", \
                  "CARCD's role in Regional Alignment", \
                  "CARCD's Role for the Community"]


customizations['consider'] = 
  #show_proposer_icon: true
  proposal_filters: false 
  opinion_filters: false 

  "cluster/Bug Reports" : 
    slider_pole_labels: relevance
    show_slider_feedback: false
    discussion: false
    one_line_desc: "Include your browser and device!"

  # opinion_filters: [ {
  #     label: 'consider.it staff'
  #     tooltip: null
  #     pass: (user) -> user.key in ['/user/1701', '/user/1707', '/user/30970']
  #   }]


  "cluster/Hard Tasks" : 
    slider_pole_labels: important_unimportant
    show_slider_feedback: false
    one_line_desc: "What tasks should we make significantly easier?"
        

customizations['us'] = 
  show_proposer_icon: true

customizations['cimsec'] = 
  slider_pole_labels : effective_ineffective



customizations['tunisia'] = 
  proposal_filters: false
  show_meta: false
  lang: 'tun_ar'
  slider_pole_labels: 
    support: 'أوافق'
    oppose: 'أخالف'

  homie_histo_title: 'الآراء'
  point_labels:  
    pro: 'نقطة إجابية'
    pros: 'نقاط إجابية' 
    con: 'نقطة سلبية'
    cons: 'نقاط سلبية'
    your_header: "--valences-- أبد" 
    other_header: "--valences--  أخرى" 
    top_header: "--valences--  الرئيسية" 


portuguese = ['sintaj', 'delegados_sintaj']

for port in portuguese
  customizations[port] = 
    lang: 'ptbr'
    point_labels : port_pros_cons
    slider_pole_labels : port_agree_disagree
    homie_histo_title: "Opiniões"
    show_slider_feedback: false
    proposal_filters: false 

spanish = ['vacabacana', 'alcala', 'villagb', 'citysens', 'iniciativasciudadanas', 'afternext', \
           'movilidadcdmx', 'zonaq', 'valenciaencomu', 'aguademayo', 'eparticipa', 'theartofco', 'educacion2025']

for spa in spanish
  customizations[spa] = 
    lang: 'spa'
    point_labels : pros_contras
    slider_pole_labels : desacuerdo_acuerdo
    homie_histo_title: "Opiniones"
    show_slider_feedback: false
    proposal_filters: false 

french = ['fr']

for fr in french
  customizations[fr] = 
    lang: 'french'
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

    homie_histo_title: "Des avis"
    show_slider_feedback: false
    proposal_filters: false 






###############
# Monitorinstitute


customizations['monitorinstitute'] = 
  point_labels : strengths_improvements
  slider_pole_labels : strong_weak
  homie_histo_title: "Opinions"
  show_slider_feedback: false

  cluster_order: ['Intellectual Agenda Items', 'Overall']

################
# seattle HALA

hala_teal = "#0FB09A"
hala_orange = '#FBAF3B'
hala_magenta = '#CB2A5C'
hala_gray = '#444'
hala_brown = '#A77C53'

hala_section_heading = 
  fontSize: 42
  fontWeight: 300
  color: hala_teal
  marginBottom: 5

hala_section_description = 
  fontSize: 18
  fontWeight: 400 
  #fontStyle: 'italic' 
  color: hala_gray


cluster_link = (href, anchor) ->
  anchor ||= href 
  "<a href='#{href}' target='_blank' style='text-decoration:underline'>#{anchor}</a>"

customizations['hala'] = 
  point_labels : pro_con
  slider_pole_labels : agree_disagree
  homie_histo_title: "Opinions"
  show_proposer_icon: false
  show_meta: false 
  civility_pledge: true
  show_score: true
  proposal_filters: false

  uncollapseable: true

  cluster_order: ['Preservation of Existing Affordable Housing',  'Urban Village Expansion', 'Historic Areas and Unique Conditions', 'Housing Options and Community Assets', 'Transitions', 'Urban Design Quality', 'Fair Chance Housing', 'Minimize Displacement']


  opinion_filters: ( -> 
    filters = 
      [ {
        label: 'focus group'
        tooltip: null
        pass: (user) -> passes_tags(user, 'hala_focus_group')
      }] 

    for home in ['Rented', 'Owned by me', 'Other']

      filters.push 
        label: "Home:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['home.editable'] == home 

    for home in ['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']

      filters.push 
        label: "Housing_type:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['housing_type.editable'] == home 

    for age in [0, 25, 35, 45, 55, 65]
      if age == 0 
        label = 'Age:0-25'
      else if age == 65
        label = 'Age:65+'
      else 
        label = "Age:#{age}-#{age+10}"

      filters.push 
        label: label
        tooltip: null 
        pass: do(age) -> (user) -> 
          u = fetch(user)
          u.tags['age.editable'] && parseInt(u.tags['age.editable']) >= age && parseInt(u.tags['age.editable']) < age + 10


    return filters 
    )()


  label_style: 
    color: hala_teal

  "cluster/Preservation of Existing Affordable Housing" : 

    homepage_label: 'Guidelines'
    label: "Preservation of Existing Affordable Housing"
    description: [
          """There are many buildings and other types of housing in Seattle that currently offer affordable rents. 
             In this set of questions, we are using the term "preservation" to describe retaining affordable rents 
             in existing buildings that are currently unsubsidized. In the next section, we address historic 
             preservation in the context of Mandatory Housing Affordability (MHA). We will be using the term AMI or Area Median Income. 
             For Seattle, here is a snapshot of those: 60% of AMI in 2016 is $37,980 annually for an individual, 
             $54,180 for a family of four. 
             See #{cluster_link('http://www.seattle.gov/Documents/Departments/Housing/PropertyManagers/IncomeRentLimits/Income-Rent-Limits_Rental-Housing-HOME.pdf','detailed numbers')}."""
          "What do you think of the following guidelines?"
        ]


  "cluster/Urban Village Expansion" : 

          
    homepage_label: 'Guidelines'
    label: "Urban Village Expansion Areas"
    description: [
      """Urban Villages are areas where there is a high density of essential services like 
         high quality transportation options, parks, employment, shopping and other amenities 
         that make it possible for residents to reduce their reliance on cars. It also means 
         that investments made in those neighborhoods are maximized because they are enjoyed 
         by the greatest number of people. Currently, the City is proposing to expand some 
         Urban Village boundaries to reflect improvements and increases in services in those 
         areas like the recent addition of light rail stations. To learn more about Urban 
         Villages, see the resources below:
         <ul style='padding-left:40px'>
            <li>#{cluster_link('http://seattlecitygis.maps.arcgis.com/apps/MapTools/index.html?appid=2c698e5c81164beb826ba448d00e5cf0', 'Interactive Map of Seattle’s Urban Villages')}</li>
            <li>#{cluster_link('http://www.seattle.gov/dpd/cs/groups/pan/@pan/documents/web_informational/dpdd016663.pdf', 'Urban Village Element in Seattle’s Comprehensive Plan' )}</li>
         </ul>
      """
      "What do you think of the following guidelines?"
    ]


  "cluster/Historic Areas and Unique Conditions" : 

          
    homepage_label: 'Guidelines'
    label: "Historic Areas and Unique Conditions"
    description: [
      """Seattle has many historic areas, some on the National Register and some known to locals 
         as places of historic or cultural significance.  As a community we have defined these areas, 
         in code and in practice, and their special heritage in our community."""

      "What do you think of the following guidelines?"
    ]



  "cluster/Housing Options and Community Assets" : 
    homepage_label: 'MHA Principles'    

    description: ->  
      DIV 
        style: 
          width: HOMEPAGE_WIDTH()

        DIV 
          style: _.extend {}, hala_section_heading, 
            color: hala_brown
            fontSize: 42
            fontWeight: 400
            #marginLeft: -30
            

          SPAN 
            style: 
              borderBottom: "1px solid #{hala_brown}"
              color: hala_brown

            "Mandatory Housing Affordability "

            SPAN 
              style: 
                fontStyle: 'italic'
              "Principles"



        DIV 
          style: hala_section_description

          """Mandatory Housing Affordability (MHA) would require all new commercial and multifamily development either to 
             include affordable housing on site or make an in-lieu payment for affordable 
             housing using a State-approved approach. In exchange for the new affordable 
             housing requirement, additional development capacity will be granted in 
             the form of zoning changes. A community input process will help inform details 
             and location of the zoning changes to implement MHA. The MHA program is a 
             cornerstone of the """

          A 
            href: 'http://www.seattle.gov/hala/about'
            target: '_blank'
            style: 
              color: hala_teal
              textDecoration: 'underline'

            'Grand Bargain' 


          """ and is essential to achieving affordable 
             housing goals of 6,000 new affordable units over ten years. """

        DIV 
          style: _.extend {}, hala_section_description, 
            fontStyle: 'italic'
            marginTop: 20

          """The questions below assume that zoning changes will take place to fully implement MHA.  
             We are asking for input on how those zoning changes will look and feel.  These questions 
             are intended to get at the values that should drive these zoning changes.  What are the 
             important principles for us to keep in mind when we propose zoning changes in the next few months? 
             Bear in mind, the following elements are only a portion of the MHA. We will continue adding 
             pieces as they become available."""


        DIV 
          style: _.extend {}, hala_section_heading,
            marginTop: 20

          "Housing Options and Community Assets"


        DIV 
          style: hala_section_description
            
          "What do you think of the following principles?"




  "cluster/Transitions" : 
    homepage_label: 'MHA Principles'    
    label: "Transitions"
    description: [
      """When taller buildings are constructed in areas that are zoned for more density, 
         neighboring buildings that are smaller sometimes feel out of place. Zoning 
         regulations can plan for transitions between higher- and lower-scale zones as 
         Seattle grows and accommodates new residents and growing families."""
      "What do you think of the following principles?"
    ]

  "cluster/Urban Design Quality" : 
    homepage_label: 'MHA Principles'    
    label: "Urban Design Quality"
    description: [
      """As Seattle builds new housing, we want to know what design features are 
         important to you. These elements address quality of life with design choices 
         for new residential buildings and landscaping."""
      "What do you think of the following principles?"
    ]


  "cluster/Minimize Displacement" : 

    archived: true
    uncollapseable: false
    homepage_label: 'Displacement proposal (archived)'
    label: "Minimize Displacement"
    description: """Displacement is happening throughout Seattle, and particular communities 
                    are at high risk of displacement. Data analysis and community outreach will 
                    help identify how growth may benefit or burden certain populations. We will 
                    use that data to make sure our strategies are reaching the communities most 
                    in need."""


  "cluster/Fair Chance Housing" : 
    archived: true
    homepage_label: 'Guidelines (archived)'    
    uncollapseable: false
    description: ->  
      DIV 
        style: 
          width: HOMEPAGE_WIDTH()

        DIV 
          style: _.extend {}, hala_section_heading, 
            color: hala_brown
            fontSize: 42
            fontWeight: 400
            #marginLeft: -30
            

          SPAN 
            style: 
              borderBottom: "1px solid #{hala_brown}"
              color: hala_brown

            "HALA phase 1 discussion archive"

        DIV 
          style: _.extend {}, hala_section_description,
            marginBottom: 50

          "We're working on summarizing what we heard from phase 1, which will be posted "

          A 
            href: 'http://www.seattle.gov/hala/your-thoughts'
            target: '_blank'
            style: 
              color: hala_teal
              textDecoration: 'underline'

            'here'

          '.'


        DIV 
          style: hala_section_heading

          "Fair Chance Housing legislation"


        DIV 
          style: hala_section_description

          """Fair Chance Housing legislation is aimed at increasing access to Housing for 
             People with Criminal History. 
             An estimated one in every three adults in the United States has a criminal 
             record, and nearly half of all children in the U.S. have one parent with a 
             criminal record. Due to a rise in the use of criminal background checks during 
             the tenant screening process, people with arrest and conviction records face 
             major barriers to housing. Fair Chance Housing legislation could lessen some of 
             the barriers people face."""


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
      #   tag: 'hispanic.editable'
      #   question: "I'm of Hispanic origin"
      #   input: 'dropdown'
      #   options:['No', 'Yes']
      #   required: false
      # }, {
      #   tag: 'gender.editable'
      #   question: "My gender is"
      #   input: 'dropdown'
      #   options:['Female', 'Male', 'Transgender', 'Other']
      #   required: false
      # }, {
        tag: 'home.editable'
        question: "My home is"
        input: 'dropdown'
        options:['Rented', 'Owned by me', 'Other']
        required: false
      }, {
        tag: 'housing_type.editable'
        question: "I live in"
        input: 'dropdown'
        options:['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']
        required: false
      }



     ]

  additional_auth_footer: -> 

    auth = fetch('auth')
    if auth.ask_questions && auth.form in ['create account', 'create account via invitation', 'user questions']
      return DIV 
        style:
          fontSize: 13
          color: auth_text_gray
          padding: '16px 0' 
        """
        We are collecting this information to find out if this tool is 
        truly reaching the diverse population that reflects our city. Thank you!
        """
    else 
      SPAN null, ''


customizations['bradywalkinshaw'] = 
  point_labels : pro_con
  slider_pole_labels : agree_disagree
  homie_histo_title: "Opinions"
  show_proposer_icon: true
  show_meta: false 
  civility_pledge: true
  show_score: false
  proposal_filters: false

  label_style:
    color: hala_teal

  cluster_filters: 
    'Economy': ['Economics']
    'Environment': ['Environment']
    'Education': ['Education']
    'Civil Rights': ['Civil Rights']

  "cluster/Civil Rights" : 
    homepage_label: 'Planks' 
    uncollapseable: true   

    label: "Civil Rights for the 21st Century"

    description: [
      "The son of a Cuban immigrant, Brady Piñero Walkinshaw will be Washington State’s first Latino and openly-gay member of Congress. He grew up in a rural farming community in Washington State, attended Princeton University with support from financial aid, and has worked professionally to create economic opportunity in the developing world.  As a State Representative, he brought together Republicans and Democrats to pass legislation to expand affordable housing, improve transportation, and increase healthcare and mental health services.  At 32 years old, Brady represents a new generation of positive Progressive leadership that will get things done in Congress for years to come. He’ll be a Progressive voice on national issues like climate change and focus on delivering for our local priorities."
      "Brady has the background and life experiences to represent this region’s unique diversity and be a voice for our community. His mother’s family were poor immigrants from Cuba seeking a better life and opportunity, and he will work to pass immigration reform to bring millions of immigrants out of the shadows. As a married gay man, Brady recognizes that the movement for social justice must continue to protect everyone’s civil rights. As the first person of color to represent our district in Congress, Brady will fight to end discrimination in the workplace, schools and our justice system."
      "The next generation of leadership in our country must continue the heroic efforts of those who have come before us to secure justice for every American, regardless of gender, orientation, race, economic status, or even citizenship status. We need leaders that reflect the diversity of our nation and understand from personal experience that our diversity is our greatest strength."
    ]


  "cluster/Economics" : 
    homepage_label: 'Planks' 
    uncollapseable: true   

    label: "Economic Leadership for the 21st Century"
    description: [
      "America’s next generation of leaders must balance our pace of growth with our core Progressive values, and there are few regions where this divide is more visible than Washington’s 7th district."
      "Our community has both an opportunity and the obligation to build innovative, community-based solutions to address the climate crisis. The first step in that process is supporting policies that transition our nation to a low-carbon economy – to halt the debilitating impact of climate change, keep our region pristine and beautiful, and spur a new wave of economic growth for the 21st Century."
      "Addressing climate change head on is a necessity. Our region has the values, the commitment, and the talent to build innovative reforms that can transform our economy and lead the global community in taking action."
      "Washington state is blessed with stunning nature, clean energy and an unparalleled quality of life that attracts innovative employers and highly skilled workers. We are fortunate to boast a strong economic base across diverse industries, and to serve as home to some of the world’s leading innovative companies. The next generation of leadership in this country must focus on continuing growth that generates prosperity while ensuring that every American has access to the opportunities and resources they need to share in prosperity."
      "Our economy should work for all of us, not just a wealthy few, and our region has all the tools we need to lead the nation in both innovation industries and equality for all our residents. We must generate a healthy economy that expands access to opportunity and jobs that pay a living wage."            
      "What do you think of the following planks? Click into any of them to read details and discuss."
    ]

  "cluster/Education" : 
    homepage_label: 'Planks' 
    uncollapseable: true   

    label: "Education Leadership for the 21st Century"
    description: [
      """Education and academic research are key to the future of our country, and we need to do everything in our power to support students as they prepare to compete in the global economy. Financial obstacles continue to restrict students from becoming the first in their families to go to college, and we must ensure that higher education is accessible for every single student."""
      "What do you think of the following planks? Click into any of them to read details and discuss."
    ]

  "cluster/Environment" : 
    homepage_label: 'Planks'    
    uncollapseable: true  
    label: "Environmental Leadership for the 21st Century"
    description: [
          """Brady is committed to forward-looking policies and will make fighting climate change his top priority.  He will fight for our Progressive values and bring Republicans and Democrats together to get things done, like investing in transportation and public transit improvements – such as light rail and express bus services – to reduce carbon emissions and improve our quality of life."""
          "What do you think of the following planks? Click into any of them to read details and discuss."
    ]



################
# engageseattle

engageseattle_teal = "#67B5B5"

customizations['engageseattle'] = 
  point_labels : pro_con
  slider_pole_labels : agree_disagree
  homie_histo_title: "Opinions"
  show_proposer_icon: true
  show_meta: true 
  civility_pledge: true
  show_score: true
  proposal_filters: false

  uncollapseable: true

  cluster_order:          ['Value in engagement',  'Meeting preferences', 'Community Involvement Commission', 'Community Involvement Commission Roles', 'Engagement Ideas']
  clusters_to_always_show: ['Value in engagement',  'Meeting preferences', 'Community Involvement Commission', 'Community Involvement Commission Roles', 'Engagement Ideas']

  label_style:
    color: engageseattle_teal

  opinion_filters: ( -> 
    filters = 
      [ {
        label: 'focus group'
        tooltip: null
        pass: (user) -> passes_tags(user, 'hala_focus_group')
      }] 

    for home in ['Rented', 'Owned by me', 'Other']

      filters.push 
        label: "Home:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['home.editable'] == home 

    for home in ['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']

      filters.push 
        label: "Housing_type:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['housing_type.editable'] == home 

    for age in [0, 25, 35, 45, 55, 65]
      if age == 0 
        label = 'Age:0-25'
      else if age == 65
        label = 'Age:65+'
      else 
        label = "Age:#{age}-#{age+10}"

      filters.push 
        label: label
        tooltip: null 
        pass: do(age) -> (user) -> 
          u = fetch(user)
          u.tags['age.editable'] && parseInt(u.tags['age.editable']) >= age && parseInt(u.tags['age.editable']) < age + 10


    return filters 
    )()



  "cluster/Value in engagement" : 
    cluster_header: -> 
      DIV style: height: 18

    show_new_proposal_button: false
    homepage_label: 'Values'
    label: "What do you value when engaging with the City about issues in your community, such as at public meetings?"


  "cluster/Meeting preferences" : 
    cluster_header: -> 
      DIV style: height: 18

    show_new_proposal_button: false
    homepage_label: 'Preferences'
    label: "How do you like to meet and what do you want to talk about?"


  "cluster/Community Involvement Commission" : 

    show_new_proposal_button: false
    cluster_header: -> 
      DIV style: height: 18

    label: 'Community Involvement Commission'
    description: """A Community Involvement Commission could be established to create a more inclusive and 
                   representative process for decision-making. Your comments are needed to help develop the 
                   charter and membership of the Commission. """


  "cluster/Community Involvement Commission Roles" : 
          
    homepage_label: 'Roles'

    label_style: 
      fontSize: 34
      fontWeight: 300
      color: '#666'
      marginBottom: 5

    label: "What additional roles, if any, should the Community Involvement Commission undertake?"


  "cluster/Engagement Ideas" : 
          
    homepage_label: 'Your ideas'
    label: "What’s your big idea on how the City can better engage with residents?"




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
      #   tag: 'hispanic.editable'
      #   question: "I'm of Hispanic origin"
      #   input: 'dropdown'
      #   options:['No', 'Yes']
      #   required: false
      # }, {
      #   tag: 'gender.editable'
      #   question: "My gender is"
      #   input: 'dropdown'
      #   options:['Female', 'Male', 'Transgender', 'Other']
      #   required: false
      # }, {
        tag: 'home.editable'
        question: "My home is"
        input: 'dropdown'
        options:['Rented', 'Owned by me', 'Other']
        required: false
      }, {
        tag: 'housing_type.editable'
        question: "I live in"
        input: 'dropdown'
        options:['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']
        required: false
      }



     ]

  additional_auth_footer: -> 

    auth = fetch('auth')
    if auth.ask_questions && auth.form in ['create account', 'create account via invitation', 'user questions']
      return DIV 
        style:
          fontSize: 13
          color: auth_text_gray
          padding: '16px 0' 
        """
        We are collecting this information to find out if this tool is 
        truly reaching the diverse population that reflects our city. Thank you!
        """
    else 
      SPAN null, ''





























customizations['cir'] = 
  slider_pole_labels : important_unimportant
  homie_histo_title: "Opinions"
  show_proposer_icon: false
  show_meta: true 
  civility_pledge: true
  show_score: false
  proposal_filters: false

  uncollapseable: true

  label_style:
    color: '#159ed9'

  cluster_order: ['Questions']
  clusters_to_always_show: ['Questions']


  "cluster/Questions" : 
          
    homepage_label: 'Your questions'

    label: 'Questions to pose to the Citizen Panel'

    description: """Now that you've heard the claims, its your turn to ask the questions! Below, 
                    you can ask questions. Furthermore, you can rate how important the answer to 
                    each question is to you. The most important question will be presented to the 
                    Citizen Initiative Review when it convenes."""

  auth: 

    user_questions : [

      {
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
        tag: 'gender.editable'
        question: "My gender is"
        input: 'dropdown'
        options:['Female', 'Male', 'Transgender', 'Other']
        required: false
      }


     ]



################
# seattle2035

customizations['seattle2035'] = 
  point_labels : pro_con
  slider_pole_labels : agree_disagree
  homie_histo_title: "Opinions"
  show_proposer_icon: true
  civility_pledge: true

  cluster_order: ['Key Proposals', 'Big Changes', 'Overall']

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




customizations['foodcorps'] = 
  point_labels : strengths_weaknesses
  slider_pole_labels : ready_not_ready
  show_slider_feedback: false



customizations['sosh'] = 
  point_labels : strengths_weaknesses
  slider_pole_labels : yes_no
  show_slider_feedback: false


customizations['schools'] = 
  homie_histo_title: "Students' opinions"
  #point_labels : challenge_justify
  slider_pole_labels : agree_disagree


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


customizations['collective'] = 
  show_meta: false 
  proposal_filters: false 

  "/cluster/Contributions": 
    slider_pole_labels: important_unimportant  

  "/cluster/Licenses":
    slider_pole_labels: yes_no




          
conference_config = 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  homie_histo_title: "PC's ratings"

  cluster_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']


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



##############
# ECAST

customizations.ecastonline = customizations['ecast-demo'] = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree

  docking_proposal_header : true

  additional_auth_footer: -> 

    auth = fetch('fetch')
    if auth.ask_questions && auth.form in ['create account', 'create account via invitation', 'user questions']
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






passes_tags = (user, tags) -> 
  if typeof(tags) == 'string'
    tags = [tags]
  user = fetch(user)

  passes = true 
  for tag in tags 
    passes &&= user.tags[tag] && \
     !(user.tags[tag].toLowerCase() in ['no', 'false'])
  passes 

passes_tag_filter = (user, tag, regex) -> 
  user = fetch(user)
  passes = true 
  for tag, value of user.tags   
    passes ||= tag.match(regex) && !(value.toLowerCase() in ['no', 'false'])
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



customizations.bitcoin = 
  show_proposer_icon: true
  collapse_descriptions_at: 300

  civility_pledge: true

  slider_pole_labels: support_oppose

  show_score: true

  cluster_order: ['Blocksize Survey', 'Proposals']   

  'cluster/Blocksize Survey': 
    show_crafting_page_first: false

    slider_handle: slider_handle.triangley
    slider_ticks: true
    discussion: false
    show_score: false
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






customizations['ynpn'] = 
  proposal_filters: false





customizations['on-chain-conf'] = _.extend {}, 
  opinion_filters: customizations.bitcoin.opinion_filters
  auth: customizations.bitcoin.auth
  show_proposer_icon: false
  collapse_descriptions_at: 300
  show_meta: false 

  proposal_filters: true
  civility_pledge: true

  slider_pole_labels: interested

  cluster_order: ['Events', 'On-chain scaling', 'Other topics']

  'cluster/On-chain scaling': 
    slider_pole_labels: interested

  'cluster/Other topics': 
    slider_pole_labels: interested






customizations['kulahawaiinetwork'] = 
  show_proposer_icon: true
  collapse_descriptions_at: 300

  clusters_to_always_show: ['Leadership', 'Advocacy & Public Relations', 'Building Kula Resources & Sustainability', \
                           'Cultivating Kumu', 'Relevant Assessments', 'Teacher Resources', \
                           '‘Ōlelo Hawai’i', '3C Readiness'] 

  cluster_filters: 
    'Advocacy & Public Relations': ['Advocacy & Public Relations']
    'Building Kula Resources & Sustainability': ['Building Kula Resources & Sustainability']
    'Cultivating Kumu': ['Cultivating Kumu']
    'Relevant Assessments': ['Relevant Assessments']
    'Teacher Resources': ['Teacher Resources']
    '‘Ōlelo Hawai’i': ['‘Ōlelo Hawai’i']
    '3C Readiness': ['3C Readiness']
    'Leadership': ['Leadership']


  'cluster/Advocacy & Public Relations':
    homepage_label: 'Ideas'

    label: 'Advocacy & Public Relations'
    description: [
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

  'cluster/Building Kula Resources & Sustainability':
    homepage_label: 'Ideas'
    label: 'Building Kula Resources & Sustainability'
    description: "A space to discuss ideas around joining efforts across kula to enhance opportunities to increase kula resources and sustainability."


  'cluster/Cultivating Kumu':
    homepage_label: 'Ideas'
    label: 'Cultivating Kumu'
    description: [
      """A space to discuss ideas about two things:
         <ul style='list-style:outside;padding-left:40px'>
           <li>Attracting, training, recruiting, growing, retaining, and supporting the preparation of novice teachers, excellent kula leaders, kumu, and staff for learning contexts where ʻōlelo Hawaiʻi, culture, and ʻāina-based experiences are foundational.</li>
           <li>Growing two related communities of kumu and kula leaders who interact regularly, share and learn from one another, develop pilina with one another, and provide support ot one another.</li>
         </ul>
      """
    ]

  'cluster/Relevant Assessments':
    homepage_label: 'Ideas'

    label: 'Relevant Assessments'
    description: "A space to discuss ideas around the development of shared assessments that honor the many dimensions of student growth involved in learning contexts where ʻōlelo Hawaiʻi, culture, and ʻāina-based experiences are foundational. Are we willing to challenge the mainstream concep to education success?"


  'cluster/Teacher Resources':
    homepage_label: 'Ideas'
    label: 'Teacher Resources'
    description: "A space to discuss ideas around the creation of new (and compiling existing) ʻōlelo Hawaiʻi, culture, and ʻāina-based teaching resources to share widely in an online waihona."


  'cluster/‘Ōlelo Hawai’i':
    homepage_label: 'Ideas'
    label: '‘Ōlelo Hawai’i'
    description: "A space to discuss ideas around the way we use our network of Hawaiian Educational Organizationsʻ Synergy to increase the amount of Hawaiian Language speakers so that the language will again be thriving!"

  'cluster/3C Readiness':
    homepage_label: 'Ideas'
    label: '3C Readiness'
    description: "A space to discuss ideas around nurturing college, career, and community readiness in haumāna. How do we provide experiences for haumāna that integrate and bridge high-school, college, career, and community engagement experiences?"

  'cluster/Leadership':
    homepage_label: 'Ideas'
    label: 'Leadership'
    description: "A space for network leaders to gather mana’o."




dao_blue = '#348AC7'
dao_red = '#F83E34'
dao_purple = '#7474BF'
dao_yellow = '#F8E71C'


customizations.dao = _.extend {}, 
  show_proposer_icon: true
  collapse_descriptions_at: 300

  proposal_filters: true

  civility_pledge: true

  show_crafting_page_first: false

  default_proposal_sort: 'trending'

  cluster_order: ["Proposed to DAO", 'Under development', 'New', 'Needs more description', 'Funded', 'Rejected', 'Archived', 'Proposals', 'Ideas', 'Meta', 'DAO 2.0 Wishlist', 'Hack', 'Hack meta']
  clusters_to_always_show: ['Proposed to DAO', 'Under development',  'Proposals', 'Meta']

  proposal_tips: [
    'Describe your idea in sufficient depth for others to evaluate it. The title is usually not enough.'
    'Link to any contract code, external resources, or videos.'
    'Link to any forum.daohub.org or /r/thedao where more free-form discussion about your idea is happening.'
    'Take responsibility for improving your idea given feedback.'
  ]

  cluster_filters: 
    'Inspire Us': ['Ideas', 'Proposals']
    'Proposal Pipeline': ['New', "Proposed to DAO", 'Under development',  'Needs more description', 'Funded', 'Rejected', 'Archived']
    'Meta Proposals': ['Meta', 'Hack', '*']
    'Hack Response': ['Hack', 'Hack meta']
  #cluster_filter_default: 'Hack Response'


  'cluster/Under development':
    archived: false

  'cluster/Proposed to DAO':
    one_line_desc: 'Proposals submitted to The Dao\'s smart contract'

  'cluster/Needs more description':
    archived: true
    one_line_desc: 'Proposals needing more description to evaluate'

  'cluster/Funded':
    archived: true 
    one_line_desc: 'Proposals already funded by The DAO'

  'cluster/Rejected':
    archived: true   
    one_line_desc: 'Proposals formally rejected by The DAO'
  
  'cluster/Archived':
    archived: true 

  'cluster/Done':
    archived: true

  'cluster/Proposals':
    homepage_label: 'Ideas'

  'cluster/Name the DAO':
    archived: true

















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



customizations['bitcoinfoundation'] = 
  cluster_order: ['Proposals', 'Trustees', 'Members']

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
    one_line_desc: 'Archived proceedings of the First Foundation'        
    archived: true

  show_crafting_page_first: true



#####################
# Living Voters Guide



customizations.livingvotersguide = 

  civility_pledge: true

  slider_pole_labels: support_oppose

  'cluster/Advisory votes': 
    archived: true
    one_line_desc: "Advisory Votes are not binding."


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

customizations['ama-rfs'] = 
  show_proposer_icon: true


##########
# Fill in default values for each unspecified field for 
# each subdomain customization
for own k,v of customizations
  _.defaults customizations[k], customizations.default

  customizations[k].key = "customizations/#{k}"
  save customizations[k]
