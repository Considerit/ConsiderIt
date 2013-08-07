@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->
  class Dash.AssessmentController extends Dash.AdminController
    data_uri : ->
      Routes.assessment_index_path()

    process_data_from_server : (data) ->
      data

    setupLayout : ->
      layout = @getLayout()
      # @listenTo layout, 'account:updated', (data) ->
      #   App.request "tenant:update", data.user
      #   layout.render()
      layout

    getLayout : ->
      new Dash.AssessmentView
