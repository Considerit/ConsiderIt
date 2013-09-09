@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.AssessmentEditController extends App.Dash.Admin.AdminController
    data_uri : ->
      Routes.edit_assessment_path @options.model_id

    process_data_from_server : (data) ->
      #TODO: store all instantiated assessments on app and make request for them
      @model = false || new App.Entities.Assessment data.assessment

      @model.set_assessable_obj new ConsiderIt.Point data.assessable_obj.point
      @model.set_root_obj new ConsiderIt.Proposal data.root_object.proposal

      @model.set_claims new Backbone.Collection data.claims,
        model : App.Entities.Claim

      @model.claims.each (claim) =>
        claim.set_assessment @model

      @all_claims = new Backbone.Collection data.all_claims,
        model : App.Entities.Claim

      @model.set_requests new Backbone.Collection data.requests,
        model : App.Entities.Request
        comparator : (rq) -> rq.get('created_at')

    setupLayout : ->
      layout = @getLayout()

      @listenTo layout, 'show', ->
        context = new Assessment.EditContextView
          model : @model
          root_object : @model.root_obj
          assessable : @model.assessable_obj

        layout.contextRegion.show context

        requests = new Assessment.RequestsView
          collection : @model.requests

        layout.requestsRegion.show requests

        claims = new Assessment.ClaimsView
          collection: @model.claims
          all_claims : @all_claims
          assessment : @model

        @listenTo claims, 'claim:created', (claim) ->
          claims.collection.add claim

        @listenTo claims, 'childview:claim:deleted', (claim) -> 
          claims.collection.remove claim

        @listenTo claims, 'childview:claim:updated', (claim, params) ->
          claim.set params

        layout.claimsRegion.show claims

        forms = new Assessment.EditFormsView
          model : @model

        @listenTo forms, 'assessment:updated', (assessment) ->
          @model.set assessment

        layout.formRegion.show forms

      layout


    getLayout : ->
      new Assessment.EditLayout
