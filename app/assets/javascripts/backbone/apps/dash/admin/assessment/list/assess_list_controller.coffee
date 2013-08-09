@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.AssessmentsController extends App.Dash.Admin.AdminController
    data_uri : ->
      Routes.assessment_index_path()

    process_data_from_server : (data) ->
      assessable_objects = {}
      for obj in data.assessable_objects
        assessable_objects[obj.point.id] = new ConsiderIt.Point obj.point

      root_objects = {}
      for obj in data.root_objects
        root_objects[obj.proposal.id] = new ConsiderIt.Proposal obj.proposal

      assessments = []
      for obj in data.assessments
        assessment = new App.Entities.Assessment obj.assessment
        assessable_obj = assessable_objects[assessment.get('assessable_id')]
        assessment.set_assessable_obj assessable_obj
        assessment.set_root_obj root_objects[assessable_obj.get('proposal_id')]
        assessments.push assessment

      @assessments = new Backbone.Collection assessments,
        comparator : (assessment) -> assessment.get "created_at"

      data

    setupLayout : ->
      layout = @getLayout()
      # @listenTo layout, 'account:updated', (data) ->
      #   App.request "tenant:update", data.user
      #   layout.render()
      layout

    getLayout : ->
      
      new Assessment.AssessmentListView
        collection : @assessments
