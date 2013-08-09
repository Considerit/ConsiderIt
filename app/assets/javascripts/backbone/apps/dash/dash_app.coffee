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

  API =

    userProfile : (user_id) ->
      user = ConsiderIt.users[user_id]
      new Dash.User.UserProfileController
        region : @_getMainRegion()  
        model : user      
    
    editProfile : (user_id) ->
      user = ConsiderIt.request('user:current')
      new Dash.User.EditProfileController
        region : @_getMainRegion()  
        model : user   

    accountSettings : (user_id) ->
      user = ConsiderIt.request('user:current')
      new Dash.User.AccountSettingsController
        region : @_getMainRegion()  
        model : user   

    emailNotifications : (user_id) ->
      user = if ConsiderIt.request("user:current:logged_in?") then ConsiderIt.request('user:current') else ConsiderIt.request("user:fixed")
      new Dash.User.EmailNotificationsController
        region : @_getMainRegion()  
        model : user

    appSettings : ->
      new Dash.Admin.AppSettingsController
        region : @_getMainRegion()  

    manageProposals : ->
      new Dash.Admin.ManageProposalsController
        region : @_getMainRegion()  

    userRoles : ->
      new Dash.Admin.UserRolesController
        region : @_getMainRegion()  

    analyze : ->
      new Dash.Admin.AnalyticsController
        region : @_getMainRegion()  

    database : ->
      new Dash.Admin.DatabaseController
        region : @_getMainRegion()        

    moderate : ->
      new Dash.Admin.Moderation.ModerationController
        region : @_getMainRegion()  

    unauthorizedPage : ->
      new Dash.UnauthorizedController
        region : @_getMainRegion()  


    _getMainRegion : ->
      if !@dashboard
        @dashboard = new Dash.Controller()
        App.vent.on 'dashboard:region:rendered', (model, dash_name) =>
          model ?= App.request 'user:current'
          @dashboard.renderSidebar(model, dash_name)
        @dashboard.region.show @dashboard.layout

      @dashboard.layout.mainRegion

  App.reqres.setHandler "dashboard:mainRegion", ->
    API._getMainRegion()

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
