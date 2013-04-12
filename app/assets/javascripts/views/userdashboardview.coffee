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



  change_context : (target_context) ->
    
    user = @model
    data_uri = null

    @current_context = target_context

    switch target_context
      #when 'profile'
      #  data_uri = Routes.profile_path(user.id)
      #when 'preferences'
      #  data_uri = Routes.edit_profile_path(user.id)
      #when 'account_settings'
      #  data_uri = Routes.edit_profile_path(user.id)
      #when 'email_notifications'
      #  data_uri = Routes.edit_notifications_path(user.id)

      when 'app_settings'
        data_uri = Routes.application_settings_path()
      when 'moderate'
        data_uri = Routes.dashboard_moderate_path()
      when 'analyze'
        data_uri = Routes.analytics_path()
      when 'assess'
        data_uri = Routes.assessment_index_path()


    if !(target_context of @templates)
      @templates[target_context] = _.template( $("#tpl_dashboard_#{target_context}").html() )

    if data_uri
      # add loading icon
      #TODO: fetch data from server
      #TODO: don't fetch every time
      # remove loading icon
    else
      @change_context_finish({})


  change_context_finish : (params) ->
    @$content_area.html(
      @templates[@current_context]( $.extend({}, params, {
        is_self : @model.id == ConsiderIt.current_user.id        
        user : @model.attributes
        avatar : window.PaperClip.get_avatar_url(@model, 'original')
      }))
    )

    @$el.find('.m-dashboard_link').removeClass('current').filter("[data-target=#{@current_context}]").addClass('current')

    if @$el.is(':hidden')
      @$el.slideDown()

  events :
    'click .m-dashboard_link' : 'change_context_ev' 
    'click .edit_profile' : 'change_context_edit_profile'
    'click .m-dashboard-close' : 'close'
    'ajax:complete .m-dashboard-edit-user' : 'user_updated'

  user_updated : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.update_current_user(data.user.user)
    if @current_context
      @change_context @current_context

  change_context_edit_profile : () ->
    @change_context('edit_profile')

  change_context_ev : (ev) ->
    target_context = $(ev.currentTarget).data('target')
    @change_context(target_context)

  close : (ev) ->
    @$el.slideUp()

