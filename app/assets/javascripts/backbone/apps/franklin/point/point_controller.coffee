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

        @listenTo expanded_view, 'details:close', =>
          @unexpand()

        @layout.$el.toggleClass 'm-point-expanded m-point-unexpanded'

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

    setupCommentsView : (region) ->
      comments = new App.Franklin.Comments.CommentsController
        commentable_type : 'Point'
        commentable_id : @options.model.id
        region: region
        collection : @options.model.getComments()

      @listenTo comments, 'comment:created', =>
        @options.model.set 'comment_count', @options.model.getComments().length

    unexpand : ->
      $(document).off '.m-point-details'
      @layout.$el.toggleClass 'm-point-expanded m-point-unexpanded'

      @layout.expansionRegion.reset()
      App.navigate Routes.root_path(), {trigger : true}


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
