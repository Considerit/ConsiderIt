@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->
  class Dash.Router extends Marionette.AppRouter
    appRoutes :
      "dashboard/application" : "appSettings"
      "dashboard/proposals" : "manageProposals"
      "dashboard/roles" : "userRoles"
      "dashboard/users/:id/profile" : "userProfile"
      "dashboard/users/:id/profile/edit" : "editProfile"
      "dashboard/users/:id/profile/edit/account" : "accountSettings"
      "dashboard/users/:id/profile/edit/notifications" : "emailNotifications"
      "dashboard/analytics" : "analyze"
      "dashboard/data" : "database"
      "dashboard/moderate" : "moderate"
      "dashboard/assessment" : "assess"

  API =

    userProfile : (user_id) ->
      user = ConsiderIt.users[user_id]
      dashboard_controller = @_getDash()      
      new Dash.UserProfileController
        region : dashboard_controller.layout.mainRegion
        model : user      
    
    editProfile : (user_id) ->
      user = ConsiderIt.request('user:current')
      dashboard_controller = @_getDash()      
      new Dash.EditProfileController
        region : dashboard_controller.layout.mainRegion
        model : user   

    accountSettings : (user_id) ->
      user = ConsiderIt.request('user:current')
      dashboard_controller = @_getDash()      
      new Dash.AccountSettingsController
        region : dashboard_controller.layout.mainRegion
        model : user   

    emailNotifications : (user_id) ->
      user = if ConsiderIt.request("user:current:logged_in?") then ConsiderIt.request('user:current') else ConsiderIt.request("user:fixed")
      dashboard_controller = @_getDash()      
      new Dash.EmailNotificationsController
        region : dashboard_controller.layout.mainRegion
        model : user

    appSettings : ->
      dashboard_controller = @_getDash()      
      new Dash.AppSettingsController
        region : dashboard_controller.layout.mainRegion

    manageProposals : ->
      dashboard_controller = @_getDash()      
      new Dash.ManageProposalsController
        region : dashboard_controller.layout.mainRegion

    userRoles : ->
      dashboard_controller = @_getDash()      
      new Dash.UserRolesController
        region : dashboard_controller.layout.mainRegion

    analyze : ->
      dashboard_controller = @_getDash()      
      new Dash.AnalyticsController
        region : dashboard_controller.layout.mainRegion

    database : ->
      dashboard_controller = @_getDash()      
      new Dash.DatabaseController
        region : dashboard_controller.layout.mainRegion        

    assess : ->
      dashboard_controller = @_getDash()      
      new Dash.AssessmentController
        region : dashboard_controller.layout.mainRegion

    moderate : ->
      dashboard_controller = @_getDash()      
      new Dash.ModerationController
        region : dashboard_controller.layout.mainRegion

    unauthorizedPage : ->
      @current_region_controller = @_getDash() 
      new Dash.UnauthorizedController
        region : dashboard_controller.layout.mainRegion


    _getDash : ->
      if !@dashboard
        @dashboard = new Dash.Controller()
        App.vent.on 'dashboard:region:rendered', (model, dash_name) =>
          model ?= App.request 'user:current'
          @dashboard.renderSidebar(model, dash_name)
        @dashboard.region.show @dashboard.layout

      @dashboard

  App.reqres.setHandler "admin_templates_loaded?", ->
    $('#tpl_dashboard_app_settings').length > 0

  App.vent.on 'authorization:page_not_allowed', ->
    API.unauthorizedPage()

  App.vent.on 'dashboard:profile_requested', ->
    API.userProfile()

  App.vent.on 'dashboard:edit_profile_requested', ->
    API.editProfile()
  
  App.addInitializer ->
    new Dash.Router
      controller: API
