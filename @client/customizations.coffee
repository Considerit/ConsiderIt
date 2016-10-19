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

  es: 
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

  fr: 
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

  aeb: 
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

  pt: 
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
                 "Airbdsm","bitcoin-ukraine","lyftoff","hcao","arlingtoncountyfair","progressive", \
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







customizations['hala'] = 


  show_proposer_icon: true
  show_proposal_meta_data: true 
  auth_require_pledge: true
  show_proposal_scores: true
  homepage_show_search_and_sort: false

  list_uncollapseable: false

  homepage_list_order: ['Housing Options and Community Assets', 'Transitions', 'Urban Design Quality', 'Urban Village Expansion', 'Historic Areas and Unique Conditions', 'Fair Chance Housing', 'Preservation of Existing Affordable Housing', 'Minimize Displacement']


  opinion_filters: ( -> 
    filters = 
      [ {
        label: 'focus group'
        tooltip: null
        pass: (user) -> passes_tags(user, 'hala_focus_group')
      }] 

    for home in ['Rented', 'Owned by me', 'Other']

      filters.push 
        label: "Home:#{home.replace(/ /g, '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['home.editable'] == home 

    for home in ['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']

      filters.push 
        label: "Housing_type:#{home.replace(/ /g, '_')}"
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


  list_label_style: 
    color: seattle_vars.teal

  "list/Preservation of Existing Affordable Housing" : 

    list_items_title: 'Guidelines'
    list_label: "Preservation of Existing Affordable Housing"
    list_description: [
          """There are many buildings and other types of housing in Seattle that currently offer affordable rents. 
             In this set of questions, we are using the term "preservation" to describe retaining affordable rents 
             in existing buildings that are currently unsubsidized. In the next section, we address historic 
             preservation in the context of Mandatory Housing Affordability (MHA). We will be using the term AMI or Area Median Income. 
             For Seattle, here is a snapshot of those: 60% of AMI in 2016 is \$37,980 annually for an individual, 
             \$54,180 for a family of four. 
             See #{cluster_link('http://www.seattle.gov/Documents/Departments/Housing/PropertyManagers/IncomeRentLimits/Income-Rent-Limits_Rental-Housing-HOME.pdf','detailed numbers')}."""
          "What do you think of the following guidelines?"
        ]


  "list/Urban Village Expansion" : 

          
    list_items_title: 'Guidelines'
    list_label: "Urban Village Expansion Areas"
    list_description: [
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


  "list/Historic Areas and Unique Conditions" : 

          
    list_items_title: 'Guidelines'
    list_label: "Historic Areas and Unique Conditions"
    list_description: [
      """Seattle has many historic areas, some on the National Register and some known to locals 
         as places of historic or cultural significance.  As a community we have defined these areas, 
         in code and in practice, and their special heritage in our community."""

      "What do you think of the following guidelines?"
    ]



  "list/Housing Options and Community Assets" : 
    list_items_title: 'MHA Principles'    
    list_is_archived: false
    list_uncollapseable: false
    list_label: "Housing Options and Community Assets"
    list_description: "What do you think of the following principles?"

    list_divider: ->  
      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          marginTop: 40
        DIV 
          style: _.extend {}, seattle_vars.section_description, 
            marginTop: 20
            backgroundColor: seattle_vars.teal
            color: 'white'
            display: 'inline-block'
            padding: 20
            fontWeight: 500
            fontSize: 22
            marginBottom: 20

          "The comment period is now closed on the below questions. Thanks for your input!"
          " We've taken away these "
          A 
            href: 'https://www.seattle.gov/Documents/Departments/HALA/FocusGroups/Principles_MHA_Implementation_2pager.pdf'
            target: '_blank'
            style: 
              textDecoration: 'underline'
            'MHA principles'
          '.'



        DIV 
          style:
            color: seattle_vars.brown
            fontSize: 42
            fontWeight: 400
            marginBottom: 5
            

          H1 
            style: 
              borderBottom: "1px solid #{seattle_vars.brown}"
              color: seattle_vars.brown

            "Mandatory Housing Affordability "

            SPAN 
              style: 
                fontStyle: 'italic'
              "Principles"

        DIV 
          style: seattle_vars.section_description

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
              color: seattle_vars.teal
              textDecoration: 'underline'

            'Grand Bargain' 


          """ and is essential to achieving affordable 
             housing goals of 6,000 new affordable units over ten years. """

        DIV 
          style: _.extend {}, seattle_vars.section_description, 
            fontStyle: 'italic'
            marginTop: 20
            marginBottom: 20

          """The questions below assume that zoning changes will take place to fully implement MHA.  
             We are asking for input on how those zoning changes will look and feel.  These questions 
             are intended to get at the values that should drive these zoning changes.  What are the 
             important principles for us to keep in mind when we propose zoning changes in the next few months? 
             Bear in mind, the following elements are only a portion of the MHA. We will continue adding 
             pieces as they become available."""



      





  "list/Transitions" : 
    list_uncollapseable: false
    list_is_archived: false
    list_items_title: 'MHA Principles'    
    list_label: "Transitions"
    list_description: [
      """When taller buildings are constructed in areas that are zoned for more density, 
         neighboring buildings that are smaller sometimes feel out of place. Zoning 
         regulations can plan for transitions between higher- and lower-scale zones as 
         Seattle grows and accommodates new residents and growing families."""
      "What do you think of the following principles?"
    ]

  "list/Urban Design Quality" : 
    list_uncollapseable: false
    list_is_archived: false
    list_items_title: 'MHA Principles'    
    list_label: "Urban Design Quality"
    list_description: [
      """As Seattle builds new housing, we want to know what design features are 
         important to you. These elements address quality of life with design choices 
         for new residential buildings and landscaping."""
      "What do you think of the following principles?"
    ]


  "list/Minimize Displacement" : 

    list_is_archived: false
    list_uncollapseable: false
    list_items_title: 'Displacement proposal'
    list_label: "Minimize Displacement"
    list_description: """Displacement is happening throughout Seattle, and particular communities 
                    are at high risk of displacement. Data analysis and community outreach will 
                    help identify how growth may benefit or burden certain populations. We will 
                    use that data to make sure our strategies are reaching the communities most 
                    in need."""


  "list/Fair Chance Housing" : 
    list_is_archived: false
    list_items_title: 'Guidelines'    
    list_uncollapseable: false
    list_label: "Fair Chance Housing legislation"
    list_description: """Fair Chance Housing legislation is aimed at increasing access to Housing for 
             People with Criminal History. 
             An estimated one in every three adults in the United States has a criminal 
             record, and nearly half of all children in the U.S. have one parent with a 
             criminal record. Due to a rise in the use of criminal background checks during 
             the tenant screening process, people with arrest and conviction records face 
             major barriers to housing. Fair Chance Housing legislation could lessen some of 
             the barriers people face."""
    list_divider: ->  
      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          marginTop: 40

        DIV 
          style:
            color: seattle_vars.brown
            fontSize: 42
            fontWeight: 400
            marginBottom: 5
            

          H1 
            style: 
              borderBottom: "1px solid #{seattle_vars.brown}"
              color: seattle_vars.brown
              marginBottom: 20

            "Other HALA topics"


  "list/Urban Village Expansions" : 
    list_description: -> 

      [
        "The "
        A 
          href: 'http://2035.seattle.gov/'
          target: '_blank'
          style: 
            textDecoration: 'underline'

          "Seattle 2035 Comprehensive Planning"

        """ considered expanding urban villages 
        to reflect the walkshed from excellent transit service.  The draft maps suggest specific 
        urban village boundary expansions, building on the general concepts in the comprehensive plan 
        and feedback from the public throughout this process."""
      ]

  "list/Single Family Rezone Areas" : 
    list_description: -> 
      [
        """Existing Single Family (SF) zones within the """
        A
          href: 'http://seattlecitygis.maps.arcgis.com/apps/MapTools/index.html?appid=2c698e5c81164beb826ba448d00e5cf0'
          target: '_blank'
          style: 
            textDecoration: "underline"

          "urban villages" 
        """ would be rezoned to implement MHA. Residential Small Lot (RSL), a zone that allows small infill 
        homes in the scale and character of a single family area, is proposed for many of these.  
        However, some of the areas could have Lowrise (LR) Multi-Family zoning. And only a few 
        of these areas are shown having a mixed use commercial zone (NC) on the draft map."""
      ]

  "list/Multi-family Residential Areas" : 
    list_description: """Draft zoning for multi-family areas is in brown on the map."""

  "list/Commercial Areas" : 
    list_description: """Draft zoning for commercial areas is in red and pink."""



  auth_questions : [
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

  auth_footer: """
    We are collecting this information to find out if this tool is 
    truly reaching the diverse population that reflects our city. Thank you!
    """
    

  google_translate_style: 
    top: 12
    # top: 40
    position: 'absolute'
    zIndex: 2
    left: 20

  SiteHeader: ShortHeader
    text: "HALA"
    logo_src: null
    min_height: 40

  homepage_tabs: 
    'Feedback on key principles': ['*']
    'Draft zoning changes': ['Alignment with Mandatory Housing Affordability principles', 'Commercial areas', 'Multi-family Residential Areas',  'Single Family Rezone Areas', 'Urban Village Expansions']

  proposal_description: (->

    desc = ReactiveComponent
      displayName: 'hala-desc'
      componentDidMount: -> @embed()
      componentDidUpdate: -> @embed()
      embed: -> 
        if !@local.embedded 
          PDFObject.embed? @props.proposal.description, '#hala_map_embed'
          @local.embedded = true 

        if !@local.principles_embedded
          PDFObject.embed? 'https://www.seattle.gov/Documents/Departments/HALA/FocusGroups/Principles_MHA_Implementation_2pager.pdf', '#hala_mha_principles_embed'
          @local.principles_embedded = true

      render: ->
        proposal = @props.proposal 
        DIV null, 

          if proposal.cluster == 'Multi-family Residential Areas'
            DIV style: marginBottom: 20, "Draft zoning for multi-family areas is in brown on the map."
          else if proposal.cluster == "Single Family Rezone Areas"
            DIV style: marginBottom: 20, 
              """Existing Single Family (SF) zones within the """
              A
                href: 'http://seattlecitygis.maps.arcgis.com/apps/MapTools/index.html?appid=2c698e5c81164beb826ba448d00e5cf0'
                target: '_blank'
                style: 
                  textDecoration: "underline"

                "urban villages" 
              """ would be rezoned to implement MHA. Residential Small Lot (RSL), a zone that allows small infill 
              homes in the scale and character of a single family area, is proposed for many of these.  
              However, some of the areas could have Lowrise (LR) Multi-Family zoning. And only a few 
              of these areas are shown having a mixed use commercial zone (NC) on the draft map."""
          else if proposal.cluster == "Multi-family Residential Areas"
            DIV style: marginBottom: 20, "Draft zoning for multi-family areas is in brown on the map."



          DIV 
            style: 
              marginBottom: 4


            BUTTON
              onClick: => @local.show_full_map = !@local.show_full_map; @local.embedded = false; save @local; document.activeElement.blur()
              style: 
                border: 'none'
                backgroundColor: '#D8D8D8'
                textAlign: 'center'
                display: 'block'
                width: '100%'
                padding: '12px 0'
                fontSize: 26
                # textDecoration: 'underline'
                fontWeight: 600

              if !@local.show_full_map
                'View draft zoning changes map'
              else 
                'Hide draft zoning changes map'

            if @local.show_full_map
              DIV 
                id: 'hala_map_embed'
                style: 
                  height: window.innerHeight


          DIV 
            style: 
              marginBottom: 4

            BUTTON 
              onClick: => @local.learn_more = !@local.learn_more; save @local; document.activeElement.blur()
              style: 
                border: 'none'
                backgroundColor: '#D8D8D8'
                textAlign: 'center'
                display: 'block'
                width: '100%'
                padding: '12px 0'
                fontSize: 26
                # textDecoration: 'underline'
                fontWeight: 600

              if @local.learn_more
                'Learn less about how to read the map'
              else 
                'Learn more about how to read the map'

            if @local.learn_more
              DIV 
                style: {}

                DIV 
                  style: 
                    width: 300

                UL 
                  style: 
                    fontSize: 18
                    paddingLeft: 40
                    listStyle: 'outside'
                    marginBottom: 12
                  LI null,
                    """The colors reflect new zoning for implementing the MHA affordable housing requirements. """
                    A 
                      href: 'http://www.seattle.gov/hala/focus-groups#MHA%20Development%20Examples'
                      target: '_blank'
                      style: 
                        textDecoration: 'underline'

                      "Examples" 
                    
                    " of what buildings would look like in the new zones."
                  
                  LI null,
                    """Each zone is labeled with the name of today’s existing zone (*before the “|”) and the proposed new MHA zone (after the “|”).""" 
                  LI null,
                    """The affordable housing requirement will vary based on market conditions in the neighborhood and the size of the zoning changes. 
                       The requirement will range from 5% to 11% of housing units or a payment of $7.00 to $32.75 per sq. ft. for residential 
                       development; and from 5% to 9% of commercial square feet or a payment of $5.00 to $14.50 per sq. ft. for commercial 
                       development. Areas with an (M1) suffix have slightly larger zoning increases and higher affordable housing amounts, 
                       and areas with an (M2) suffix have even larger zoning increases and the highest affordable housing amounts."""

                  LI null,
                    """Urban villages that have a proposed boundary expansion as part of the """
                    A 
                      href: 'http://2035.seattle.gov/'
                      target: '_blank'
                      style: 
                        textDecoration: 'underline'

                      "Seattle 2035 Comprehensive Planning"
                    """process are shown with the current boundary (solid white line), and a draft expanded boundary (dashed white line).  All areas within an existing or expanded urban villages have draft MHA zoning changes.""" 

                IFRAME 
                  src: 'https://spark.adobe.com/video/6Co5MIVpCCAg3/embed'
                  width: HOMEPAGE_WIDTH()
                  height: HOMEPAGE_WIDTH() * 540 / 960
                  frameborder: "0" 
                  allowfullscreen: '1'

          DIV 
            style: 
              marginBottom: 18

            BUTTON
              onClick: => @local.show_full_mha = !@local.show_full_mha; @local.principles_embedded = false; save @local; document.activeElement.blur()  
              style: 
                border: 'none'
                backgroundColor: '#D8D8D8'
                textAlign: 'center'
                display: 'block'
                width: '100%'
                padding: '12px 0'
                fontSize: 26
                #textDecoration: 'underline'
                fontWeight: 600

              if !@local.show_full_mha
                'Learn more about the MHA principles'
              else 
                'Learn less about the MHA principles'

            if @local.show_full_mha
              DIV 
                id: 'hala_mha_principles_embed'
                style: 
                  height: window.innerHeight

          DIV 
            style: 
              fontSize: 36
              marginTop: 40
              textAlign: 'center'

            'What do you think?'

    {  
      'Alignment with Mandatory Housing Affordability principles': desc
      'Commercial areas': desc
      'Multi-family Residential Areas': desc
      'Single Family Rezone Areas': desc
      'Urban Village Expansions': desc
    }

  )() 

  homepage_tab_views: 
    'Draft zoning changes': ReactiveComponent
      displayName: 'HALA Draft Zoning Tab'

      componentDidMount: -> @embed()
      componentDidUpdate: -> @embed()
      embed: -> 
        if @local.embedded != fetch('hala').map && $('#hala_map_embed').length > 0
          PDFObject.embed? fetch('hala').map, '#hala_map_embed'
          @local.embedded = fetch('hala').map 
        if !@local.principles_embedded
          PDFObject.embed? 'https://www.seattle.gov/Documents/Departments/HALA/FocusGroups/Principles_MHA_Implementation_2pager.pdf', '#hala_mha_principles_embed'
          @local.principles_embedded = true

      render: -> 
        subdomain = fetch('/subdomain')
        proposals = fetch('/proposals')
        current_user = fetch('/current_user')

        if !proposals.proposals 
          return ProposalsLoading()   

        clusters = clustered_proposals_with_tabs()

        # collapse by default archived clusters
        collapsed = fetch 'collapsed'
        if !collapsed.clusters?
          collapsed.clusters = {}
          for cluster in clusters when cluster.list_is_archived 
            collapsed.clusters[cluster.key] = 1
          save collapsed

        has_proposal_sort = customization('homepage_show_search_and_sort') && proposals.proposals.length > 10


        neighborhoods = []
        hala = fetch('hala')
        for c in clusters 
          if c.name == 'Alignment with Mandatory Housing Affordability principles'
            for p in c.proposals 
              neighborhood = capitalize(p.slug.split('--')[0].replace(/_/g, ' '))
              neighborhoods.push 
                name: neighborhood
                map: p.description
              if !hala.name 
                _.extend hala, neighborhoods[0]

        for c in clusters 
          c.proposals = (p for p in c.proposals when hala.name == capitalize(p.slug.split('--')[0].replace(/_/g, ' ')))

        for n,idx in neighborhoods
          if n.name == hala.name 
            current_val = idx 

        DIV
          id: 'homepagetab'
          role: "tabpanel"
          style: 
            fontSize: 22
            margin: '45px auto'
            width: HOMEPAGE_WIDTH()
            position: 'relative'


          STYLE null,
            '''a.proposal:hover {border-bottom: 1px solid grey}'''


          H1 
            style: 
              fontSize: 42
              fontWeight: 400
              marginBottom: 5
              color: seattle_vars.teal              
            'Draft Zoning Changes for Urban Villages'

          DIV 
            style: seattle_vars.section_description

            P 
              style:
                marginBottom: 18 
              'Each map shows possible zoning changes necessary to implement '
              SPAN style: fontWeight: 600, 'Mandatory Housing Affordability (MHA)' 
              """ in a specific neighborhood. MHA will require new commercial (buildings that house jobs and services) 
              and multifamily development (housing that shares walls, not a single family house) to include affordable 
              housing on site or make an in-lieu payment to a fund managed by the City’s Office of Housing (see City’s """
              A 
                href: 'http://www.seattle.gov/Documents/Departments/HALA/HousingLevy_CombinedLevies_Production.pdf'
                target: '_blank'
                style: 
                  textDecoration: 'underline'
                "track record"
              " of spending for similar fund)."

            P 
              style:
                marginBottom: 18 

              'Each map is based on '
              A 
                href: 'http://www.seattle.gov/Documents/Departments/HALA/FocusGroups/Principles_MHA_Implementation_2pager.pdf'
                target: '_blank'                
                style: 
                  textDecoration: 'underline'
                'Principles'
              ' developed with '
              A 
                href: 'http://www.seattle.gov/hala/your-thoughts'
                target: '_blank'
                style: 
                  textDecoration: 'underline'
                'community input'
              """ from recent months and past planning. Your feedback will help us propose final MHA 
              implementation maps to the City Council in spring 2017."""


          DIV 
            style: 
              fontSize: 28
              marginBottom: 20
              fontWeight: 'inherit'

            LABEL 
              htmlFor: 'neighborhood_selector'
              'View draft zoning changes for'

            SELECT 
              id: 'neighborhood_selector'
              className: 'unstyled'
              style: 
                fontSize: 28
                marginLeft: 10
                paddingTop: 8
                paddingBottom: 8
                fontWeight: 400
                backgroundSize: '24px 20px'
              value: current_val
              onChange: (e) => 
                _.extend hala, neighborhoods[parseInt(e.target.value)]
                save hala
                document.activeElement.blur()

              for n,idx in neighborhoods
                OPTION 
                  value: idx
                  n.name


          DIV 
            style: 
              marginBottom: 4

            DIV 
              id: 'hala_map_embed'
              style: 
                height: if !@local.show_full_map then '450px' else window.innerHeight

            BUTTON
              onClick: => @local.show_full_map = !@local.show_full_map; save @local; document.activeElement.blur() 
              style: 
                border: 'none'
                backgroundColor: '#D8D8D8'
                textAlign: 'center'
                display: 'block'
                width: '100%'
                padding: '12px 0'
                fontSize: 26
                # textDecoration: 'underline'
                fontWeight: 600

              if !@local.show_full_map
                'Expand map'
              else 
                'Collapse map'


          DIV 
            style: 
              marginBottom: 4

            BUTTON 
              onClick: => @local.learn_more = !@local.learn_more; save @local; document.activeElement.blur()
              style: 
                border: 'none'
                backgroundColor: '#D8D8D8'
                textAlign: 'center'
                display: 'block'
                width: '100%'
                padding: '12px 0'
                fontSize: 26
                # textDecoration: 'underline'
                fontWeight: 600

              if @local.learn_more
                'Learn less about how to read the map'
              else 
                'Learn more about how to read the map (+ video)'

            if @local.learn_more
              DIV 
                style: 
                  marginTop: 20

                DIV 
                  style: 
                    width: 300

                UL 
                  style: 
                    fontSize: 18
                    paddingLeft: 40
                    listStyle: 'outside'
                    marginBottom: 12
                  LI style: marginBottom: 4,
                    """The colors reflect new zoning for implementing the MHA affordable housing requirements. """
                    A 
                      href: 'http://www.seattle.gov/hala/focus-groups#MHA%20Development%20Examples'
                      target: '_blank'
                      style: 
                        textDecoration: 'underline'

                      "Examples" 
                    
                    " of what buildings would look like in the new zones."
                  
                  LI style: marginBottom: 4,
                    """Each zone is labeled with the name of today’s existing zone (*before the “|”) and the proposed new MHA zone (after the “|”).""" 
                  LI style: marginBottom: 4,
                    """The affordable housing requirement will vary based on market conditions in the neighborhood and the size of the zoning changes. 
                       The requirement will range from 5% to 11% of housing units or a payment of $7.00 to $32.75 per sq. ft. for residential 
                       development; and from 5% to 9% of commercial square feet or a payment of $5.00 to $14.50 per sq. ft. for commercial 
                       development. Areas with an (M1) suffix have slightly larger zoning increases and higher affordable housing amounts, 
                       and areas with an (M2) suffix have even larger zoning increases and the highest affordable housing amounts."""

                  LI style: marginBottom: 4,
                    """Urban villages that have a proposed boundary expansion as part of the """
                    A 
                      href: 'http://2035.seattle.gov/'
                      target: '_blank'
                      style: 
                        textDecoration: 'underline'

                      "Seattle 2035 Comprehensive Planning"
                    """ process are shown with the current boundary (solid white line), and a draft expanded boundary (dashed white line).  All areas within an existing or expanded urban villages have draft MHA zoning changes.""" 

                IFRAME 
                  src: 'https://spark.adobe.com/video/6Co5MIVpCCAg3/embed'
                  width: HOMEPAGE_WIDTH()
                  height: HOMEPAGE_WIDTH() * 540 / 960
                  frameborder: "0" 
                  allowfullscreen: '1'


          DIV 
            style: 
              marginBottom: 18

            BUTTON
              onClick: => @local.show_full_mha = !@local.show_full_mha; @local.principles_embedded = false; save @local; document.activeElement.blur()
              style: 
                border: 'none'
                backgroundColor: '#D8D8D8'
                textAlign: 'center'
                display: 'block'
                width: '100%'
                padding: '12px 0'
                fontSize: 26
                #textDecoration: 'underline'
                fontWeight: 600


              if !@local.show_full_mha
                'Learn more about the MHA principles'
              else 
                'Learn less about the MHA principles'

            if @local.show_full_mha
              DIV 
                id: 'hala_mha_principles_embed'
                style: 
                  height: window.innerHeight


          H3 
            style: 
              marginBottom: 40
              marginTop: 50
              fontSize: 28
              fontWeight: 'inherit'

            "What do you think about the #{fetch('hala').name} draft map?"



          if has_proposal_sort
            [first_column, secnd_column, first_header, secnd_header] = cluster_styles()
            ProposalFilter
              style: 
                width: first_column.width
                marginBottom: 20
                display: 'inline-block'
                verticalAlign: 'top'

          if customization('opinion_filters')
            [first_column, secnd_column, first_header, secnd_header] = cluster_styles()

            OpinionFilter
              style: 
                width: if has_proposal_sort || true then secnd_column.width
                marginBottom: 20
                marginLeft: if has_proposal_sort then secnd_column.marginLeft else first_column.width + secnd_column.marginLeft
                display: if has_proposal_sort then 'inline-block'
                verticalAlign: 'top'
                textAlign: 'center' 



          # List all clusters
          for cluster, index in clusters or []
            Cluster
              key: "list/#{cluster.name}"
              cluster: cluster 
              index: index

  homepage_default_tab: 'Draft zoning changes'

  homepage_tabs_no_show_all: true

  HomepageHeader: -> 

    background_image_alternative_text = 'Seattle HALA: Housing Affordability and Livability Agenda. Tell us your thoughts on HALA!'
    background_image_url = asset('hala/hala-header.png')
    image_style = 
      borderBottom: "7px solid #{seattle_vars.teal}"      

    DIV 
      style: 
        position: 'relative'

      IMG
        alt: background_image_alternative_text
        style: _.defaults {}, image_style,
          width: '100%'
          display: 'block'
        src: background_image_url

      DIV 
        style: 
          backgroundColor: '#767676'
          color: 'white'

        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            margin: 'auto'
            padding: '36px 0'
          H1
            style: 
              fontSize: 34
              fontWeight: 500
              color: 'white'
              marginBottom: 36

            'Please add your opinion about how to secure quality, affordable housing for Seattle for many years to come'

          DIV 
            style: 
              fontSize: 18 
            """“We are facing our worst housing affordability crisis in decades. My vision is a city where people who work in Seattle can afford to live here…We all share a responsibility in making Seattle affordable. Together, """
            A 
              href: 'http://www.seattle.gov/hala'
              target: '_blank'
              style: 
                fontWeight: 700
                textDecoration: 'underline'
              "HALA" 
            " will take us there.”"

          DIV 
            style:
              textAlign: 'right'

            IMG 
              alt: ''
              src: asset('hala/ed-murray.jpg')
              style: 
                borderRadius: '50%'
                width: 50
                height: 50
                verticalAlign: 'middle'

            SPAN 
              style: 
                padding: '0 10px'
                verticalAlign: 'middle'
                fontSize: 22
                fontWeight: 500

              'Mayor Ed Murray'

      DIV 
        style: 
          backgroundColor: seattle_vars.teal
          color: 'white'
          borderBottom: "1px solid #000"

        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            margin: 'auto'
            padding: '36px 0 50px 0'

          H1
            style: 
              fontSize: 34
              fontWeight: 500
              color: 'white'
              marginBottom: 36

            'The '
            A
              href: 'http://www.seattle.gov/hala'
              target: '_blank'
              style: 
                textDecoration: 'underline'
              'HALA team'
            ' at the City of Seattle is listening'


          DIV 
            style: 
              position: 'relative'
              color: 'white'
              fontSize: 20

            DIV 
              style: 
                position: 'relative'
                left: 0
              DIV 
                style: 
                  width: 525
                  position: 'relative'

                SPAN 
                  style: 
                    fontSize: 18
                  A 
                    href: 'http://www.seattle.gov/hala/your-thoughts'
                    target: '_blank'
                    style: 
                      textDecoration: 'underline'
                      fontWeight: 700
                    "We heard from residents from May to September"
                  " about key principles underlying Mandatory Housing Affordability and other topics about securing affordable housing in Seattle."

                SVG 
                  style: 
                    position: 'absolute'
                    top: 100
                    left: '10%'
                    opacity: .75

                  width: 67 * .85
                  height: 204 * .85
                  viewBox: "0 0 67 204" 

                  G                       
                    fill: 'none'

                    PATH
                      strokeWidth: 1 / 1.05 
                      stroke: 'white' 
                      d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

            DIV 
              style: 
                position: 'relative'
                left: 250
                marginTop: 36

              DIV 
                style: 
                  width: 525
                  position: 'relative'

                SPAN 
                  style: 
                    fontSize: 18
                  SPAN 
                    style: 
                      fontWeight: 700
                    'We’ve started engaging residents about draft zoning changes'
                  ' for specific neighborhoods based on Mandatory Housing Affordability principles.'

                SVG 
                  style: 
                    position: 'absolute'
                    top: 100
                    left: '10%'
                    opacity: 1

                  width: 67 * .25
                  height: 204 * .25
                  viewBox: "0 0 67 204" 

                  G                       
                    fill: 'none'

                    PATH
                      strokeWidth: 1 / .63
                      stroke: 'white' 
                      d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"


        DIV 
          style: 
            width: HOMEPAGE_WIDTH()
            margin: 'auto'
          HomepageTabs()




    # # external_link: 'http://seattle.gov/hala'
    # # external_link_anchor: 'seattle.gov/hala'
    # background_image_alternative_text: 'Seattle HALA: Housing Affordability and Livability Agenda. Tell us your thoughts on HALA!'
    # background_image_url: asset('hala/hala-header.png')
    # image_style: 
    #   borderBottom: "7px solid #{seattle_vars.teal}"      
    # quote: 
    #   who: 'Mayor Ed Murray'
    #   what: """
    #         We are facing our worst housing affordability crisis in decades. My vision is a city where 
    #         people who work in Seattle can afford to live here…We all share a responsibility in making Seattle 
    #         affordable. Together, HALA will take us there.
    #         """
    
    # #top_strip_style: 
    # #  backgroundColor: seattle_vars.magenta  
    
    # section_heading_style: 
    #   color: seattle_vars.brown

    # sections: [
    #   {
    #     label: """Your thoughts on the Housing Affordability and Livability Agenda (HALA) are key to securing quality, 
    #               affordable housing for Seattle for many years to come."""
    #     paragraphs: ["""HALA addresses Seattle's housing affordability crisis on many fronts. As we take proposals from idea 
    #                    to practice, we have been listening to the community to find out what matters to you. This online 
    #                    conversation reflects the diversity of ideas we've heard thus far and will continue 
    #                    to provide meaningful ideas on how to move forward."""]
    #   }, {
    #     label: """Please add your opinion below"""
    #     paragraphs: ["""
    #       We have listed many key recommendations below. This is an opportunity for you to shape the recommendations 
    #       before they are finalized. As the year progresses, we will be looking at other new programs, so check back often to weigh in on them. 
    #       The questions you see here are Phase 2 of this community conversation. Phase 1 questions that closed 
    #       recently can be found at the bottom of this page. We are also summarizing your feedback and posting it on 
    #       #{cluster_link('http://www.seattle.gov/hala/your-thoughts', 'our website')}.
    #       """
    #     ]
    #   }
    # ]

    # salutation: 
    #   text: 'Thanks for your time,'
    #   image: asset('hala/Seattle-Logo-and-signature2.jpg')
    #   from: 'HALA Team, City of Seattle'
    #   after: "p.s. Email us at #{cluster_link('mailto:halainfo@seattle.gov', 'halainfo@seattle.gov')} or visit our website at #{cluster_link('http://seattle.gov/HALA', 'seattle.gov/HALA')} if you want to know more."
    # closed: false












