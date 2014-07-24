@ConsiderIt.module "Dash.Admin", (Admin, App, Backbone, Marionette, $, _) ->

  class Admin.AdminController extends App.Dash.RegionController
    admin_template_needed : true
    auth : 'is_admin'

    initialize : (options = {} ) ->
      if !@hasPermission()
        App.navigate Routes.root_path(), {trigger : true}
        toastr.error 'Sorry, you need to sign in first to access that page'
        @redirected = true

      if !App.request("admin_templates_loaded?")
        $('head').append ConsiderIt.admin_files.style_tag
        $('head').append ConsiderIt.admin_files.js_tag
      super options

    hasPermission : ->
      current_user = App.request 'user:current'
      current_user && current_user.permissions()[@auth]

  class Admin.AppSettingsController extends Admin.AdminController
    admin_template_needed : true
    auth : 'is_admin'

    data_uri : -> 
      if App.request("tenant").fully_loaded
        null
      else 
        Routes.account_path()

    process_data_from_server : (data) ->
      App.request("tenant").add_full_data(data.account.account)
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'account:updated', (data) ->
        App.request "tenant:update", data
        @region.show layout
      layout

    getLayout : ->
      new Admin.AppSettingsView
        model: App.request("tenant")

  # class Admin.ManageProposalsController extends Dash.AdminController
  #   setupLayout : ->
  #     layout = @getLayout()
  #     layout

  #   getLayout : ->
  #     new Admin.ManageProposalsView
  #       active_proposals : ConsiderIt.all_proposals.where {active: true}
  #       inactive_proposals : ConsiderIt.all_proposals.where {active: false}


  class Admin.UserRolesController extends Admin.AdminController
    auth : 'is_admin'
    admin_template_needed : true

    #TODO: cache this data
    data_uri : -> 
      Routes.manage_roles_path()

    process_data_from_server : (data) ->
      App.request 'users:update', data.users_by_roles_mask
      @collection = App.request 'users'
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'role:edit:requested', (user_id) =>
        user = @collection.get user_id
        view = new Admin.EditUserRoleView
          model : user

        @listenTo view, 'role:changed', (data) =>
          user.updateRole data.roles_mask
          dialog.close()          
          layout.render()

        dialog = App.request 'dialog:new', view,
          class : 'user_roles-edit_form'

      layout

    getLayout : ->
      new Admin.UserRolesView
        collection : @collection


  class Admin.ImportDataController extends Admin.AdminController
    auth : 'is_manager'
    admin_template_needed : true

    data_uri : ->
      Routes.import_data_path()

    process_data_from_server : (data) -> 
      data

    setupLayout : ->
      layout = @getLayout()

      @listenTo layout, 'data:imported', (result) =>
        if result.proposals && result.proposals.length > 0
          App.vent.trigger "proposals:fetched", result.proposals

      layout

    getLayout : ->
      new Admin.ImportDataView


  class Admin.DatabaseController extends Admin.AdminController
    auth : 'is_admin'

    setupLayout : ->
      @getLayout()
    
    getLayout : ->
      new Admin.DatabaseView

  class Admin.ClientErrorsController extends Admin.AdminController
    auth : 'is_developer'
    admin_template_needed : true

    data_uri : -> 
      Routes.client_error_path()

    process_data_from_server : (data) ->
      App.vent.trigger 'javascript:errors:fetched', data.errors
      data

    setupLayout : ->
      layout = @getLayout()


      layout

    getLayout : ->
      new Admin.ClientErrorsView