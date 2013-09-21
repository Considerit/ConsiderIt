@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsController extends App.Controllers.Base
    initialize : (options = {}) ->

      layout = @getLayout @options.collection

      @listenTo layout, 'show', =>
        @listenTo layout, 'comment:create', (attrs) => @handleCreate attrs
        @listenTo layout, 'childview:give_thanks', (view) =>
          model = view.model
          attrs =
            thankable_type : model.name.charAt(0).toUpperCase() + model.name.slice(1)
            thankable_id : model.id
          thank = App.request 'thanks:create', attrs
          App.execute 'when:fetched', thank, ->
            console.log 'rendering', thank

            layout.render()

        @listenTo layout, 'childview:revoke_thanks', (view) =>
          model = view.model
          current_user = App.request 'user:current'
          thank = App.request 'thanks:get:user', model.name.charAt(0).toUpperCase() + model.name.slice(1), model.id, current_user.id
          thank = thank.destroy
            success : (model, response) ->
              layout.render()



      @layout = layout
      @region.show layout

    handleCreate : (attrs) ->
      current_user = App.request 'user:current'
      _.extend attrs, 
        user_id : current_user.id
        commentable_type : @options.commentable_type
        commentable_id : @options.commentable_id

      comment = App.request 'comment:create', attrs,
        wait : true
        success : (data) =>
          @layout.commentCreated()
          @trigger 'comment:created'
          @options.collection.add comment
      

    getLayout : (collection) ->
      new Comments.CommentsView
        collection : collection