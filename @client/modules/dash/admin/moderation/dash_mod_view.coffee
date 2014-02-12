@ConsiderIt.module "Dash.Admin.Moderation", (Moderation, App, Backbone, Marionette, $, _) ->

  class Moderation.ModerationLayout extends App.Dash.View
    dash_name : 'moderate'
    regions :
      tabsRegion : '#tabs'
      moderationsRegion : '#moderations'


  class Moderation.ModerationTabView extends App.Views.ItemView
    template : '#tpl_moderate_tab'

    serializeData : ->
      unmoderated = {}
      for mc in @options.classes_to_moderate
        unmoderated[mc] = _.size(@options.moderations[mc].where({status: null})) 
      
      params = 
        classes_to_moderate : @options.classes_to_moderate
        unmoderated : unmoderated
      params

    onShow : ->
      @$el.find('.moderation-tab:first').trigger('click')

    events : 
      'click .moderation-tab.inactive' : 'tabChanged'

    tabChanged : (ev) ->
      $target = $(ev.currentTarget)
      cls = $target.attr('class_name')
      $target.siblings('.active').toggleClass('active inactive')
      $target.toggleClass('active inactive')

      @trigger 'tab:changed', cls


  class Moderation.ModerationItemView extends App.Views.ItemView
    template : '#tpl_moderate_item_view'
    tagName : 'div'
    className : 'moderate-row'

    radioboxes : [
      ['account', 'moderate_points_mode', 'account_moderate_points_mode']
    ]

    radioBox : (model, attribute, selector) ->
      input = @$el.find("#{selector}_#{model.get(attribute)}")[0].checked = true


    serializeData : ->
      obj = @model.getRootObject()
      switch @model.get 'moderatable_type'
        when 'Point'
          url = Routes.proposal_point_path obj.get('long_id'), obj.id
          anchor = 'View this Point'
        when 'Comment'
          url = Routes.proposal_point_path obj.get('proposal_id'), obj.get('root_id')
          anchor = 'View this Comment'
        when 'Proposal'
          url = Routes.proposal_path obj.id
          anchor = 'View this Proposal'

      _.extend {}, @model.attributes,
        user : if @model.user_id then App.request('user', @model.user_id) else null
        anchor : anchor
        url : url
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

      @trigger 'moderation:updated', response.moderation.moderation

    emailRequest : ->
      @trigger 'mod:emailRequest'


  class Moderation.ModerationListView extends App.Views.CompositeView
    template : '#tpl_moderate_list_view'
    itemView : Moderation.ModerationItemView
    itemViewContainer : '.moderate-content'

    setFilter : (filter) ->
      @$el.find('.moderate-filter').removeClass('selected')
      @$el.find(".moderate-filter[action='#{filter}']").addClass('selected')
      @current_filter = filter
      @trigger 'filter:changed', filter

    events : 
      'click .moderate-filter' : 'toggleFilter'

    toggleFilter : (ev) ->
      $target = $(ev.currentTarget)

      if $target.data('target') == 'all' && $target.is('.selected')
        return

      if $target.is('.selected')
        filter = 'all'
      else
        filter = $target.data('target')

      @setFilter filter


  class Moderation.EmailDialogView extends App.Dash.EmailDialogView
    dialog: 
      title: 'Emailing author...'
