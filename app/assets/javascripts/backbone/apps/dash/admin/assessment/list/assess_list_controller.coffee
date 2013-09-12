@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.AssessmentsController extends App.Dash.Admin.AdminController
    
    setupLayout : ->
      collection = new App.Entities.Assessments App.request('assessments:get').models,
        comparator : (assessment) -> - new Date(assessment.get("created_at")).getTime()

      layout = @getLayout()
      @listenTo layout, 'show', ->
        list = new Assessment.AssessmentListView
          collection : collection

        layout.listRegion.show list

      # @listenTo layout, 'account:updated', (data) ->
      #   App.request "tenant:update", data.user
      #   layout.render()
      layout

    data_uri : ->
      Routes.assessment_index_path()

    process_data_from_server : (data) ->
      App.vent.trigger 'points:fetched', (p.point for p in data.assessable_objects)
      App.vent.trigger 'proposals:fetched', (p.proposal for p in data.root_objects)
      App.request 'verdicts:add', (v.verdict for v in data.verdicts)
      App.request 'assessments:add', (a.assessment for a in data.assessments)
      data

    getLayout : ->
      new Assessment.AssessmentListLayout
