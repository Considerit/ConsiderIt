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
      } ) )
    )

    @$content_area = @$el.find('.m-dashboard-content')

    if @initial_context
      @change_context(@initial_context)
      @initial_context = null

    this

  _check_box : (model, attribute, selector) ->
    if model.get(attribute)
      input = document.getElementById(selector).checked = true

  change_context : (target_context) ->
    
    user = @model
    data_uri = null

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

      when 'moderate'
        data_uri = Routes.dashboard_moderate_path()
        $.get data_uri, {admin_template_needed : !admin_template_loaded}, (data) =>
          if !admin_template_loaded
            $('head').append(data.admin_template)

          @change_context_finish(data)

      when 'analyze'
        data_uri = Routes.analytics_path()
      when 'assess'
        data_uri = Routes.assessment_index_path()
      else
        @change_context_finish({})

      # add loading icon
      #TODO: fetch data from server
      #TODO: don't fetch every time
      # remove loading icon


  change_context_finish : (params) ->
    if !(@current_context of @templates)
      @templates[@current_context] = _.template( $("#tpl_dashboard_#{@current_context}").html() )

    params = $.extend({}, params, {
      is_self : @model.id == ConsiderIt.current_user.id        
      user : @model.attributes
      avatar : window.PaperClip.get_avatar_url(@model, 'original')
    })

    console.log params
    @$content_area.html(
      @templates[@current_context](params)
    )

    @$el.find('.m-dashboard_link').removeClass('current').filter("[data-target=#{@current_context}]").addClass('current')

    if @$el.is(':hidden')
      @$el.slideDown()

  events :
    'click .m-dashboard_link' : 'change_context_ev' 
    'click .edit_profile' : 'change_context_edit_profile'
    'click .m-dashboard-close' : 'close'
    'ajax:complete .m-dashboard-edit-user' : 'user_updated'
    'ajax:complete .m-dashboard-edit-account' : 'account_updated'

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

  close : (ev) ->
    @$el.slideUp()

