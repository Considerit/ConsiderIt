@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->
  class Dash.Router extends Marionette.AppRouter
    appRoutes :
      "dashboard/application(/)" : "appSettings"
      #"dashboard/proposals" : "manageProposals"
      "dashboard/roles(/)" : "userRoles"
      "dashboard/users/:id/profile(/)" : "userProfile"
      "dashboard/users/:id/profile/edit(/)" : "editProfile"
      "dashboard/users/:id/profile/edit/account(/)" : "accountSettings"
      "dashboard/users/:id/profile/edit/notifications(/)" : "emailNotifications"
      "dashboard/analytics(/)" : "analyze"
      "dashboard/data(/)" : "database"
      "dashboard/moderate(/)" : "moderate"
      "dashboard/import_data(/)" : "importData"
      "dashboard/client_errors(/)" : "clientErrors"

  API =

    userProfile : (user_id) ->
      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      user = App.request 'user', user_id
      @current_controller = new Dash.User.UserProfileController
        region : @_getMainRegion()  
        model : user  

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["#{user.get('name')}", Routes.profile_path(user.id)] ]
      App.request 'meta:change:default'

    
    editProfile : (user_id) ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      current_user = ConsiderIt.request 'user:current'
      @current_controller = new Dash.User.EditProfileController
        region : @_getMainRegion()  
        model : current_user   

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["profile", Routes.edit_profile_path(current_user.id)] ]
      App.request 'meta:change:default'

    accountSettings : (user_id) ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      current_user = ConsiderIt.request 'user:current'
      @current_controller = new Dash.User.AccountSettingsController
        region : @_getMainRegion()  
        model : current_user   

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["account", Routes.edit_account_path(current_user.id)] ]
      App.request 'meta:change:default'


    emailNotifications : (user_id) ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      user = if ConsiderIt.request("user:is_client_logged_in?") then ConsiderIt.request('user:current') else ConsiderIt.request("user:fixed")
      @current_controller = new Dash.User.EmailNotificationsController
        region : @_getMainRegion()  
        model : user

      App.vent.trigger 'route:completed', [ 
        ['homepage', '/'], 
        ["notifications", Routes.edit_notifications_path(user.id)] ]
      App.request 'meta:change:default'


    appSettings : ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.AppSettingsController
        region : @_getMainRegion()  

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["Application", Routes.account_path()] ]
        App.request 'meta:change:default'


    # manageProposals : ->
    #   new Dash.Admin.ManageProposalsController
    #     region : @_getMainRegion()  

    #   App.vent.trigger 'route:completed', [ 
    #     ['homepage', '/'], 
    #     ["Manage proposals", Routes.account_path()]         

    userRoles : ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.UserRolesController
        region : @_getMainRegion()  

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["User roles", Routes.manage_roles_path()] ]
        App.request 'meta:change:default'


    analyze : ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.Analytics.AnalyticsController
        region : @_getMainRegion()  

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["Analytics", Routes.analytics_path()] ]
        App.request 'meta:change:default'
  

    importData : ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.ImportDataController
        region : @_getMainRegion()  

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["Import data", Routes.import_data_path()] ]
        App.request 'meta:change:default'

    database : ->

      $(document).scrollTop(0)

      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.DatabaseController
        region : @_getMainRegion()        

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["Database", Routes.rails_admin_dashboard_path()] ]
        App.request 'meta:change:default'

    moderate : ->

      $(document).scrollTop(0)
      
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.Moderation.ModerationController
        region : @_getMainRegion()  

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["moderate", Routes.dashboard_moderate_path()] ]
        App.request 'meta:change:default'

    clientErrors : ->
      $(document).scrollTop(0)
      
      @current_controller.close() if @current_controller      
      @current_controller = new Dash.Admin.ClientErrorsController
        region : @_getMainRegion()  

      if !@current_controller.redirected

        App.vent.trigger 'route:completed', [ 
          ['homepage', '/'], 
          ["client_errors", Routes.client_error_path()] ]
        App.request 'meta:change:default'


    unauthorizedPage : ->
      @current_controller.close() if @current_controller
      @current_controller = new Dash.UnauthorizedController
        region : @_getMainRegion()  


    _getMainRegion : ->

      region = App.request 'default:region'

      if @dashboard && region.controlled_by != @dashboard
        @dashboard.close() 
        @dashboard = null

      if region.controlled_by && region.controlled_by != @dashboard
        region.controlled_by.close()

      if !@dashboard
        @dashboard = new Dash.DashController
          region : region

        region.controlled_by = @dashboard
        
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
