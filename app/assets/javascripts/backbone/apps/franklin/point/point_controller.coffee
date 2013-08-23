@ConsiderIt.module "Franklin.Point", (Point, App, Backbone, Marionette, $, _) ->
  class Point.ExpandedPointController extends App.Controllers.Base
    initialize : (options = {}) ->
      layout = @getLayout @options.model

      @listenTo layout, 'show', =>
        pointview = @getPointView @options.model
        layout.pointHeaderRegion.show pointview

        comments = new App.Franklin.Comments.CommentsController
          commentable_type : 'Point'
          commentable_id : @options.model.id
          region: layout.discussionRegion
          collection : @options.model.getComments()

        @listenTo comments, 'comment:created', =>
          @options.model.set('comment_count', @options.model.getComments().length)

        @listenTo layout, 'close', =>
          (document).off '.m-point-details'


      @region.show layout

    getLayout : (model) ->
      new Point.ExpandedPointView
        model : model

    getPointView : (model) ->
      new Point.PointView
        model : model
