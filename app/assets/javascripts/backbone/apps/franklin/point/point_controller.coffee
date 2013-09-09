@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->

  class Point.PointController extends App.Controllers.Base
    initialize : (options = {}) ->
      point = @options.model
      layout = @getLayout point

      @listenTo layout, 'show', => 
        header_view = @getHeaderView point
        layout.headerRegion.show header_view

        body_view = @getBodyView point
        layout.bodyRegion.show body_view

      @listenTo layout, 'point:show_details', =>
        @expand()

      @layout = layout

    expand : ->
      expanded_view = @getExpandedView @options.model

      @listenTo expanded_view, 'show', =>

        if App.request("user:current:logged_in?") && @options.model.get 'published'
          follow_view = @setupFollowView()
          expanded_view.followRegion.show follow_view

        current_tenant = App.request 'tenant:get'
        if current_tenant.get('assessment_enabled')
          @setupAssessmentView expanded_view.assessmentRegion

        @setupCommentsView expanded_view.discussionRegion

        @listenTo expanded_view, 'details:close', (go_back) => @unexpand go_back
        @listenTo App.vent, 'point:expanded', => @unexpand false
        @listenTo App.vent, 'navigated_to_base', => @unexpand false

        @layout.$el
          .addClass('m-point-expanded')
          .removeClass('m-point-unexpanded')

        window.ensure_el_in_view @layout.$el, .5


      @layout.expansionRegion.show expanded_view

    setupFollowView : ->
      follow_view = @getFollowView @options.model
      @listenTo follow_view, 'show', =>
        @listenTo follow_view, 'point:follow', (data) =>
          current_user = App.request 'user:current'
          current_user.setFollowing data.follow.follow
      follow_view

    setupAssessmentView : (region) ->
      assessment = @options.model.getAssessment()
      assessment_controller = new App.Franklin.Assessment.AssessmentController
        region : region
        model : assessment
        assessable_type : 'Point'
        assessable : @options.model
        parent_controller : @


    setupCommentsView : (region) ->
      comments = new App.Franklin.Comments.CommentsController
        commentable_type : 'Point'
        commentable_id : @options.model.id
        region: region
        collection : @options.model.getComments()
        parent_controller : @

      @listenTo comments, 'comment:created', =>
        @options.model.set 'comment_count', @options.model.getComments().length

    unexpand : (go_back) ->
      $(document).off '.m-point-details'
      @layout.$el
        .addClass('m-point-unexpanded')
        .removeClass('m-point-expanded')

      @stopListening @layout.expansionRegion.currentView
      @stopListening App.vent, 'point:expanded'
      @stopListening App.vent, 'navigated_to_base'

      @layout.expansionRegion.reset() if @layout.expansionRegion

      window.ensure_el_in_view @layout.$el, .5

      App.request 'nav:back:crumb' if go_back
      # App.navigate Routes.root_path(), {trigger : true}
      # go_back ?= true
      # @$el.find('.m-point-wrap > *').css 'visibility', 'hidden'

      # @commentsview.clear()
      # @commentsview.remove()
      # @assessmentview.remove() if @assessmentview?


      # @$el.removeClass('m-point-expanded')
      # @$el.addClass('m-point-unexpanded')

      # @undelegateEvents()
      # @stopListening()
      
      # @model.trigger 'change' #trigger a render event
      # ConsiderIt.app.go_back_crumb() if go_back


    getLayout : (model) ->
      @options.view

    getHeaderView : (model) ->
      new Point.PointHeaderView
        model : model

    getBodyView : (model) ->
      new Point.PointBodyView
        model : model

    getExpandedView : (model) ->
      new Point.ExpandedView
        model : model

    getFollowView : (model) ->
      new Point.FollowView
        model : model
