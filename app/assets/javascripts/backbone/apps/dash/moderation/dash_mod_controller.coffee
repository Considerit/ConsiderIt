@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->
  class Dash.ModerationController extends Dash.AdminController
    data_uri : ->
      Routes.dashboard_moderate_path()

    process_data_from_server : (data) ->
      @data = data
      data

    setupLayout : ->
      layout = @getLayout()
      # @listenTo layout, 'account:updated', (data) ->
      #   App.request "tenant:update", data.user
      #   layout.render()
      layout

    getLayout : ->
      new Dash.ModerationView
        objs_to_moderate : @data.objs_to_moderate
        existing_moderations : @data.existing_moderations
        classes_to_moderate : @data.classes_to_moderate