@ConsiderIt.module "Dash.Admin", (Admin, App, Backbone, Marionette, $, _) ->

  class Admin.AppSettingsView extends App.Dash.View
    dash_name : 'app_settings'
    checkboxes : [
      #['account', 'assessment_enabled', 'account_assessment_enabled'],
      #['account', 'enable_position_statement', 'account_enable_position_statement'],
      ['account', 'enable_user_conversations', 'account_enable_user_conversations'], 
      ['account', 'enable_sharing', 'account_enable_sharing'],
      ['account', 'enable_hibernation', 'account_enable_hibernation'],
      ['account', 'requires_civility_pledge_on_registration', 'account_requires_civility_pledge_on_registration']

    ]

    radioboxes : []

    serializeData : ->
      @model.attributes

    onShow : ->
      super
      @$el.find('#account_header_text').autosize()
      @$el.find('#account_header_details_text').autosize()

      @$el.find('.l-expandable-option').each (idx, $expandable) =>
        @toggleExpandable 
          currentTarget : $expandable

    events : 
      'ajax:complete .dashboard-edit-account' : 'accountUpdated'
      'click .l-expandable-option input' : 'toggleExpandable'

    accountUpdated : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'account:updated', data.account

      App.execute 'notify:success', 'Account updated'


    toggleExpandable : (ev) ->
      $expandable_option = $(ev.currentTarget).closest('.l-expandable-option')
      $expandable_area = $expandable_option.siblings('.l-expandable-area')

      if $expandable_option.find('input').is(':checked')
        $expandable_area.slideDown()
      else
        $expandable_area.slideUp()


  # class Admin.ManageProposalsView extends App.Dash.View
  #   dash_name : 'manage_proposals'

  #   serializeData : ->
  #     active_proposals : @options.active_proposals
  #     inactive_proposals : @options.inactive_proposals


  class Admin.UserRolesView extends App.Dash.View
    dash_name : 'user_roles'
    templates : {}

    serializeData : ->
      users_by_roles_mask: @collection

    onShow : ->
      super
      @$el.find('#account_header_text').autosize()
      @$el.find('#account_header_details_text').autosize()

    events : 
      'click .user_roles-invoke_role_change' : 'editRole'

    editRole : (ev) ->

      @trigger 'role:edit:requested', $(ev.currentTarget).data('id')


  class Admin.EditUserRoleView extends App.Dash.View
    dash_name : 'user_roles_edit'

    serializeData : ->
      tenant = App.request 'tenant'
      _.extend {}, @model.attributes,
        enable_moderation : tenant.get 'enable_moderation'
        enable_assessment : tenant.get 'assessment_enabled'

    dialog: =>
      name = if @model.get('name') && @model.get('name').length > 0 then @model.get('name') else @model.get('email')

      return {
        title : "Authorized roles for #{ name }"
      }

    onShow : ->
      super
      @checkBox @model, null, 'user_role_admin', @model.hasRole('admin') || @model.hasRole('superadmin')
      @checkBox @model, null, 'user_role_specific', !@model.hasRole('admin') && @model.roles_mask > 0
      @checkBox @model, null, 'user_manager', @model.hasRole('manager')
      @checkBox @model, null, 'user_moderator', @model.hasRole('moderator')
      @checkBox @model, null, 'user_evaluator', @model.hasRole('evaluator')    
      @checkBox @model, null, 'user_analyst', @model.hasRole('analyst')
      @checkBox @model, null, 'user_role_user', @model.roles_mask == 0

    events : 
      'click .user_roles-edit_form input[type="checkbox"]' : 'roleEdited'
      'ajax:complete .user_roles-edit_form' : 'roleChanged'


    roleEdited : (ev) ->
      $(ev.currentTarget).closest('.user_roles-edit_form').find('.option.specific input[type="radio"]').trigger('click')

    roleChanged : (data, response, xhr) ->
      result = $.parseJSON(response.responseText)
      @trigger 'role:changed', result


  class Admin.DatabaseView extends App.Dash.View
    dash_name : 'database'

  class Admin.ImportDataView extends App.Dash.View
    dash_name : 'import_data'

    serializeData : ->
      tenant = App.request 'tenant'
      _.extend {},
        tenant : tenant.attributes
        current_user : App.request('user:current')

    events : 
      'ajax:complete .dashboard-import-data' : 'dataImported'

    dataImported : (data, response, xhr) ->
      result = $.parseJSON(response.responseText)
      if result.created > 0
        App.execute 'notify:success', "#{result.created} proposals created"

      if result.updated > 0
        App.execute 'notify:success', "#{result.updated} proposals updated"

      if result.errors > 0
        App.execute 'notify:failure', "#{result.errors} proposals were not updated because of errors"

      if App.request('tenant').get('theme') == 'lvg' && result.jurisdictions
        App.execute 'notify:success', "#{result.jurisdictions}"
        
        if result.jurisdiction_errors > 0
          App.execute 'notify:success', "Failed jurisdictions: #{result.jurisdiction_errors}"

      @trigger 'data:imported', result


  class Admin.ClientErrorsView extends App.Dash.View
    dash_name : 'client_errors'

    serializeData : ->
      _.extend {}, 
        errors : App.request 'javascript:errors:get'



