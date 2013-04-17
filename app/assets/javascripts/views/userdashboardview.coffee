class ConsiderIt.UserDashboardView extends Backbone.View

  template : _.template( $('#tpl_dashboard_container').html())

  initialize : (options) ->  
    @initial_context = options.initial_context
    @templates = {}

  render : ->
    @$el.hide()

    @$el.html(
      @template( $.extend( {}, {
        is_self : @model.id == ConsiderIt.current_user.id
        user : @model.attributes
        is_admin : ConsiderIt.roles.is_admin
        is_moderator : ConsiderIt.roles.is_moderator
        is_analyst : ConsiderIt.roles.is_analyst
        is_evaluator : ConsiderIt.roles.is_evaluator
        is_manager : ConsiderIt.roles.is_manager
      } ) )
    )

    @$content_area = @$el.find('.m-dashboard-content')

    if @initial_context
      @change_context(@initial_context)
      @initial_context = null

    this

  _check_box : (model, attribute, selector, condition) ->
    if condition || (!condition? && model.get(attribute))
      input = document.getElementById(selector).checked = true

  change_context : (target_context) ->
    
    user = @model
    data_uri = null

    @previous_context = @current_context
    @current_context = target_context

    admin_template_loaded = $('#c-admin-template-loaded').length > 0
    switch target_context

      when 'app_settings'
        data_uri = Routes.account_path()
        $.get data_uri, {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)
          ConsiderIt.current_tenant.set(data.account.account)
          @change_context_finish({ account : ConsiderIt.current_tenant.attributes })
          @_check_box(ConsiderIt.current_tenant, 'enable_moderation', 'account_enable_moderation')
          @_check_box(ConsiderIt.current_tenant, 'enable_position_statement', 'account_enable_position_statement')

      when 'manage_proposals'
        active = []
        inactive = []
        data_uri = Routes.account_path() #TODO: actually fetch the proposals that are not currently loaded
        $.get data_uri, {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          for proposal in _.values(ConsiderIt.proposals)
            if proposal.model.get('active')
              active.push proposal.model
            else
              inactive.push proposal.model

          @change_context_finish({ active_proposals: active, inactive_proposals: inactive })

      when 'user_roles'
        $.get Routes.manage_roles_path(), {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          @users_by_roles_mask = new Backbone.Collection()
          @users_by_roles_mask.set((new ConsiderIt.User(user.user) for user in data.users_by_roles_mask) )

          @change_context_finish(_.extend(data, {users_by_roles_mask: @users_by_roles_mask}) )

      when 'analyze'
        data_uri = Routes.analytics_path()
        $.get data_uri, {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          @change_context_finish(data, ConsiderIt.UserDashboardViewAnalyze)

      when 'moderate'
        $.get Routes.dashboard_moderate_path(), {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          @change_context_finish(data, ConsiderIt.Moderatable.ModerationView)

      when 'assess'
        data_uri = Routes.assessment_index_path()
        $.get data_uri, {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          @change_context_finish(data, ConsiderIt.Assessable.AssessmentsView)

      when 'database'
        data_uri = Routes.account_path()
        $.get data_uri, {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          @change_context_finish({})

      else
        @change_context_finish({})

      # add loading icon
      #TODO: don't fetch every time
      # remove loading icon


  change_context_finish : (params, view_class) ->
    if !view_class
      if !(@current_context of @templates)
        @templates[@current_context] = _.template( $("#tpl_dashboard_#{@current_context}").html() )

      params = $.extend({}, params, {
        is_self : @model.id == ConsiderIt.current_user.id        
        user : @model.attributes
        avatar : window.PaperClip.get_avatar_url(@model, 'original')
      })

      @$content_area.html(
        @templates[@current_context](params)
      )
    else
      @managing_dashboard_content_view = new view_class({el: @$content_area, data: params })
      @managing_dashboard_content_view.render()

    @$el.find('.m-dashboard_link').removeClass('current').filter("[data-target=#{@current_context}]").addClass('current')

    if @$el.is(':hidden')
      @$el.slideDown()

    @$content_area.removeClass("m-dashboard-#{@previous_context}")
    @$content_area.addClass("m-dashboard-#{@current_context}")

  events :
    'click .m-dashboard_link' : 'change_context_ev' 
    'click .edit_profile' : 'change_context_edit_profile'
    'click .m-dashboard-close' : 'close'

    'ajax:complete .m-dashboard-edit-user' : 'user_updated'
    'ajax:complete .m-dashboard-edit-account' : 'account_updated'

    'click .m-user_roles-invoke_role_change' : 'edit_role'
    'click .m-user_roles-edit_form input[type="checkbox"]' : 'role_edited'
    'click .m-user_roles-edit_form .cancel' : 'edit_role_close'
    'ajax:complete .m-user_roles-edit_form' : 'role_changed'
       
  user_updated : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.update_current_user(data.user.user)
    if @current_context
      @change_context @current_context

  account_updated : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.current_tenant.set(data.account)
    if @current_context
      @change_context @current_context

  change_context_edit_profile : () ->
    @change_context('edit_profile')

  change_context_ev : (ev) ->
    target_context = $(ev.currentTarget).data('target')
    @change_context(target_context)

  edit_role : (ev) ->
    if !('tpl_dashboard_user_roles_edit' of @templates)
      @templates['tpl_dashboard_user_roles_edit'] = _.template( $('#tpl_dashboard_user_roles_edit').html() )

    user = @users_by_roles_mask.get($(ev.currentTarget).data('id'))
    
    @$el.append @templates['tpl_dashboard_user_roles_edit']({ user: user })

    @_check_box user, null, 'user_role_admin', user.has_role('admin') || user.has_role('superadmin')
    @_check_box user, null, 'user_role_specific', !user.has_role('admin') && user.roles_mask > 0
    @_check_box user, null, 'user_manager', user.has_role('manager')
    @_check_box user, null, 'user_moderator', user.has_role('moderator')
    @_check_box user, null, 'user_evaluator', user.has_role('evaluator')    
    @_check_box user, null, 'user_analyst', user.has_role('analyst')
    @_check_box user, null, 'user_role_user', user.roles_mask == 0

  edit_role_close : (ev) ->
    $('.m-user_roles-edit_form').remove()

  role_edited : (ev) ->
    $(ev.currentTarget).parents('.m-user_roles-edit_form').find('.option.specific input[type="radio"]').trigger('click')

  role_changed : (data, response, xhr) ->
    $dialog_window = $(this).parents('.detachable')
    $field = $dialog_window.data('parent').children('a').find('span')
    role = response.role_list

    $field.text( role )

    $dialog_window.detach().appendTo($dialog_window.data('parent')).hide()


  close : () ->
    @$el.slideUp()
    if @managing_dashboard_content_view
      @managing_dashboard_content_view.remove()
    

