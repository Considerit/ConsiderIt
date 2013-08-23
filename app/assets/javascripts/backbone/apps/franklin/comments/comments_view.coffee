@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsView extends App.Views.CompositeView
    template: '#tpl_comments_view'
    itemView : Comments.CommentView
    itemViewContainer : 'ul.m-point-comments'


    events : 
      'click .m-new-comment-submit' : 'createNew'

    serializeData : ->
      is_logged_in : ConsiderIt.request('user:current:logged_in?')
      user : App.request 'user:current'

    createNew : (ev) ->
      attrs = {
        body : @$el.find('.m-new-comment-body-field').val()
      }
      @trigger 'comment:create', attrs

    commentCreated : ->
      @$el.find('.m-new-comment-body-field').val('')
      toastr.success 'Comment added'
