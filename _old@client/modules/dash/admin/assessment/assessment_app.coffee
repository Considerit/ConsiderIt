@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.Router extends Marionette.AppRouter
    appRoutes :
      "dashboard/assessment(/)" : "list"
      "dashboard/assessment/:id/edit(/)" : "edit"

  API =

    list : ->
      $(document).scrollTop(0)

      new Assessment.AssessmentsController
        region : App.request 'dashboard:mainRegion'

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["Assess", Routes.assessment_index_path()] ]     

    edit : (id, model = null) ->      
      $(document).scrollTop(0)
      
      new Assessment.AssessmentEditController
        region : App.request 'dashboard:mainRegion'
        model_id : id
        model : model

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["Assess", Routes.assessment_index_path()] 
        ["Edit", Routes.assessment_path(id)] ]       


  App.vent.on 'assessment:edit', (model) ->
    API.edit model.id, model  

  App.addInitializer ->
    new Assessment.Router
      controller: API
