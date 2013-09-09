@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->
  class Dash.Router extends Marionette.AppRouter
    appRoutes :
      "dashboard/application" : "appSettings"
      #"dashboard/proposals" : "manageProposals"
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
      @current_controller.close() if @current_controller      
      user = App.request 'user', user_id
      @current_controller = new Dash.User.UserProfileController
        region : @_getMainRegion()  
        model : user  

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["#{user.get('name')}", Routes.profile_path(user.id)] ]

    
    editProfile : (user_id) ->
      @current_controller.close() if @current_controller      
      current_user = ConsiderIt.request 'user:current'
      @current_controller = new Dash.User.EditProfileController
        region : @_getMainRegion()  
        model : current_user   

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["profile", Routes.edit_profile_path(current_user.id)] ]

    accountSettings : (user_id) ->
      @current_controller.close() if @current_controller      
      current_user = ConsiderIt.request 'user:current'
      @current_controller = new Dash.User.AccountSettingsController
        region : @_getMainRegion()  
        model : current_user   

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["account", Routes.edit_account_path(current_user.id)] ]


    emailNotifications : (user_id) ->
      @current_controller.close() if @current_controller      
      user = if ConsiderIt.request("user:current:logged_in?") then ConsiderIt.request('user:current') else ConsiderIt.request("user:fixed")
      @current_controller = new Dash.User.EmailNotificationsController
        region : @_getMainRegion()  
        model : user

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["notifications", Routes.edit_notifications_path(user.id)] ]


    appSettings : ->
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.AppSettingsController
        region : @_getMainRegion()  

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["Application", Routes.account_path()] ]


    # manageProposals : ->
    #   new Dash.Admin.ManageProposalsController
    #     region : @_getMainRegion()  

    #   App.vent.trigger 'route:completed', [ 
    #     ['homepage', '/'], 
    #     ["Manage proposals", Routes.account_path()]         

    userRoles : ->
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.UserRolesController
        region : @_getMainRegion()  

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["User roles", Routes.manage_roles_path()] ]


    analyze : ->
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.AnalyticsController
        region : @_getMainRegion()  

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["Analytics", Routes.analytics_path()] ]

    database : ->
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.DatabaseController
        region : @_getMainRegion()        

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["Database", Routes.rails_admin_path()] ]

    moderate : ->
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.Moderation.ModerationController
        region : @_getMainRegion()  

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["moderate", Routes.dashboard_moderate_path()] ]

    unauthorizedPage : ->
      @current_controller.close() if @current_controller
      @current_controller = new Dash.UnauthorizedController
        region : @_getMainRegion()  


    _getMainRegion : ->
      if !@dashboard
        @dashboard = new Dash.Controller()
        App.vent.on 'dashboard:region:rendered', (model, dash_name) =>
          model ?= App.request 'user:current'
          @dashboard.renderSidebar model, dash_name
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
