@ConsiderIt.module "Dash.Admin", (Admin, App, Backbone, Marionette, $, _) ->

  class Admin.AppSettingsView extends App.Dash.View
    dash_name : 'app_settings'
    checkboxes : [
      ['account', 'assessment_enabled', 'account_assessment_enabled'],
      ['account', 'enable_moderation', 'account_enable_moderation'],
      ['account', 'enable_position_statement', 'account_enable_position_statement'],
      ['account', 'enable_user_conversations', 'account_enable_user_conversations'], 
      ['account', 'requires_civility_pledge_on_registration', 'account_requires_civility_pledge_on_registration']
    ]

    radioboxes : [
      ['account', 'moderate_points_mode', 'account_moderate_points_mode'],
      ['account', 'moderate_comments_mode', 'account_moderate_comments_mode'],
      ['account', 'moderate_proposals_mode', 'account_moderate_proposals_mode'],      
    ]

    serializeData : ->
      @model.attributes

    onShow : ->
      super
      @$el.find('#account_header_text').autosize()
      @$el.find('#account_header_details_text').autosize()
      @toggleModeration()

    events : 
      'ajax:complete .m-dashboard-edit-account' : 'accountUpdated'
      'click #account_enable_moderation' : 'toggleModeration'

    accountUpdated : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'account:updated', data.account

      toastr.success 'Account updated'


    toggleModeration : ->
      if @$el.find('#account_enable_moderation').is(':checked')
        @$el.find('.m-moderation-settings').slideDown()
      else
        @$el.find('.m-moderation-settings').slideUp()


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
      'click .m-user_roles-invoke_role_change' : 'editRole'

    editRole : (ev) ->

      @trigger 'role:edit:requested', $(ev.currentTarget).data('id')


  class Admin.EditUserRoleView extends App.Dash.View
    dash_name : 'user_roles_edit'

    serializeData : ->
      tenant = App.request 'tenant:get'
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
      'click .m-user_roles-edit_form input[type="checkbox"]' : 'roleEdited'
      'ajax:complete .m-user_roles-edit_form' : 'roleChanged'


    roleEdited : (ev) ->
      $(ev.currentTarget).closest('.m-user_roles-edit_form').find('.option.specific input[type="radio"]').trigger('click')

    roleChanged : (data, response, xhr) ->
      result = $.parseJSON(response.responseText)
      @trigger 'role:changed', result


  class Admin.DatabaseView extends App.Dash.View
    dash_name : 'database'




