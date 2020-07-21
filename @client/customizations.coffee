
#######################
# Customizations.coffee
#
# Tailor considerit applications by subdomain

window.customizations = {}
customizations_by_file = {}
window.db_customization_loaded = {}

window._ = _


#######
# API
#
# The customization method returns the proper value of the field for this 
# subdomain, or the default value if it hasn't been defined for the subdomain.
#
# object_or_key is optional. If passed, customization will additionally check for 
# special configs for that object (object.key) or key.



# Either stringify functions or convert them to functions. 
# Will toggle -- it recurses down obj and finds a stringified
# function, it will return an actual function. If it encounters
# a function, it will stringify it. 
FUNCTION_IDENTIFIER = "#javascript\n"
convert_customization = (obj) ->  
  __convert obj, []

__convert = (obj, path) ->

  if Array.isArray(obj)
    return (__convert(vv, path) for vv in obj)

  else if typeof(obj) == 'object' 
    tree = {}
    for k,v of obj 
      p = path.slice()
      p.push k 
      tree[k] = __convert(v,p)
    return tree

  else if typeof(obj) == 'function'
    return "#{FUNCTION_IDENTIFIER}#{obj.toString()}"

  else if typeof(obj) == 'string' && obj.startsWith(FUNCTION_IDENTIFIER)
    str_func = obj.substring FUNCTION_IDENTIFIER.length
    func = new Function("return #{str_func}")()
    return func

  else 
    return obj




window.load_customization = (subdomain) ->
  return if !subdomain.name
  subdomain_name = subdomain.name?.toLowerCase()

  try 
    customizations_file_used = !!customizations_by_file[subdomain_name]
    if customizations_file_used
      console.log "#{subdomain_name} config for import: \n", JSON.stringify(convert_customization(customizations_by_file[subdomain_name]), null, 2)

    if subdomain.customization_obj
      new Function(subdomain.customization_obj)() # will create window.customization_obj      
      stringified = convert_customization window.customization_obj
      subdomain.customizations = JSON.stringify stringified, null, 2
      save subdomain
    else 
      subdomain = fetch '/subdomain'
      stringified = JSON.parse subdomain.customizations 

    customizations[subdomain_name] = _.extend {}, (customizations_by_file[subdomain_name] or {}), convert_customization(stringified)

    db_customization_loaded[subdomain_name] = true

  catch error 
    console.error error


window.customization = (field, object_or_key) -> 
  
  if !!object_or_key && !object_or_key.key?
    obj = fetch object_or_key
  else 
    obj = object_or_key


  if obj && obj.subdomain_id && "#{obj.subdomain_id}" != document.querySelector("meta[name='forum']")?.getAttribute("content")
    subdomain = fetch "/subdomain/#{obj.subdomain_id}" 
  else 
    subdomain = fetch('/subdomain')

  subdomain_name = subdomain.name?.toLowerCase()
  
  if !db_customization_loaded[subdomain.name]
    load_customization subdomain

  key = if obj 
          if obj.key then obj.key else obj
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
        proposal = obj
        cluster_key = "list/#{proposal.cluster}"
        if subdomain_config[cluster_key]?
          chain_of_configs.push subdomain_config[cluster_key]

    # subdomain config
    chain_of_configs.push subdomain_config
  
  # global default config
  chain_of_configs.push customizations['default']

  value = undefined
  for config in chain_of_configs
    value = config[field]

    break if value?

  # if !value?
  #   console.error "Could not find a value for #{field} #{if key then key else ''}"

  value



require './color'
require './logo'
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

  point_labels : point_labels.pro_con
  slider_pole_labels : slider_labels.agree_disagree
  list_opinions_title: 'Opinions'

  # Proposal options
  discussion_enabled: true

  homepage_show_search_and_sort: true

  list_show_new_button: true

  homepage_show_new_proposal_button: true
  homepage_default_sort_order: 'trending'

  show_crafting_page_first: false

  show_histogram_on_crafting: true

  show_proposal_meta_data: true 

  slider_handle: slider_handle.face
  slider_regions: null

  show_proposal_scores: true

  show_proposer_icon: true
  collapse_proposal_description_at: 300

  # default cluster options
  list_is_archived: false
  list_uncollapseable: false

  # Other options
  auth_footer: false
  auth_require_pledge: false
  has_homepage: true

  homepage_list_order: []

  font: "'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Lucida Sans Unicode', 'Helvetica Neue', Helvetica, Verdana, sans-serif"

  auth_questions: []

  SiteHeader : ShortHeader()
  SiteFooter : DefaultFooter

  new_proposal_fields: -> 
   name:  translator("engage.edit_proposal.summary_label", "Summary")
   description: translator("engage.edit_proposal.description_label", "Details") + " (#{translator('optional')})" 
   additional_fields: []
   create_description: (fields) -> fields.description






##########################
# SUBDOMAIN CONFIGURATIONS


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
  customizations_by_file[sub.toLowerCase()] = 
    HomepageHeader: LegacyImageHeader()

for sub in masthead_only
  customizations_by_file[sub.toLowerCase()] = 
    HomepageHeader: LegacyImageHeader()



