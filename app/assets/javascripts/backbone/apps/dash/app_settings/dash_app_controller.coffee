@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.AdminController extends Dash.RegionController
    admin_template_needed : true

    initialize : (options = {} ) ->
      if !App.request("admin_templates_loaded?")
        $('head').append ConsiderIt.admin_files.style_tag
        $('head').append ConsiderIt.admin_files.js_tag
      super options

  class Dash.AppSettingsController extends Dash.AdminController
    admin_template_needed : true

    data_uri : -> 
      if ConsiderIt.current_tenant.fully_loaded
        null
      else 
        Routes.account_path()

    process_data_from_server : (data) ->
      ConsiderIt.current_tenant.add_full_data(data.account.account)
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'account:updated', (data) ->
        App.request "tenant:update", data.user
        layout.render()
      layout

    getLayout : ->
      new Dash.AppSettingsView


  # class Dash.ManageProposalsController extends Dash.AdminController
  #   setupLayout : ->
  #     layout = @getLayout()
  #     layout

  #   getLayout : ->
  #     new Dash.ManageProposalsView
  #       active_proposals : ConsiderIt.all_proposals.where {active: true}
  #       inactive_proposals : ConsiderIt.all_proposals.where {active: false}


  class Dash.UserRolesController extends Dash.AdminController

    #TODO: cache this data
    data_uri : -> 
      Routes.manage_roles_path()

    process_data_from_server : (data) ->
      @collection = new Backbone.Collection( (new ConsiderIt.User(user.user) for user in data.users_by_roles_mask)  )
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'role:edit:requested', (user_id) =>
        user = @collection.get user_id
        view = new Dash.EditUserRoleView
          model : user

        @listenTo view, 'role:changed', (data) =>
          user.update_role data.roles_mask
          dialog.close()          
          layout.render()

        dialog = App.request 'dialog:new', view,
          class : 'm-user_roles-edit_form'

      layout

    getLayout : ->
      new Dash.UserRolesView
        collection : @collection

  class Dash.AnalyticsController extends Dash.AdminController
    data_uri : ->
      Routes.analytics_path()

    process_data_from_server : (data) ->
      @analytics_data = data.analytics_data
      data

    setupLayout : ->
      @getLayout()

    getLayout : ->
      new Dash.AnalyticsView
        analytics_data : @analytics_data


  class Dash.DatabaseController extends Dash.AdminController
    setupLayout : ->
      @getLayout()
    
    getLayout : ->
      new Dash.DatabaseView
