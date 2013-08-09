@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.Router extends Marionette.AppRouter
    appRoutes :
      "dashboard/assessment" : "list"
      "dashboard/assessment/:id/edit" : "edit"

  API =

    list : ->
      new Assessment.AssessmentsController
        region : App.request 'dashboard:mainRegion'

    edit : (id, model = null) ->
      new Assessment.AssessmentEditController
        region : App.request 'dashboard:mainRegion'
        model_id : id
        model : model

  App.vent.on 'assessment:edit', (model) ->
    API.edit model.id, model  

  App.addInitializer ->
    new Assessment.Router
      controller: API
