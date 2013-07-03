class ConsiderIt.Account extends Backbone.Model
  name: 'account'
  
  initialize : (attrs) ->
    super #attrs

    @set( 'slider_right', 'oppose') if !!!@get( 'slider_right')
    @set( 'slider_left', 'support') if !!!@get( 'slider_left')

    @set( 'considerations_prompt', 'What are the most important pros and cons to you?') if !!!@get( 'considerations_prompt')
    @set( 'slider_prompt', 'What is your overall opinion given these Pros and Cons?') if !!!@get( 'slider_prompt')
    @set( 'statement_prompt', 'support') if !!!@get('statement_prompt')
    @set( 'pro_label', 'pro') if !!!@get('pro_label')
    @set( 'con_label', 'pro') if !!!@get('con_label')

  url : () ->
    Routes.account_path()

  get_pro_label : ({capitalize, plural}) ->
    capitalize ?= false
    plural ?= false

    @get_label(true, capitalize, plural)

  get_con_label : ({capitalize, plural}) ->
    capitalize ?= false
    plural ?= false

    @get_label(false, capitalize, plural)


  get_label : (is_pro, capitalize, plural) ->
    label = if is_pro then @get('pro_label') else @get('con_label')
    if capitalize
      label = label.charAt(0).toUpperCase() + label.slice(1)
    if plural #TODO: better solution
      label = label + 's'
    label
