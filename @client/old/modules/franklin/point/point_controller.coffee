@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->

  class Point.PointController extends App.Controllers.Base
    initialize : (options = {}) ->
      point = @options.model
      @layout = @getLayout point

      @setupLayout @layout

    setupLayout : (layout) ->
      point = @options.model

      @listenTo layout, 'render', => 
        header_view = @getHeaderView point
        layout.headerRegion.show header_view

        @body_view = @getBodyView point, layout.actions
        layout.bodyRegion.show @body_view

      @listenTo layout, 'show', =>
        @listenTo layout, 'point:open', =>
          @openPoint()


    closePoint : (go_back) ->
      $(document).off '.close_point_event'
      @layout.$el
        .addClass('closed_point')
        .removeClass('open_point')

      @stopListening @layout.openPointRegion.currentView
      @stopListening App.vent, 'point:opened'
      @stopListening App.vent, 'points:unexpand'

      @layout.openPointRegion.reset() if @layout.openPointRegion

      if @layout.$el.parents('.points_by_community[data-state="crafting"]').length > 0
        @layout.enableDrag()

      App.request 'nav:back:crumb' if go_back

    openPoint : ->
      open_point_view = @getOpenPointView @options.model, @layout.actions

      @listenTo open_point_view, 'show', =>
        if App.request("user:is_client_logged_in?") && @options.model.get 'published'
          follow_view = @setupFollowView()

          open_point_view.followRegion.show follow_view

        current_tenant = App.request 'tenant'
        if current_tenant.get 'assessment_enabled'
          @setupAssessmentView open_point_view.assessmentRegion

        @setupCommentsView open_point_view.discussionRegion

        @listenTo open_point_view, 'point:close', (go_back) => 
          @layout.$el.removeLightbox()
          @closePoint go_back
          @layout.trigger 'point:closed'

        @listenTo open_point_view, 'make_fields_editable', =>
          @body_view.makeEditable()
          open_point_view.makeEditable()
          @listenToOnce open_point_view, 'point:close', =>
            @body_view.removeEditable()
          
        @listenTo App.vent, 'point:opened', => @closePoint false
        @listenTo App.vent, 'points:unexpand', => 
          @layout.$el.removeLightbox()
          @closePoint true # set to true so that when including open point, the url is updated appropriately on close

        @layout.$el
          .addClass('open_point')
          .removeClass('closed_point')

        @layout.$el.ensureInView {fill_threshold: .5}
        @layout.$el.putBehindLightbox()

        if @layout.$el.parents('.points_by_community[data-state="crafting"]').length > 0
          @layout.disableDrag()

      @layout.openPointRegion.show open_point_view

    setupFollowView : ->
      follow_view = @getFollowView @options.model
      @listenTo follow_view, 'show', =>

        @listenTo follow_view, 'point:follow', =>
          current_user = App.request 'user:current'          
          already_following = current_user.isFollowing 'Point', @options.model.id

          params = 
            follows :
              followable_id : @options.model.id
              followable_type : 'Point'
              user_id : current_user.id

          path = if already_following then Routes.unfollow_path() else Routes.follow_path()

          $.post path, params, (data) => 
            App.execute 'notify:success', 'Subscription successful'
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
      collection = @options.model.getComments()

      # collection will be polymorphic with fact checks mixed in      
      current_tenant = App.request 'tenant'
      if current_tenant.get 'assessment_enabled'
        assessment = @options.model.getAssessment()
        if assessment
          collection = new App.Entities.DiscussionCollection _.compact(_.flatten([assessment.getClaims().models, collection.models]))

      comments = new App.Franklin.Comments.CommentsController
        commentable_type : 'Point'
        commentable_id : @options.model.id
        region: region
        collection : collection
        proposal : @options.model.getProposal()
        parent_controller : @

      @listenTo comments, 'comment:created', =>
        @options.model.set 'comment_count', @options.model.getComments().length


    getLayout : (model) ->
      @options.view

    getHeaderView : (model) ->
      new Point.PointAvatarArea
        model : model

    getBodyView : (model, actions) ->
      new Point.PointSummaryView
        model : model
        actions : actions

    getOpenPointView : (model, actions) ->
      new Point.OpenPointView
        model : model
        actions : actions

    getFollowView : (model) ->
      new Point.FollowPointView
        model : model
