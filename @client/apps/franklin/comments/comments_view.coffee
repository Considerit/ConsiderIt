@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsView extends App.Views.CompositeView
    template: '#tpl_comments_view'
    itemView : Comments.CommentView
    itemViewContainer : 'ul.m-point-comments'

    buildItemView : (item) ->
      if item instanceof App.Entities.Comment 
        view = new Comments.CommentView
          model : item
      else if item instanceof App.Entities.Claim
        view = new Comments.ClaimView
          model : item
          attributes : 
            id : "claim-comment-#{item.id}"

      view

    events : 
      'click .m-new-comment-submit' : 'createNew'

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        is_logged_in : ConsiderIt.request 'user:current:logged_in?'
        user : current_user
        comments_open : @options.proposal.isActive()

    onShow : ->
      for el in @$el.find('.is_counted')
        $(el).NobleCount $(el).siblings('.count'), 
          block_negative: true,
          max_chars : parseInt $(el).siblings('.count').text()

      @$el.find('.m-new-comment-body-field').autosize()


    createNew : (ev) ->
      attrs = {
        body : @$el.find('.m-new-comment-body-field').val()
      }
      @trigger 'comment:create', attrs

    commentCreated : ->
      @$el.find('.m-new-comment-body-field').val('')
      toastr.success 'Comment added'

    restoreCommentText : ->
      @$el.find('.m-new-comment-body-field').val @saved_comment_text

    saveCommentText : ->
      @saved_comment_text = @$el.find('.m-new-comment-body-field').val()
