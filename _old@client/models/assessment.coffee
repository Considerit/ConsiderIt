@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->


  class Entities.Assessment extends App.Entities.Model
    name: 'assessment'

    initialize : (options = {}) ->
      super options

    url : ->
      if @id
        Routes.assessment_path( @id )
      else
        Routes.assessment_index_path()

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

    allClaimsAnswered : ->
      ret = true
      @getClaims().each (c) ->
        return ret = false if !c.getVerdict() || !c.get('result')
      ret


    allClaimsApproved : ->
      ret = true
      @getClaims().each (c) ->
        return ret = false if !c.getApprover()
      ret

    getVerdict : ->
      return null if !@get('verdict_id')

      verdict = App.request 'verdict:get', @get('verdict_id')
      verdict



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

    url : ->
      if @id
        Routes.assessment_update_claim_path @get('assessment_id'), @id
      else 
        Routes.assessment_create_claim_path @get('assessment_id')

    getAssessment : ->
      if !@assessment
        @assessment = App.request 'assessment:get', @get('assessment_id')
      @assessment

    getCreator : ->
      if !@creator
        @creator = App.request 'user', @get('creator')
      @creator

    getApprover : ->
      return null if !@get('approver')

      if !@approver
        @approver = App.request 'user', @get('approver')
      @approver

    getVerdict : ->
      return null if !@get('verdict_id')

      verdict = App.request 'verdict:get', @get('verdict_id')
      verdict

    getThanks : ->
      @thanks = App.request 'thanks', 'Assessable::Claim', @id


  class Entities.Claims extends App.Entities.Collection
    model : Entities.Claim

  class Entities.Request extends App.Entities.Model
    name: 'request'

    parse : (attrs) ->
      App.request 'assessments:add', [attrs.assessment.assessment]
      attrs.request.request

  class Entities.Requests extends App.Entities.Collection
    model : Entities.Request

    url : ->
      Routes.assessment_index_path()


  class Entities.Verdict extends App.Entities.Model
    name : 'verdict'

    getIcon : ->
      url = "#{ConsiderIt.public_root}/system/icons/#{@id}/original/#{@get('icon_file_name')}"
      url

  class Entities.Verdicts extends App.Entities.Collection
    model : Entities.Verdict

  VERDICTS_API = 
    all_verdicts : new Entities.Verdicts

    addVerdicts : (verdicts) ->
      @all_verdicts.add verdicts

    getVerdict : (verdict_id) ->
      @all_verdicts.get verdict_id

    getVerdicts : ->
      @all_verdicts

  App.reqres.setHandler 'verdicts:add', (verdicts) ->
    VERDICTS_API.addVerdicts verdicts

  App.reqres.setHandler 'verdict:get', (verdict_id) ->
    VERDICTS_API.getVerdict verdict_id

  App.reqres.setHandler 'verdicts:get', ->
    VERDICTS_API.getVerdicts()

  CLAIMS_API = 
    all_claims : new Entities.Claims
    claims_by_proposal : {}

    createClaim : (attrs, options) ->
      options.success = (model, response) =>
        model.set response
      claim = @all_claims.create attrs, options
      claim

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

  App.reqres.setHandler 'claim:create', (attrs, options = {wait: true}) ->
    CLAIMS_API.createClaim attrs, options

  REQUEST_API = 
    all_requests : new Entities.Requests

    requestByUser : (assessable_id, user_id) ->

      result = @all_requests.findWhere { assessable_id : assessable_id, user_id : user_id }
      result

    addRequest : (request) ->
      @all_requests.add request

    createRequest : (attrs) ->
      rq = @all_requests.create attrs, {wait: true}
      rq

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
      @all_assessments.add @all_assessments.parse(assessments), {merge: true}

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

  App.reqres.setHandler 'assessment:request:by_user', (assessable_id, user_id) ->
    REQUEST_API.requestByUser assessable_id, user_id

  App.reqres.setHandler 'assessment:request:create', (attrs) ->
    REQUEST_API.createRequest attrs

  App.reqres.setHandler 'assessment:request:add', (request) ->
    REQUEST_API.addRequest request

  App.reqres.setHandler 'assessment:requests:add', (requests) ->
    REQUEST_API.addRequests requests

  App.reqres.setHandler 'assessment:requests:get', (assessment_id) ->
    REQUEST_API.getRequests assessment_id
