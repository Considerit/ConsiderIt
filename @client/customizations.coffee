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


  cs: 
    point_labels:
      pro: 'pro'
      pros: 'pro' 
      con: 'proti'
      cons: 'proti'
      your_header: "Dejte --valences--" 
      other_header: "Jiný' --valences--" 
      top_header: "Top --valences--" 
    slider_pole_labels: 
      support: 'Souhlas'
      oppose: 'Nesouhlas'




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











