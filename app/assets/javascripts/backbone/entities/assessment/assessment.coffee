@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Assessment extends App.Entities.Model
    name: 'assessment'

    initialize : (options = {}) ->
      super options

    set_assessable_obj : (obj) ->
      @assessable_obj = obj

    set_root_obj : (obj) ->
      @root_obj = obj

    set_claims : (claims) ->
      @claims = claims

    set_requests : (requests) ->
      @requests = requests

    status : ->
      if @get('complete') then "completed" else if @get('reviewable') then 'reviewable' else 'incomplete'


  class Entities.Claim extends App.Entities.Model
    name: 'claim'

    initialize : (options = {}) ->
      super options
      #TODO: store this as an html attribute...
      @attributes.result = htmlFormat @attributes.result

    format_verdict : ->

      switch @get('verdict')
        when 2 then 'Accurate'
        when 1 then 'Unverifiable'
        when 0 then 'Questionable'
        when -1 then 'No checkable claims'
        else '-'

    set_assessment : (assessment) ->
      @assessment = assessment

  class Entities.Request extends App.Entities.Model
    name: 'request'
