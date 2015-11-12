require './customizations'

####
# t()
#
# language appropriate string for a given string identifier
#
# label is an identifier for the string to be fetched. Will
# look label up in the respective language's dictionary defined
# below.
#
# args is optional object that will be passed onto the label
#
window.t = (label, args) -> 
  lang = customization('lang') # get the language defined for this subdomain

  if !dict[lang]?
    throw "Sorry, don't support language #{lang}"

  dictionary = dict[lang]

  label = label.replace(/\ /g, '_')

  if !dictionary[label]?
    throw "Can't translate #{label} for language #{lang}"

  if typeof(dictionary[label]) == 'function'
    dictionary[label](args)
  else 
    dictionary[label]


##### 
# Dict will hold all the different translations for each language, 
#  i.e. dict.en, dict.spa, etc
# Each language's dict will have entries for every possible label that the 
# system needs to have a translation for. The entry can be a simple string, 
# or a function that will be passed arguments from t(). 

dict = {}


################
# Translation guidelines: 
#   - Try to make the translation roughly the same
#     number of characters as the english version, to prevent 
#     weird layout issues. I know this won't always be possible!


# Idea: Instead of defining everything here, it might be better to have 
#       each module/component define its own translations, and register them 
#       with the translation system. That might lead to a better development
#       experience when writing code, as the strings are all defined locally.
#       On the other hand, having all translations in a single file might 
#       make it easier to ask others to add/update necessary translations.  

dict.en = 
  comment: 'comment'
  comments: 'comments'
  read_more: 'read more'
  select_these_opinions: 'Select these opinions'
  prev: 'prev'
  next: 'next'
  drag_from_left: (args) ->
    "Drag a #{args.noun} from the left"
  drag_from_right: (args) -> 
    "Drag a #{args.noun} from the right"
  write_a_new_point: (args) -> 
    "Write a new #{args.noun}"    
  or: 'or'

dict.spa = 
  comment: 'comentario'
  comments: 'comentarios'
  read_more: 'ver más'
  select_these_opinions: 'Selecciona estas opiniones'
  prev: 'anterior'
  next: 'siguiente'
  drag_from_left: (args) ->
    return "Arrastra un #{args.noun} de la izquierda"

  drag_from_right: (args) ->
    return "Arrastra un #{args.noun} de la derecha"

  write_a_new_point: (args) ->
    return "Escribe un nuevo #{args.noun}"
  or: 'ó'

########
# authentication / user account related translations

_.extend dict.en, 
  Log_in: 'Log in'
  Create_new_account: 'Create new account'
  Log_out: 'Log out'
  Edit_Profile: 'Edit Profile'
  Email_Settings: 'Email Settings'
  Introduce_Yourself: 'Introduce Yourself'

_.extend dict.spa, 
  Log_in: 'Entrar'
  Create_new_account: 'Registrarse'
  Log_out: 'Salir'
  Edit_Profile: 'Editar Perfil'
  Email_Settings: 'Configuración de Email'
  Introduce_Yourself: 'Descríbete'


# fill in missing spanish translations with english equivalents
_.defaults dict.spa, dict.en