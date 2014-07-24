@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.DiscussionEntry extends App.Views.ItemView
    events : 
      'click [action=thank-commenter]' : 'giveThanks'
      'click [action=unthank-commenter]' : 'revokeThanks'

    giveThanks : (ev) ->
      @trigger 'give_thanks'

    revokeThanks : (ev) ->
      @trigger 'revoke_thanks'

  class Comments.CommentView extends Comments.DiscussionEntry
    template : '#tpl_comment_view'
    className : 'plain_comment comment'
    modelName : 'Comment'

    serializeData : ->
      current_user = App.request 'user:current'

      _.extend {}, @model.attributes,
        user : @model.getUser().attributes
        thanks : @model.getThanks()
        user_thanked : App.request 'thanks:exists_for_user', 'Comment', @model.id, current_user.id
        can_thank : current_user.isLoggedIn() && current_user.id != @model.get('user_id')

    onShow : ->
      current_user = App.request 'user:current'
      if current_user.id == @model.get('user_id') #|| ConsiderIt.request('user:current').isAdmin()
        $editable = @$el.find('.comment_body')
        $editable.editable 
          resource: 'comment'
          pk: @model.id
          url: Routes.commentable_path @model.id
          type: 'textarea'
          name: 'body'
          success : (response, new_value) => @model.set('body', new_value)
        #$editable.addClass 'icon-pencil icon-large'
        $editable.prepend '<i class="editable-pencil icon-pencil icon-large">'



  class Comments.ClaimView extends Comments.DiscussionEntry
    template : '#tpl_claim_comment_view' 
    className : 'claim_comment comment'
    modelName : 'Assessable::Claim'

    serializeData : ->
      current_user = App.request 'user:current'
      
      params = 
        claim : @model
        assessment : @model.getAssessment()
        verdict : @model.getVerdict()
        thanks : @model.getThanks()
        user_thanked : App.request 'thanks:exists_for_user', 'Assessable::Claim', @model.id, current_user.id
        can_thank : current_user.isLoggedIn()

      params
