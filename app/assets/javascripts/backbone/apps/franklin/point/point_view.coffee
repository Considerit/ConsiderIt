@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->
  
  class Point.PointHeaderView extends App.Views.ItemView
    template : '#tpl_point_view_header'
    tagName : 'span'

    serializeData : ->
      assessment = @model.getAssessment()
      tenant = App.request 'tenant:get'
      has_assessment = tenant.get('assessment_enabled') && assessment && assessment.get('complete')

      params = _.extend {}, 
        user : @model.getUser().attributes
        hide_name : @model.get 'hide_name'
        has_assessment : has_assessment

      if has_assessment
        _.extend params, 
          assessment : assessment
          verdict : assessment.getVerdict()
          claims : assessment.getClaims() 
      params

    onRender : ->
      #TODO: in previous scheme, this change was intended to trigger render on point details close
      @listenTo @model, 'change', @render

    events : 
      'mouseover .m-point-assessment-indicator-region' : 'showVerdictTooltip'

    showVerdictTooltip : (ev) ->

      $target = $(ev.currentTarget)
      assessment = @model.getAssessment()
      verdict = assessment.getVerdict()

      template = _.template($('#tpl_verdict_tooltip').html())


      content = switch verdict.id
        when 1
          "Warning: may contain unsubstantiated claims."
        when 2
          "Contains some unverified claims."
        when 3
          "Makes accurate claims."          
        else
          null

      html = template
        content : content


      if content
        $target.tooltipster
          content: html
          offsetY: 25
          delay: 200
          title : 'This point has been fact-checked'

        $target.tooltipster 'show'


  class Point.PointBodyView extends App.Views.ItemView
    template : '#tpl_point_view_body'

    onRender : ->
      #TODO: in previous scheme, this change was intended to trigger render on point details close
      @listenTo @model, 'change', @render

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        adjusted_nutshell : @model.adjusted_nutshell()
        user : @model.getUser().attributes
        proposal : @model.getProposal().attributes
        actions : @options.actions
      
      params

    onRender : ->
      @stickit()

    bindings : 
      '.m-point-read-more' : 
        observe : 'comment_count'
        onGet : -> 
          if @model.get('comment_count') == 1 then "1 comment" else "#{@model.get('comment_count')} comments"


  class Point.PointView extends App.Views.Layout
    actions : []

    tagName : 'li'
    template : '#tpl_point_view'

    regions :
      headerRegion : '.m-point-header-region'
      bodyRegion : '.m-point-wrap'
      expansionRegion : '.m-point-expansion-region'

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        actions : @actions

      params

    @events : 
      'click' : 'pointClicked'

    pointClicked : (ev) ->
      @trigger 'point:clicked'
      ev.stopPropagation()

  class Point.PeerPointView extends Point.PointView
    actions : ['include']

    events : _.extend @events,
      'click [data-target="point-include"]' : 'includePoint'

    includePoint : (ev) ->
      @trigger 'point:include'
      ev.stopPropagation()

  class Point.PositionPointView extends Point.PointView
    actions : ['remove']

    events : _.extend @events,
      'click [data-target="point-remove"]' : 'removePoint'

    removePoint : (ev) ->
      @trigger 'point:remove'
      ev.stopPropagation()

  class Point.AggregatePointView extends Point.PointView

    events : _.extend @events,
      'mouseenter' : 'highlightIncluders'
      'mouseleave' : 'unhighlightIncluders'

    highlightIncluders : ->
      @trigger 'point:highlight_includers'

    unhighlightIncluders : ->
      @trigger 'point:unhighlight_includers'

  class Point.ExpandedView extends App.Views.Layout
    template : '#tpl_point_expanded'
    regions :
      followRegion : '.m-point-follow-region'
      assessmentRegion : '.m-point-assessment-region'
      discussionRegion : '.m-point-discussion'

    onRender : ->
      App.vent.trigger 'point:expanded'


    onShow : ->
      # when clicking outside of point, close it      
      $(document).on 'click.m-point-details', (ev)  => 
        is_not_clicking_this_point = ($(ev.target).closest('.m-point-expanded').length == 0 || $(ev.target).closest('.m-point-expanded').data('id') != @model.id)
        dialog_not_open = $('#l-dialog-detachable').length == 0
        if is_not_clicking_this_point && $(ev.target).closest('.editable-buttons').length == 0 && dialog_not_open
          is_click_within_a_point = $(ev.target).closest('[data-role="m-point"]').length > 0
          is_clicking_nav = $(ev.target).closest('.l-navigate-wrap').length > 0
          @closeDetails(  !is_click_within_a_point && !is_clicking_nav ) 


      $(document).on 'keyup.m-point-details', (ev) => 
        dialog_not_open = $('#l-dialog-detachable').length == 0
        @closeDetails() if ev.keyCode == 27 && dialog_not_open

      current_user = App.request 'user:current'
      if current_user.id == @model.get('user_id') #|| ConsiderIt.request('user:current').isAdmin()
        @$el.find('.m-point-nutshell ').editable
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @model.get('long_id'), @model.id
          type: 'textarea'
          name: 'nutshell'
          success : (response, new_value) => @model.set('nutshell', new_value)

        @$el.find('.m-point-details-description ').editable
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @model.get('long_id'), @model.id
          type: 'textarea'
          name: 'text'
          success : (response, new_value) => @model.set('text', new_value)


    closeDetails : (go_back) ->
      go_back ?= true
      @trigger 'details:close', go_back


  class Point.FollowView extends App.Views.ItemView
    template : '#tpl_point_follow'

    serializeData : ->
      current_user = App.request 'user:current'
      params = _.extend {}, @model.attributes,
        already_follows : current_user.isFollowing 'Point', @model.id
        current_user_id : current_user.id
      params

    events : 
      'click .m-point-follow' : 'toggleFollow'

    toggleFollow : (ev) ->
      @trigger 'point:follow'

