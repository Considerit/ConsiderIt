@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->
  
  class Point.PointView extends App.Views.Layout
    actions : []

    tagName : 'li'
    template : '#tpl_point_view'

    regions :
      headerRegion : '.point-header-region'
      bodyRegion : '.point-wrap-region'
      expansionRegion : '.point-expansion-region'

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        actions : @actions

      params

    @events : 
      'click .point-close' : 'closePoint'
      'click' : 'pointClicked'

    pointClicked : (ev) ->
      pass_through = @$el.parents('[data-state="points-collapsed"]').length > 0
      _.each App.request('shared:targets'), (target) ->
        pass_through ||= $(ev.target).is("[data-target='#{target}']")

      if !pass_through
        @trigger 'point:clicked'
        ev.stopPropagation()

    closePoint : (ev) ->
      # only for closing expanded points
      $('#l-wrap').trigger 'click'
      ev.stopPropagation()

  class Point.PeerPointView extends Point.PointView
    actions : ['include']

    events : _.extend @events,
      'click [data-target="point-include"]' : 'includePoint'
      'mouseenter' : 'highlightIncluders'
      'mouseleave' : 'unhighlightIncluders'
      
    includePoint : (ev) ->
      @trigger 'point:include'
      ev.stopPropagation()

    highlightIncluders : ->
      @trigger 'point:highlight_includers'

    unhighlightIncluders : ->
      @trigger 'point:unhighlight_includers'

    disableDrag : ->
      try
        @$el.find('.point-wrap').draggable 'destroy'
      catch e
        # get here when nav to results page before draggable created

    enableDrag : ->
      @$el.find('.point-wrap').draggable
        revert: "invalid"


  class Point.PositionPointView extends Point.PointView
    actions : ['remove']

    events : _.extend @events,
      'click [data-target="point-remove"]' : 'removePoint'

    removePoint : (ev) ->
      @trigger 'point:remove'
      ev.stopPropagation()


  class Point.ExpandedView extends App.Views.Layout
    template : '#tpl_point_expanded'
    regions :
      followRegion : '.point-follow-region'
      assessmentRegion : '.point-assessment-region'
      discussionRegion : '.point-discussion'

    serializeData : ->
      @model.attributes

    onRender : ->
      App.vent.trigger 'point:expanded'

    onShow : ->
      # when clicking outside of point, close it      
      $(document).on 'click.point-details', (ev)  => 
        is_not_clicking_this_point = ($(ev.target).closest('.point-expanded').length == 0 || $(ev.target).closest('.point-expanded').data('id') != @model.id)
        dialog_not_open = $('.l-dialog-detachable').length == 0
        if is_not_clicking_this_point && $(ev.target).closest('.editable-buttons').length == 0 && dialog_not_open
          is_click_within_a_point = $(ev.target).closest('[data-role="point"]').length > 0
          is_clicking_nav = $(ev.target).closest('.l-navigate-wrap').length > 0
          @closeDetails( !is_click_within_a_point && !is_clicking_nav ) 

      $(document).on 'keyup.point-details', (ev) => 
        dialog_not_open = $('.l-dialog-detachable').length == 0
        @closeDetails() if ev.keyCode == 27 && dialog_not_open

      current_user = App.request 'user:current'

      #needs to be managed by layout
      if current_user.canEditPoint @model 
        @trigger 'make_fields_editable'


    closeDetails : (go_back) ->
      go_back ?= true
      @trigger 'details:close', go_back

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
      'mouseover .point-assessment-indicator-region' : 'showVerdictTooltip'

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

    serializeData : ->
      params = _.extend {}, @model.attributes, 
        adjusted_nutshell : @model.adjusted_nutshell()
        user : @model.getUser().attributes
        proposal : @model.getProposal().attributes
        actions : @options.actions
      
      params

    onShow : ->
      @listenTo @model, 'change', @render      

    onRender : ->
      @stickit()

      current_user = App.request 'user:current'
      if @$el.parents('.point-expanded').length > 0 && current_user.canEditPoint @model 
        @makeEditable()

    bindings : 
      '.point-read-more' : 
        observe : 'comment_count'
        onGet : -> 
          if @model.get('comment_count') == 1 then "1 comment" else "#{@model.get('comment_count')} comments"


    makeEditable : ->
      $editable = @$el.find('.point-nutshell')
      $editable.editable
        resource: 'point'
        pk: @model.id
        url: Routes.proposal_point_path @model.get('long_id'), @model.id
        type: 'textarea'
        name: 'nutshell'
        success : (response, new_value) => @model.set('nutshell', new_value)

      # $editable.addClass 'icon-pencil icon-large'

      $editable.prepend '<i class="editable-pencil icon-pencil icon-large">'

      $details_editable = @$el.find('.point-details-description')
      $details_editable.editable
        resource: 'point'
        pk: @model.id
        url: Routes.proposal_point_path @model.get('long_id'), @model.id
        type: 'textarea'
        name: 'text'
        success : (response, new_value) => @model.set('text', new_value)

      # $details_editable.addClass 'icon-pencil icon-large'
      $details_editable.prepend '<i class="editable-pencil icon-pencil icon-large">'

    removeEditable : ->
      $editable = @$el.find('.point-nutshell')
      $details_editable = @$el.find('.point-details-description')

      $editable.editable('destroy')
      $details_editable.editable('destroy')
      # $editable.removeClass 'icon-pencil icon-large'
      # $details_editable.removeClass 'icon-pencil icon-large'

      @$el.find('.editable-pencil').remove()




  class Point.FollowView extends App.Views.ItemView
    template : '#tpl_point_follow'

    serializeData : ->
      current_user = App.request 'user:current'
      params = _.extend {}, @model.attributes,
        already_follows : current_user.isFollowing 'Point', @model.id
        current_user_id : current_user.id
      params

    onShow : ->
      current_user = App.request 'user:current'
      @listenTo current_user, "follow:changed:Point#{@model.id}", ->
        @render()

    events : 
      'click .point-follow' : 'toggleFollow'

    toggleFollow : (ev) ->
      @trigger 'point:follow'

