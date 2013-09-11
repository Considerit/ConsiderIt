@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.AssessmentEditController extends App.Dash.Admin.AdminController
    data_uri : ->
      Routes.edit_assessment_path @options.model_id

    process_data_from_server : (data) ->
      App.request 'assessments:add', [data.assessment]
      App.vent.trigger 'points:fetched', [data.assessable_obj.point]
      App.vent.trigger 'proposals:fetched', [data.root_object.proposal]
      App.request 'claims:add', (c.claim for c in data.claims)
      App.request 'claims:add', (c.claim for c in data.all_claims), data.root_object.proposal.id
      App.request 'assessment:requests:add', (r.request for r in data.requests)

    setupLayout : ->
      assessment = App.request 'assessment:get', @options.model_id

      layout = @getLayout assessment

      @listenTo layout, 'show', ->
        context = new Assessment.ContextView
          model : assessment
          root_object : assessment.getRoot()
          assessable : assessment.getAssessable()

        layout.contextRegion.show context

        requests = new Assessment.RequestsView
          collection : assessment.getRequests()

        layout.requestsRegion.show requests

        claims_collection = assessment.getClaims()
        claims = new Assessment.ClaimsView
          collection: claims_collection
          assessment : assessment

        # @listenTo claims, 'claim:created', (claim) ->
        #   claims.collection.add claim

        @listenTo claims, 'claim:new', => @setupNewClaimView assessment, claims_collection


        @listenTo claims, 'childview:claim:delete', (view) -> 
          view.model.destroy()

        @listenTo claims, 'childview:claim:edit', (view) => @setupEditClaimView view.model


        # @listenTo claims, 'childview:claim:updated', (claim, params) ->
        #   claim.set params

        layout.claimsRegion.show claims

        forms = new Assessment.EditFormsView
          model : assessment

        # @listenTo forms, 'assessment:updated', (assessment) ->
        #   assessment.set assessment

        layout.footerRegion.show forms

      layout

    setupNewClaimView : (assessment, claims_collection) ->
      new_claim_view = @getNewClaimView assessment

      @listenTo new_claim_view, 'show', =>
        @listenTo new_claim_view, 'claim:create', (attrs) =>
          attrs.assessment_id = assessment.id
          claim = App.request 'claim:create', attrs
          App.execute 'when:fetched', claim, =>
            claims_collection.add claim
            new_claim_view.close()

      overlay = App.request 'dialog:new', new_claim_view, 
        class: 'overlay_claim_view'

    setupEditClaimView : (claim) ->
      edit_claim_view = @getEditClaimView claim

      @listenTo edit_claim_view, 'show', =>

      overlay = App.request 'dialog:new', edit_claim_view,
        class: 'overlay_claim_view'


    getNewClaimView : (assessment) ->
      new Assessment.ClaimForm
        assessment: assessment
        all_claims: App.request 'claims:get:proposal', assessment.getRoot().id

    getEditClaimView : (model) ->
      new Assessment.EditClaimForm
        model : model

    getLayout : (model) ->
      new Assessment.EditLayout
        model : model
