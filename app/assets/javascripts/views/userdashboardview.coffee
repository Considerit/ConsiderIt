class ConsiderIt.UserDashboardView extends Backbone.View

  template : _.template( $('#tpl_dashboard_container').html())

  initialize : (options) ->  
    @$dashboard_el = @$el.find('#m-dashboard')

    @templates = {}
    @admin_template_loaded = false
    @rendered = false


    ConsiderIt.vent.on 'route:Profile', (id) => 
      @model = ConsiderIt.users[id]
      #@render()
      @access_dashboard_profile(parseInt(id))

    ConsiderIt.vent.on 'route:EditProfile', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_edit_profile()
    ConsiderIt.vent.on 'route:AccountSettings', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_account_settings()
    ConsiderIt.vent.on 'route:EmailNotifications', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_email_notifications()


    ConsiderIt.vent.on 'route:AppSettings', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_app_settings()
    ConsiderIt.vent.on 'route:ManageProposals', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_manage_proposals()
    ConsiderIt.vent.on 'route:UserRoles', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_user_roles()

    ConsiderIt.vent.on 'route:Analyze', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_analyze()
    ConsiderIt.vent.on 'route:Moderate', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_moderate()
    ConsiderIt.vent.on 'route:Assess', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_assess()
    ConsiderIt.vent.on 'route:Database', => 
      @model = ConsiderIt.current_user if @model.id != ConsiderIt.current_user
      @access_dashboard_database()


    # Is there a better way than just doing this for all other routes?

    ConsiderIt.vent.on 'route:Root', => @close() if @$dashboard_el.is(':visible')
    ConsiderIt.vent.on 'route:Aggregate', => @close(false) if @$dashboard_el.is(':visible')
    ConsiderIt.vent.on 'route:Consider', => @close(false) if @$dashboard_el.is(':visible')
    ConsiderIt.vent.on 'route:PointDetails', => @close(false) if @$dashboard_el.is(':visible')    


    @listenTo ConsiderIt.router, 'user:signin', => 
      @model = ConsiderIt.current_user
      if @$dashboard_el.is(':visible') && @current_context
        @render()
        Backbone.history.loadUrl(Backbone.history.fragment)
    
    @listenTo ConsiderIt.router, 'user:signout', => @close() if @$dashboard_el.is(':visible') && @current_context

  render : ->
    visible = @$dashboard_el.is(':visible')

    @$dashboard_el.hide()
    is_self = @model.id == ConsiderIt.current_user.id
    @$dashboard_el.html(
      @template( $.extend( {}, {
        is_self : is_self
        user : @model.attributes
        avatar : window.PaperClip.get_avatar_url(@model, 'original')
        is_admin : is_self && ConsiderIt.roles.is_admin
        is_moderator : is_self && ConsiderIt.roles.is_moderator
        is_analyst : is_self && ConsiderIt.roles.is_analyst
        is_evaluator : is_self && ConsiderIt.roles.is_evaluator
        is_manager : is_self && ConsiderIt.roles.is_manager
      } ) )
    )

    @$content_area = @$dashboard_el.find('.m-dashboard-content')

    if !visible
      @$dashboard_el.fadeIn() 

      @hidden_els = $("[data-role='m-proposal']:visible")
      @hidden_els_visible_before = $("[data-role='m-proposal']:visible")

      #@hidden_els = $('#m-proposals-container, .l-content-wrap:visible:not(#m-dashboard)')

      @hidden_els.css('display', 'none')

    else
      @$dashboard_el.show()

    @rendered = true

    this

  access_dashboard_app_settings : -> 
    options = 
      data_uri : Routes.account_path()
      admin_template_needed: true
      data_callback : (data, params) => 
        ConsiderIt.current_tenant.set(data.account.account)
        params['account'] = ConsiderIt.current_tenant.attributes
        params
      render_callback : =>
        @_check_box(ConsiderIt.current_tenant, 'assessment_enabled', 'account_assessment_enabled')
        @_check_box(ConsiderIt.current_tenant, 'enable_moderation', 'account_enable_moderation')
        @_check_box(ConsiderIt.current_tenant, 'enable_position_statement', 'account_enable_position_statement')
        @_check_box(ConsiderIt.current_tenant, 'enable_user_conversations', 'account_enable_user_conversations')

        @$el.find('#account_header_text').autosize()
        @$el.find('#account_header_details_text').autosize()


    @_process_dashboard_context('app_settings', options)

  access_dashboard_manage_proposals : -> 
    options = 
      admin_template_needed: true
      params : { 
        active_proposals: ConsiderIt.all_proposals.where {active: true}
        inactive_proposals: ConsiderIt.all_proposals.where {active: false}
      }
    @_process_dashboard_context('manage_proposals', options)

  access_dashboard_user_roles : -> 
    options = 
      data_uri : Routes.manage_roles_path()
      admin_template_needed: true            
      data_callback : (data, params) =>
        @users_by_roles_mask = new Backbone.Collection( (new ConsiderIt.User(user.user) for user in data.users_by_roles_mask)  )
        _.extend params, { users_by_roles_mask: @users_by_roles_mask }

    @_process_dashboard_context('user_roles', options)

  access_dashboard_analyze : -> 
    options = 
      data_uri : Routes.analytics_path()
      admin_template_needed: true            
      view_class: -> ConsiderIt.UserDashboardViewAnalyze
    @_process_dashboard_context('analyze', options)
  
  access_dashboard_moderate : -> 
    options = 
      data_uri : Routes.dashboard_moderate_path()
      admin_template_needed: true            
      view_class: -> ConsiderIt.Moderatable.ModerationView
    @_process_dashboard_context('moderate', options)

  access_dashboard_assess : -> 
    options = 
      data_uri : Routes.assessment_index_path()
      admin_template_needed: true    
      view_class: -> ConsiderIt.Assessable.AssessmentsView
        
    @_process_dashboard_context('assess', options)

  access_dashboard_database : -> 
    @_process_dashboard_context('database', {admin_template_needed: true})

  access_dashboard_profile : (user_id) -> 
    options = 
      data_uri : Routes.profile_path(user_id)
      params: 
        is_self : user_id == ConsiderIt.current_user.id
        user : ConsiderIt.users[user_id].attributes
        avatar : window.PaperClip.get_avatar_url(ConsiderIt.users[user_id], 'original')
      data_callback : (data, params) =>
        _.extend params, { tile_size: Math.min 50, ConsiderIt.utils.get_tile_size(400, 42, _.keys(data.influenced_users).length) }

    @_process_dashboard_context('profile', options)

  access_dashboard_edit_profile : -> @_process_dashboard_context('edit_profile', {params: {user : @model.attributes, avatar : window.PaperClip.get_avatar_url(@model, 'original')}})
  access_dashboard_account_settings : -> @_process_dashboard_context('account_settings', {params: {user : @model.attributes}})
  access_dashboard_email_notifications : -> 
    user = if ConsiderIt.current_user.is_logged_in() then ConsiderIt.current_user else ConsiderIt.limited_user
    options = 
      data_uri : Routes.followable_index_path()
      data_params : {user_id : if user? then user.id else null}
      view_class: -> ConsiderIt.UserDashboardViewNotifications
    @_process_dashboard_context('email_notifications', options)

  _check_box : (model, attribute, selector, condition) ->
    if condition || (!condition? && model.get(attribute))
      input = document.getElementById(selector).checked = true

  _process_dashboard_context : (new_context, {params, admin_template_needed, view_class, data_uri, render_callback, data_callback, data_params}) ->  
    admin_template_needed ?= false
    params ?= {}
    data_params ?= {}
    load_admin_template = admin_template_needed && !@admin_template_loaded
    data_uri = Routes.admin_template_path() if !data_uri && load_admin_template

    if data_uri
      qry_params = if load_admin_template then _.extend(data_params, {admin_template_needed: true}) else data_params
      $.get data_uri, qry_params, (data, status, xhr) => 
        if data.result == 'failed'
          @change_context(new_context, _.extend(data, {unauthorized: true}))
        else
          if load_admin_template
            $('head').append(data.admin_template)
            @admin_template_loaded = true
          params = _.extend data, params
          params = data_callback(data, params) if data_callback
          @change_context(new_context, params, view_class)
          render_callback() if render_callback
    else
      @change_context(new_context, params, view_class)
      render_callback() if render_callback

  change_context : (new_context, params, view_class) ->
    previous_context = @current_context
    @current_context = new_context

    @render() #if !@rendered

    if !view_class

      tpl = if 'unauthorized' of params && params['unauthorized'] then 'unauthorized' else @current_context

      if !(tpl of @templates)
        @templates[tpl] = _.template( $("#tpl_dashboard_#{tpl}").html() )

      @$content_area.html(
        @templates[tpl](params)
      )
    else
      cls = view_class()
      @managing_dashboard_content_view = new cls({el: @$content_area, data: params })
      @managing_dashboard_content_view.render()

    @$dashboard_el.find('.m-dashboard_link').removeClass('current').filter("[data-target=#{@current_context}]").addClass('current')

    if 'callback' of params
      params[callback]()


    @$content_area.removeClass("m-dashboard-#{previous_context}")
    @$content_area.addClass("m-dashboard-#{@current_context}")

  events :
    #'click .m-dashboard_link' : 'change_context_ev' 
    #'click [data-target="close_user_dashboard"]' : 'close'

    'click .m-dashboard-profile-activity-summary' : 'activity_toggled'

    'ajax:complete .m-dashboard-edit-user' : 'user_updated'
    'ajax:complete .m-dashboard-edit-account' : 'account_updated'

    'click .m-user_roles-invoke_role_change' : 'edit_role'
    'click .m-user_roles-edit_form input[type="checkbox"]' : 'role_edited'
    'click .m-user_roles-edit_form .cancel' : 'edit_role_close'
    'ajax:complete .m-user_roles-edit_form' : 'role_changed'

    'click .m-dashboard-profile-activity-action a' : 'close'


    'click [data-target="profile"]' : 'navigate_to_profile'
    'click [data-target="edit_profile"]' : 'navigate_to_edit_profile'
    'click [data-target="account_settings"]' : 'navigate_to_account_settings'
    'click [data-target="email_notifications"]' : 'navigate_to_email_notifications'
    'click [data-target="app_settings"]' : 'navigate_to_app_settings'
    'click [data-target="user_roles"]' : 'navigate_to_user_roles'
    'click [data-target="manage_proposals"]' : 'navigate_to_manage_proposals'
    'click [data-target="moderate"]' : 'navigate_to_moderate'
    'click [data-target="assess"]' : 'navigate_to_assess'
    'click [data-target="analyze"]' : 'navigate_to_analyze'
    'click [data-target="database"]' : 'navigate_to_database'

    'click [data-target="user_profile_page"]' : 'view_user_profile'


  navigate_to_profile : -> ConsiderIt.router.navigate Routes.profile_path( ConsiderIt.current_user.id ), {trigger: true}
  navigate_to_edit_profile : -> ConsiderIt.router.navigate Routes.edit_profile_path( ConsiderIt.current_user.id ), {trigger: true}
  navigate_to_account_settings : -> ConsiderIt.router.navigate Routes.edit_account_path( ConsiderIt.current_user.id ), {trigger: true}
  navigate_to_email_notifications : -> ConsiderIt.router.navigate Routes.edit_notifications_path( ConsiderIt.current_user.id ), {trigger: true}
  navigate_to_app_settings : -> ConsiderIt.router.navigate 'dashboard/application', {trigger: true}
  navigate_to_user_roles : -> ConsiderIt.router.navigate Routes.manage_roles_path(), {trigger: true}
  navigate_to_manage_proposals : -> ConsiderIt.router.navigate 'dashboard/proposals', {trigger: true}
  navigate_to_moderate : -> ConsiderIt.router.navigate Routes.dashboard_moderate_path(), {trigger: true}
  navigate_to_assess : -> ConsiderIt.router.navigate Routes.assessment_index_path(), {trigger: true}
  navigate_to_analyze : -> ConsiderIt.router.navigate Routes.analytics_path(), {trigger: true}
  navigate_to_database : -> ConsiderIt.router.navigate 'dashboard/data', {trigger: true}

  # handles user profile access for anyone throughout the app  
  view_user_profile : (ev) -> ConsiderIt.router.navigate(Routes.profile_path($(ev.currentTarget).data('id')), {trigger: true})


  activity_toggled : (ev) ->
    already_selected = $(ev.currentTarget).is('.selected')
    @$el.find('.m-dashboard-profile-activity-block').hide()
    @$el.find('.m-dashboard-profile-activity-summary').removeClass('selected')

    if !already_selected
      target = $(ev.currentTarget).data('target')    
      @$el.find("[data-target='#{target}-details']").slideDown()
      $(ev.currentTarget).addClass('selected')

  user_updated : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.update_current_user(data.user)
    @access_dashboard_edit_profile()
    #@render() if @current_context

  account_updated : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.current_tenant.set(data.account)


    $('.t-header-text').text(ConsiderIt.current_tenant.get('header_text'))
    $('.t-header-text-details').text(ConsiderIt.current_tenant.get('header_details_text'))

    #@$el.find('.m-dashboard-edit-account .save_block').append('<div>Account updated</div>')

    @$content_area.find('.save_block').append('<div class="flash_notice">Account updated</div>').delay(2000).fadeOut 'fast', =>
      @access_dashboard_app_settings()  


  # change_context_ev : (ev) ->
  #   target_context = $(ev.currentTarget).data('target')
  #   @change_context(target_context)

  edit_role : (ev) ->
    if !('tpl_dashboard_user_roles_edit' of @templates)
      @templates['tpl_dashboard_user_roles_edit'] = _.template( $('#tpl_dashboard_user_roles_edit').html() )

    user = @users_by_roles_mask.get($(ev.currentTarget).data('id'))
    
    @$dashboard_el.append @templates['tpl_dashboard_user_roles_edit']({ user: user })
    $dialog_window = @$dashboard_el.children('.l-dialog-detachable:last')
    $dialog_window.data('parent', $(ev.currentTarget))

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
    $(ev.currentTarget).closest('.m-user_roles-edit_form').find('.option.specific input[type="radio"]').trigger('click')

  role_changed : (data, response, xhr) ->
    result = $.parseJSON(response.responseText)

    $dialog_window = @$dashboard_el.children('.l-dialog-detachable:last')
    $field = $dialog_window.data('parent').find('.m-user-roles-list')
    role = result.role_list

    $field.text( role )

    $dialog_window.detach().appendTo($dialog_window.data('parent')).hide()


  close : (show_everything) ->
    show_everything ?= true

    @$dashboard_el.hide()

    if show_everything then @hidden_els.css('display', '') else @hidden_els_visible_before.css('display', '')

    @current_context = null

    if @managing_dashboard_content_view
      @managing_dashboard_content_view.undelegateEvents()


    #window.history.go(-1)    

