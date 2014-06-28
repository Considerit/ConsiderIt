@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsController extends App.Controllers.Base
    initialize : (options = {}) ->
      layout = @getLayout @options.collection

      @setupLayout layout

      @layout = layout
      @region.show layout

    setupLayout : (layout) ->
      @listenTo layout, 'show', =>
        @listenTo layout, 'comment:create', (attrs) => @handleCreate attrs
        @listenTo layout, 'childview:give_thanks', (view) =>
          model = view.model
          attrs =
            thankable_type : model.name.charAt(0).toUpperCase() + model.name.slice(1)
            thankable_id : model.id
          thank = App.request 'thanks:create', attrs
          App.execute 'when:fetched', thank, ->
            layout.render()

        @listenTo layout, 'childview:revoke_thanks', (view) =>
          model = view.model
          current_user = App.request 'user:current'
          thank = App.request 'thanks:get:user', view.modelName, model.id, current_user.id
          thank = thank.destroy
            success : (model, response) ->
              layout.render()

        @listenTo App.vent, 'user:signin', =>
          saved_comment_text = @layout.saveCommentText()
          # need to rerender, else the thankable events will be bound twice
          # in future, can probably just rerender the new comments area here
          @layout.close()
          @layout = @getLayout @options.collection
          @setupLayout @layout
          @region.show @layout 
          @layout.restoreCommentText saved_comment_text



    handleCreate : (attrs) ->
      current_user = App.request 'user:current'
      _.extend attrs, 
        user_id : current_user.id
        commentable_type : @options.commentable_type
        commentable_id : @options.commentable_id

      comment = App.request 'comment:create', attrs,
        wait : true
        success : (data) =>
          @options.collection.add comment
          @layout.commentCreated()
          @trigger 'comment:created'
          current_user.setFollowing 
            followable_type : @options.commentable_type
            followable_id : @options.commentable_id
            follow : true
            explicit: false


    getLayout : (collection) ->
      new Comments.CommentsView
        collection : collection
        proposal : @options.proposal