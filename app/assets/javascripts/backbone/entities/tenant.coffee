@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  class Entities.Tenant extends App.Entities.Model
    name : 'tenant'
    CLASSES_TO_MODERATE : [ ['points','Point'], ['comments','Comment'], ['proposals', 'Proposal']]

    defaults : 
      slider_right : 'oppose'
      slider_left : 'support'
      considerations_prompt : 'What are the most important pros and cons to you?'
      slider_prompt : 'What is your overall opinion given these Pros and Cons?'
      statement_prompt : 'support'
      pro_label : 'pro'
      con_label : 'con'


    url : () ->
      Routes.account_path()

    initialize : (options = {}) ->
      super options

      # Overwrite null and blank values for default fields
      _.each _.keys(@defaults), (key) =>
        @set(key, @defaults[key]) if !!!@get(key)

      #TODO: create HTML version of each of these fields and use those to render when appropriate
      @attributes.header_text = htmlFormat(@attributes.header_text)
      @attributes.header_details_text = htmlFormat(@attributes.header_details_text)


    classesToModerate : ->
      classes = []

      if @get('enable_moderation')
        _.each @CLASSES_TO_MODERATE, (table) =>
          classes.push(table) if @get("moderate_#{table[0]}_mode") > 0

      classes

    # TODO : refactor this method out
    add_full_data : (data) ->
      @set data
      @fully_loaded = true


    getProLabel : ({capitalize, plural} = {}) ->
      capitalize ?= false
      plural ?= false

      @_getLabel true, capitalize, plural

    getConLabel : ({capitalize, plural} = {}) ->
      capitalize ?= false
      plural ?= false

      @_getLabel false, capitalize, plural

    _getLabel : (is_pro, capitalize, plural) ->
      label = if is_pro then @get('pro_label') else @get('con_label')
      if capitalize
        label = label.charAt(0).toUpperCase() + label.slice(1)
      if plural #TODO: better solution
        label = label + 's'

      label




  API = 
    current_tenant : null

    getTenant : ->
      @current_tenant

    setTenant : (attrs) ->
      @current_tenant = new Entities.Tenant attrs

    updateTenant : (attrs) ->
      @current_tenant.set attrs
      App.vent.trigger "tenant:updated"

  App.reqres.setHandler "tenant:get", ->
    API.getTenant()

  App.reqres.setHandler "tenant:update", (data) ->
    API.updateTenant data

  App.on 'initialize:before', ->
    API.setTenant ConsiderIt.current_tenant_data
    ConsiderIt.current_tenant_data = null