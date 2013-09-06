@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsView extends App.Views.CompositeView
    template: '#tpl_comments_view'
    itemView : Comments.CommentView
    itemViewContainer : 'ul.m-point-comments'


    events : 
      'click .m-new-comment-submit' : 'createNew'

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        is_logged_in : ConsiderIt.request 'user:current:logged_in?'
        user : current_user

    onShow : ->
      for el in @$el.find('.is_counted')
        $(el).NobleCount $(el).siblings('.count'), 
          block_negative: true,
          max_chars : parseInt $(el).siblings('.count').text()       


    createNew : (ev) ->
      attrs = {
        body : @$el.find('.m-new-comment-body-field').val()
      }
      @trigger 'comment:create', attrs

    commentCreated : ->
      @$el.find('.m-new-comment-body-field').val('')
      toastr.success 'Comment added'
