@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsController extends App.Controllers.Base
    initialize : (options = {}) ->

      layout = @getLayout @options.collection

      @listenTo layout, 'show', =>
        @listenTo layout, 'comment:create', (attrs) => @handleCreate attrs

      @layout = layout
      @region.show layout

    handleCreate : (attrs) ->
      current_user = App.request 'user:current'
      _.extend attrs, 
        user_id : current_user.id
        commentable_type : @options.commentable_type
        commentable_id : @options.commentable_id

      comment = App.request 'comment:create', attrs, {
        wait : true
        success : (data) =>
          @layout.commentCreated()
          @trigger 'comment:created'
          @options.collection.add comment
      }

    getLayout : (collection) ->
      new Comments.CommentsView
        collection : collection