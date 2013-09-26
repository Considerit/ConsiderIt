@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->

  class Assessment.AssessmentListItem extends App.Views.ItemView
    template : '#tpl_assess_list_item'
    tagName: 'tr'
    className : 'assessment_row'

    serializeData : ->
      params = _.extend {}, @model.attributes,
        root_object : @model.getRoot().attributes
        claimed : @model.get('user_id') > 0
        status : @model.status()

      current_user = App.request 'user:current'
      if params.claimed
        params = _.extend params, 
          claimed_by_logged_in_user : current_user.id == @model.get('user_id')
          claimed_by : App.request('user', @model.get('user_id')).get('name')
      else
        params = _.extend params,
          current_user : current_user.id

      params

    onRender : ->
      status = if @model.get('complete') then "completed" else if @model.get('reviewable') then 'reviewable' else 'incomplete'
      @$el.addClass @model.status()

    events : 
      'click .take_responsibility' : 'takeResponsibility'

    takeResponsibility : (ev) ->
      @trigger 'assessment:claim'


  class Assessment.AssessmentListView extends App.Views.CompositeView
    template : '#tpl_assess_list'
    itemView : Assessment.AssessmentListItem
    itemViewContainer : 'tbody'

    events : 
      'click #hide_completed' : 'toggleCompleted'

    toggleCompleted : (ev) ->
      @$el.find('.assessment_block').toggleClass('hide_completed')

    onShow : ->
      # @$el.find('.table').fixedHeaderTable({ footer: false, cloneHeadToFoot: false, fixedColumn: false })
      hm = @$el.find('#hide_completed')
      if hm.is(':checked')
        hm.trigger('click')

  class Assessment.AssessmentListLayout extends App.Dash.View
    dash_name : 'assess'

    regions : 
      listRegion : '#assess'