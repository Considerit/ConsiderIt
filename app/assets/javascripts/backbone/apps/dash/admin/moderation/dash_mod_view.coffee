@ConsiderIt.module "Dash.Admin.Moderation", (Moderation, App, Backbone, Marionette, $, _) ->

  class Moderation.ModerationLayout extends App.Dash.View
    dash_name : 'moderate'
    regions :
      tabsRegion : '#tabs'
      moderationsRegion : '#moderations'

    onShow : ->
      super
      if @$el.find('#hide_moderated').is(':checked')
        @toggleModerated()

    events : 
      'click #hide_moderated' : 'toggleModerated'

    toggleModerated : ->
      @$el.toggleClass('hide_moderated')


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
      @$el.find('.m-moderation-tab:first').trigger('click')

    events : 
      'click .m-moderation-tab.inactive' : 'tabChanged'

    tabChanged : (ev) ->
      $target = $(ev.currentTarget)
      cls = $target.attr('class_name')
      $target.siblings('.active').toggleClass('active inactive')
      $target.toggleClass('active inactive')

      @trigger 'tab:changed', cls


  class Moderation.ModerationItemView extends App.Views.ItemView
    template : '#tpl_moderate_item_view'
    tagName : 'div'
    className : 'm-moderate-row'

    serializeData : ->

      if @model.moderatable_type == 'Point'
        url = Routes.proposal_point_path obj.proposal_id, obj.root_id
        anchor = 'View this Point'
      else if @model.moderatable_type == 'Comment'
        url = Routes.proposal_point_path obj.proposal_id, obj.root_id
        anchor = 'View this Comment'
      else if @model.moderatable_type == 'Proposal'
        url = Routes.proposal_path obj.proposal_id
        anchor = 'View this Proposal'

      _.extend {}, @model.attributes,
        user : if @model.user_id then ConsiderIt.users[@model.user_id] else null
        anchor : anchor
        url : url
        prior_moderation : @model.get 'status'


    onShow : ->
      status = @model.get('status')

      if status? || status == 0
        if status == 0
          @$el.find('.fail').addClass 'selected'
          @$el.addClass 'failed'

        else if status == 1
          @$el.find('.pass').addClass 'selected'
          @$el.addClass 'passed'

        @$el.addClass 'moderated' 
      else 
        @$el.addClass 'not_moderated'


    events : 
      'click .m-moderate-row button' : 'moderation'

    moderation : (ev) ->
      $target = $(ev.currentTarget)
      $target.addClass('selected')
      $target.siblings('button').removeClass('selected')
      $target.parents('.m-moderate-row').removeClass('passed failed').addClass($target.hasClass('pass') ? 'passed' : 'failed')
      $target.parents('form:first, .m-moderate-row').removeClass('not_moderated').addClass('moderated')
      $target.parents('form:first').find('#moderate_status').val($target.hasClass('pass') ? 1 : 0)
      $target.parents('form:first').find('input[type="submit"]').trigger('click')


  class Moderation.ModerationListView extends App.Views.CollectionView
    tagName : "div"
    className : 'm-moderate-content'
    itemView : Moderation.ModerationItemView



