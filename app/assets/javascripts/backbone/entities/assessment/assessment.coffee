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

    getClaims : ->
      if !@claims
        @claims = App.request 'claims:get', @id
      @claims

    status : ->
      if @get('complete') then "completed" else if @get('reviewable') then 'reviewable' else 'incomplete'

  class Entities.Assessments extends App.Entities.Collection
    model : Entities.Assessment

    parse : (attrs) ->
      attrs

  class Entities.Claim extends App.Entities.Model
    name: 'claim'

    initialize : (options = {}) ->
      super options
      #TODO: store this as an html attribute...
      @attributes.result = htmlFormat @attributes.result

    format_verdict : ->

      switch @get 'verdict'
        when 2 then 'Accurate'
        when 1 then 'Unverifiable'
        when 0 then 'Questionable'
        when -1 then 'No checkable claims'
        else '-'

    set_assessment : (assessment) ->
      @assessment = assessment

  class Entities.Claims extends App.Entities.Collection
    model : Entities.Claim

  class Entities.Request extends App.Entities.Model
    name: 'request'

  class Entities.Requests extends App.Entities.Collection
    model : Entities.Request

  CLAIMS_API = 
    all_claims : new Entities.Claims

    addClaims : (claims) ->
      console.log claims

      @all_claims.add @all_claims.parse(claims)

    getClaims : (assessment_id) ->
      claims = @all_claims.where { assessment_id : assessment_id }
      claims

  App.reqres.setHandler 'claims:get', (assessment_id) ->
    CLAIMS_API.getClaims assessment_id

  App.reqres.setHandler 'claims:add', (claims) ->
    CLAIMS_API.addClaims claims

  REQUEST_API = 
    all_requests : new Entities.Requests

    requestByUser : (assessment_id, user_id) ->
      @all_requests.findWhere { assessment_id : assessment_id, user_id : user_id }

    addRequest : (request) ->
      @all_requests.add request

  ASSESSMENT_API = 
    all_assessments : new Entities.Assessments

    addAssessments : (assessments) ->
      @all_assessments.add @all_assessments.parse(assessments)

    getAssessmentByPoint : (point_id) ->
      assessment = @all_assessments.findWhere {assessable_type : 'Point', assessable_id : point_id}
      assessment

  App.reqres.setHandler 'assessments:add', (assessments) ->
    ASSESSMENT_API.addAssessments assessments

  App.reqres.setHandler 'assessment:get:point', (point_id) ->
    ASSESSMENT_API.getAssessmentByPoint point_id

  App.reqres.setHandler 'assessment:request:by_user', (assessment_id, user_id) ->
    REQUEST_API.requestByUser assessment_id, user_id

  App.reqres.setHandler 'assessment:request:add', (request) ->
    REQUEST_API.addRequest request
