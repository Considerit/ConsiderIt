@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentView extends App.Views.ItemView
    template : '#tpl_comment_view'
    className : 'm-comment'

    serializeData : ->
      _.extend {}, @model.attributes,
        user : @model.getUser().attributes

    onShow : ->
      current_user = App.request 'user:current'
      if current_user.id == @model.get('user_id') #|| ConsiderIt.request('user:current').isAdmin()
        @$el.find('.m-comment-body').editable {
            resource: 'comment'
            pk: @model.id
            url: Routes.update_comment_path @model.id
            type: 'textarea'
            name: 'body'
            success : (response, new_value) => @model.set('body', new_value)
          }