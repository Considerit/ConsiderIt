@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.CommentsView extends App.Views.CompositeView
    template: '#tpl_comments_view'
    itemView : Comments.CommentView
    itemViewContainer : 'ul.point_comments'

    buildItemView : (item) ->
      if item instanceof App.Entities.Comment 
        view = new Comments.CommentView
          model : item
          attributes : 
            id : "comment_#{item.id}"

      else if item instanceof App.Entities.Claim
        view = new Comments.ClaimView
          model : item
          attributes : 
            id : "claim_comment_#{item.id}"

      view

    events : 
      'click [action="submit-comment"]' : 'createNew'

    serializeData : ->
      current_user = App.request 'user:current'
      _.extend {}, 
        is_logged_in : ConsiderIt.request 'user:is_client_logged_in?'
        user : current_user
        comments_open : @options.proposal.isActive()

    onShow : ->
      for el in @$el.find('.is_counted')
        $(el).NobleCount $(el).siblings('.count'), 
          block_negative: true,
          max_chars : parseInt $(el).siblings('.count').text()

      @$el.find('.new_comment_body_field').autosize()


    createNew : (ev) ->
      attrs = {
        body : @$el.find('.new_comment_body_field').val()
      }
      @trigger 'comment:create', attrs

    commentCreated : ->
      @$el.find('.new_comment_body_field').val('')
      toastr.success 'Comment added'

    restoreCommentText : ->
      @$el.find('.new_comment_body_field').val @saved_comment_text

    saveCommentText : ->
      @saved_comment_text = @$el.find('.new_comment_body_field').val()
