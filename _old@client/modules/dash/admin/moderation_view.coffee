@ConsiderIt.module "Dash.Admin.Moderation", (Moderation, App, Backbone, Marionette, $, _) ->

  class Moderation.ModerationLayout extends App.Dash.View
    dash_name : 'moderate'

    regions :
      tabsRegion : '#moderation_tabs_region'
      moderationsRegion : '#moderation_content_region'

    events : 
      'click [action="launch-moderation-settings"]' : 'moderationSettingsRequested'

    moderationSettingsRequested : (ev) ->
      @trigger 'moderation:please_show_settings'


  class Moderation.ModerationTabView extends App.Views.ItemView
    template : '#tpl_moderate_tab'
    className : 'moderation_tab_view'
    selected : null

    serializeData : ->
      unmoderated = {}
      for mc in @options.classes_to_moderate
        unmoderated[mc] = _.size @options.moderations[mc].filter( (m) -> !m.get('status') || m.get('status') == 2)
      
      params = 
        classes_to_moderate : @options.classes_to_moderate
        unmoderated : unmoderated
      params

    onRender : ->
      if !@selected
        @selected = @$el.find('.moderation-tab:first').attr('class_name')

      @$el.find("[class_name='#{@selected}']").trigger('click')

    events : 
      'click .moderation-tab.inactive' : 'tabChanged'

    tabChanged : (ev) ->
      $target = $(ev.currentTarget)
      @selected = $target.attr('class_name')
      $target.siblings('.active').toggleClass('active inactive')
      $target.toggleClass('active inactive')

      @trigger 'tab:changed', @selected


  class Moderation.ModerationItemView extends App.Views.ItemView
    template : '#tpl_moderate_item_view'
    tagName : 'div'
    className : 'moderation_list_item_view'

    radioboxes : [
      ['account', 'moderate_points_mode', 'account_moderate_points_mode']
    ]

    radioBox : (model, attribute, selector) ->
      input = @$el.find("#{selector}_#{model.get(attribute)}")[0].checked = true


    serializeData : ->
      obj = @model.getRootObject()
      # switch @model.get 'moderatable_type'
      #   when 'Point'
      #     url = Routes.proposal_point_path obj.get('long_id'), obj.id
      #     anchor = 'View this Point'
      #   when 'Comment'
      #     url = Routes.proposal_point_path obj.get('proposal_id'), obj.get('root_id')
      #     anchor = 'View this Comment'
      #   when 'Proposal'
      #     url = Routes.proposal_path obj.id
      #     anchor = 'View this Proposal'

      _.extend {}, @model.attributes,
        user : if @model.user_id then App.request('user', @model.user_id) else null
        # anchor : anchor
        # url : url
        prior_moderation : @model.get 'status'
        evaluation_options : [
          {label: 'Fail', val: 0},
          {label: 'Quarantine', val: 2},
          {label: 'Pass', val: 1}
        ]

    onShow : ->
      if @model.isCompleted() || @model.quarantined()
        @radioBox @model, 'status', "#moderate_status_#{@model.get('moderatable_id')}"

      if @model.passed() || @model.failed()
        @$el.addClass 'moderated' 
      else if @model.quarantined()
        @$el.addClass 'quarantined' 
      else 
        @$el.addClass 'not_moderated'

    events : 
      'click .moderatable-evaluation-option input' : 'moderation'
      'ajax:complete form' : 'moderationSubmitted'
      'click .moderatable-email button' : 'emailRequest'

    moderation : (ev) ->
      @$el.find('input[type="submit"]').trigger('click')

    moderationSubmitted : (ev, response, options) ->
      response = $.parseJSON(response.responseText)

      if response.result == 'success'
        toastr.success 'Moderation saved'
      else
        toastr.error 'Failed to save'

      @trigger 'moderation:updated', response.moderation

    emailRequest : ->
      @trigger 'mod:emailRequest'


  class Moderation.ModerationListView extends App.Views.CompositeView
    template : '#tpl_moderate_list_view'
    itemView : Moderation.ModerationItemView
    itemViewContainer : '.moderate-content'
    className : 'moderation_compositeview'

    setFilter : (filter) ->
      @$el.find('.moderate-filter').removeClass('selected')
      @$el.find(".moderate-filter[action='#{filter}']").addClass('selected')
      @current_filter = filter
      @trigger 'filter:changed', filter

    events : 
      'click .moderate-filter' : 'toggleFilter'

    toggleFilter : (ev) ->
      $target = $(ev.currentTarget)

      if $target.attr('action') == 'all' && $target.is('.selected')
        return

      if $target.is('.selected')
        filter = 'all'
      else
        filter = $target.attr('action')

      @setFilter filter


  class Moderation.EmailDialogView extends App.Dash.EmailDialogView
    dialog: 
      title: 'Emailing author...'

  class Moderation.EditModerationSettingsView extends App.Dash.View
    dash_name : 'moderation_settings'

    dialog:
      title: 'Moderation settings'

    checkboxes : [
      ['account', 'enable_moderation', 'account_enable_moderation'],
    ]

    radioboxes : [
      ['account', 'moderate_points_mode', 'account_moderate_points_mode'],
      ['account', 'moderate_comments_mode', 'account_moderate_comments_mode'],
      ['account', 'moderate_proposals_mode', 'account_moderate_proposals_mode'],      
    ]

    serializeData : -> @model.attributes

    onShow : ->
      super
      @$el.find('.l-expandable-option').each (idx, $expandable) =>
        @toggleExpandable 
          currentTarget : $expandable


    events : 
      'ajax:complete .dashboard-edit-account' : 'moderationSettingsUpdated'
      'click .l-expandable-option input' : 'toggleExpandable'

    moderationSettingsUpdated : (data, response, xhr) ->
      result = $.parseJSON(response.responseText)
      @trigger 'moderation:settings_updated', result

    toggleExpandable : (ev) ->
      $expandable_option = $(ev.currentTarget).closest('.l-expandable-option')
      $expandable_area = $expandable_option.siblings('.l-expandable-area')

      if $expandable_option.find('input').is(':checked')
        $expandable_area.slideDown()
      else
        $expandable_area.slideUp()

