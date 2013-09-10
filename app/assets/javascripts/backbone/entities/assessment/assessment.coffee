@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Assessment extends App.Entities.Model
    name: 'assessment'

    initialize : (options = {}) ->
      super options

    getAssessable : ->
      if !@assessable
        @assessable = App.request "#{@get('assessable_type').toLowerCase()}:get", @get('assessable_id')
      @assessable

    getRoot : ->
      if !@root_obj
        assessable = @getAssessable()
        @root_obj = if assessable then assessable.getProposal() else null

      @root_obj

    getClaims : ->
      if !@claims
        @claims = App.request 'claims:get', @id
      @claims

    getRequests : ->
      if !@requests
        @requests = App.request 'assessment:requests:get', @id
      @requests

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

    getAssessment : ->
      if !@assessment
        @assessment = App.request 'assessment:get', @get('assessment_id')
      @assessment

    # set_assessment : (assessment) ->
    #   @assessment = assessment

  class Entities.Claims extends App.Entities.Collection
    model : Entities.Claim

  class Entities.Request extends App.Entities.Model
    name: 'request'

  class Entities.Requests extends App.Entities.Collection
    model : Entities.Request

  CLAIMS_API = 
    all_claims : new Entities.Claims
    claims_by_proposal : {}

    addClaims : (claims, proposal_id = null) ->
      claims = @all_claims.parse(claims)
      @all_claims.add claims      
      if proposal_id
        if !(proposal_id of @claims_by_proposal)
          @claims_by_proposal[proposal_id] = new Entities.Claims
        _.each claims, (c) =>
          @claims_by_proposal[proposal_id].add @all_claims.get(c.id)

    getClaims : (assessment_id) ->
      claims = new Entities.Claims @all_claims.where({ assessment_id : assessment_id })
      claims

    getClaimsForProposal : (proposal_id) ->
      if proposal_id of @claims_by_proposal
        claims = @claims_by_proposal[proposal_id]
      else
        # This method doesn't work unless a whole chain of data is actually loaded.
        throw 'claims not loaded for this proposal'
        # claims = new Entities.Claims
        # @all_claims.each (claim) ->
        #   assessment = claim.getAssessment()
        #   proposal = assessment.getRoot()
        #   claims.add(claim) if proposal && proposal.id == proposal_id
      claims

  App.reqres.setHandler 'claims:get', (assessment_id) ->
    CLAIMS_API.getClaims assessment_id

  App.reqres.setHandler 'claims:get:proposal', (proposal_id) ->
    CLAIMS_API.getClaimsForProposal proposal_id

  App.reqres.setHandler 'claims:add', (claims, proposal_id = null) ->
    CLAIMS_API.addClaims claims, proposal_id

  REQUEST_API = 
    all_requests : new Entities.Requests

    requestByUser : (assessment_id, user_id) ->
      @all_requests.findWhere { assessment_id : assessment_id, user_id : user_id }

    addRequest : (request) ->
      @all_requests.add request

    addRequests : (requests) ->
      @all_requests.add @all_requests.parse(requests)

    getRequests : (assessment_id) ->
      new Entities.Requests @all_requests.where({assessment_id : assessment_id})

  ASSESSMENT_API = 
    all_assessments : new Entities.Assessments

    getAssessments : ->
      @all_assessments

    getAssessment : (id) ->
      @all_assessments.get id

    addAssessments : (assessments) ->
      @all_assessments.add @all_assessments.parse(assessments)

    getAssessmentByPoint : (point_id) ->
      assessment = @all_assessments.findWhere {assessable_type : 'Point', assessable_id : point_id}
      assessment

  App.reqres.setHandler 'assessments:get', ->
    ASSESSMENT_API.getAssessments()

  App.reqres.setHandler 'assessment:get', (id) ->
    ASSESSMENT_API.getAssessment id

  App.reqres.setHandler 'assessments:add', (assessments) ->
    ASSESSMENT_API.addAssessments assessments

  App.reqres.setHandler 'assessment:get:point', (point_id) ->
    ASSESSMENT_API.getAssessmentByPoint point_id

  App.reqres.setHandler 'assessment:request:by_user', (assessment_id, user_id) ->
    REQUEST_API.requestByUser assessment_id, user_id

  App.reqres.setHandler 'assessment:request:add', (request) ->
    REQUEST_API.addRequest request

  App.reqres.setHandler 'assessment:requests:add', (requests) ->
    REQUEST_API.addRequests requests

  App.reqres.setHandler 'assessment:requests:get', (assessment_id) ->
    REQUEST_API.getRequests assessment_id
