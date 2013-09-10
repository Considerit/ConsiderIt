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
        context = new Assessment.EditContextView
          model : assessment
          root_object : assessment.getRoot()
          assessable : assessment.getAssessable()

        layout.contextRegion.show context

        requests = new Assessment.RequestsView
          collection : assessment.getRequests()

        layout.requestsRegion.show requests

        claims = new Assessment.ClaimsView
          collection: assessment.getClaims()
          assessment : assessment
          all_claims : App.request 'claims:get:proposal', assessment.getRoot().id  #all claims for this proposal

        # @listenTo claims, 'claim:created', (claim) ->
        #   claims.collection.add claim

        # @listenTo claims, 'childview:claim:deleted', (claim) -> 
        #   claims.collection.remove claim

        # @listenTo claims, 'childview:claim:updated', (claim, params) ->
        #   claim.set params

        layout.claimsRegion.show claims

        forms = new Assessment.EditFormsView
          model : assessment

        # @listenTo forms, 'assessment:updated', (assessment) ->
        #   assessment.set assessment

        layout.formRegion.show forms

      layout


    getLayout : (model) ->
      new Assessment.EditLayout
        model : model
